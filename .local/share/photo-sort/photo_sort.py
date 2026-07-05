#!/usr/bin/env python3
"""
photo-sort — local CLIP zero-shot photo sorter (like ai-photo-sorter.vercel.app).

Give it a folder and a list of categories; it classifies each image with CLIP
and moves (or copies) it into a subfolder per category. Runs on GPU if available.

Examples:
    photo-sort ~/Pictures/messy --into "people, screenshots, memes, documents, nature"
    photo-sort ~/Downloads --into "receipts, anime, photos" --copy --threshold 0.18
"""
import argparse
import shutil
import sys
from pathlib import Path

IMG_EXT = {".jpg", ".jpeg", ".png", ".webp", ".bmp", ".gif", ".tiff", ".heic", ".heif"}

# Prompt templates improve zero-shot accuracy (CLIP was trained on captions).
TEMPLATES = [
    "a photo of {}.",
    "a picture of {}.",
    "an image of {}.",
    "{}.",
]


def parse_args():
    p = argparse.ArgumentParser(description="Local CLIP photo sorter.")
    p.add_argument("source", type=Path, help="Folder of images to sort.")
    p.add_argument("--into", required=True,
                   help="Comma-separated categories, e.g. \"cats, screenshots, receipts\".")
    p.add_argument("--copy", action="store_true",
                   help="Copy instead of move (default: move).")
    p.add_argument("--recursive", action="store_true",
                   help="Recurse into subfolders.")
    p.add_argument("--threshold", type=float, default=0.0,
                   help="Min confidence (0-1) to file an image; below is treated as unsure. Default 0 = always pick best.")
    p.add_argument("--leave-unsure", action="store_true",
                   help="Leave below-threshold images untouched in place (instead of moving them to 'unsorted/').")
    p.add_argument("--only", default="",
                   help="Comma-separated folder names that are allowed to be moved; images whose best match is any other category are left in place. Use to extract just one/few categories.")
    p.add_argument("--model", default="ViT-L-14",
                   help="open_clip model (default ViT-L-14, good accuracy/speed).")
    p.add_argument("--pretrained", default="laion2b_s32b_b82k",
                   help="Pretrained weights tag for the model.")
    p.add_argument("--dry-run", action="store_true",
                   help="Show what would happen, move nothing.")
    p.add_argument("--batch", type=int, default=16, help="Image batch size.")
    return p.parse_args()


def gather_images(root: Path, recursive: bool):
    it = root.rglob("*") if recursive else root.iterdir()
    return sorted(p for p in it if p.is_file() and p.suffix.lower() in IMG_EXT)


def main():
    args = parse_args()
    if not args.source.is_dir():
        sys.exit(f"error: {args.source} is not a directory")

    # Each category can be "Folder Name=rich description for CLIP".
    # The folder is named by the left side; CLIP matches against the right side.
    # Categories are separated by ';' if any are present (so descriptions may
    # contain commas), otherwise by ','.
    sep = ";" if ";" in args.into else ","
    labels, descs = [], []
    for raw in args.into.split(sep):
        raw = raw.strip()
        if not raw:
            continue
        if "=" in raw:
            name, desc = raw.split("=", 1)
            labels.append(name.strip())
            descs.append(desc.strip())
        else:
            labels.append(raw)
            descs.append(raw)
    if not labels:
        sys.exit("error: no categories given to --into")

    import torch
    import open_clip
    from PIL import Image

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"[photo-sort] device: {device} | model: {args.model}/{args.pretrained}")
    print(f"[photo-sort] categories: {', '.join(labels)}")

    model, _, preprocess = open_clip.create_model_and_transforms(
        args.model, pretrained=args.pretrained, device=device)
    model.eval()
    tokenizer = open_clip.get_tokenizer(args.model)

    # Build averaged text embeddings per label across templates.
    with torch.no_grad():
        label_embs = []
        for desc in descs:
            prompts = [t.format(desc) for t in TEMPLATES]
            toks = tokenizer(prompts).to(device)
            te = model.encode_text(toks)
            te = te / te.norm(dim=-1, keepdim=True)
            label_embs.append(te.mean(dim=0))
        text_features = torch.stack(label_embs)
        text_features = text_features / text_features.norm(dim=-1, keepdim=True)

    images = gather_images(args.source, args.recursive)
    if not images:
        sys.exit(f"error: no images found in {args.source}")
    print(f"[photo-sort] found {len(images)} images")

    moved = {l: 0 for l in labels}
    moved["unsorted"] = 0
    moved["(left in place)"] = 0

    def commit(src: Path, label: str):
        dest_dir = args.source / label
        dest_dir.mkdir(exist_ok=True)
        dest = dest_dir / src.name
        n = 1
        while dest.exists():
            dest = dest_dir / f"{src.stem}_{n}{src.suffix}"
            n += 1
        if args.dry_run:
            return
        (shutil.copy2 if args.copy else shutil.move)(str(src), str(dest))

    batch, paths = [], []

    def flush():
        if not batch:
            return
        with torch.no_grad():
            x = torch.stack(batch).to(device)
            feats = model.encode_image(x)
            feats = feats / feats.norm(dim=-1, keepdim=True)
            sims = (feats @ text_features.T).softmax(dim=-1)  # (N, num_labels)
            conf, idx = sims.max(dim=-1)
        only = {s.strip() for s in args.only.split(",") if s.strip()}
        for pth, c, i in zip(paths, conf.tolist(), idx.tolist()):
            win = labels[i]
            # If --only is set, ignore images that match a non-target category.
            if only and win not in only:
                moved["(left in place)"] += 1
                print(f"  ·   {pth.name:<40} left in place (not target)  ({c:.2f})")
                continue
            unsure = c < args.threshold
            if unsure and args.leave_unsure:
                moved["(left in place)"] += 1
                print(f"  ·   {pth.name:<40} left in place  ({c:.2f})")
                continue
            label = win if not unsure else "unsorted"
            moved[label] += 1
            tag = "DRY" if args.dry_run else "→"
            print(f"  {tag} {pth.name:<40} {label}  ({c:.2f})")
            commit(pth, label)
        batch.clear()
        paths.clear()

    for pth in images:
        try:
            img = Image.open(pth).convert("RGB")
        except Exception as e:
            print(f"  ! skip {pth.name}: {e}")
            continue
        batch.append(preprocess(img))
        paths.append(pth)
        if len(batch) >= args.batch:
            flush()
    flush()

    print("\n[photo-sort] summary:")
    for label, n in moved.items():
        if n:
            print(f"  {label:<20} {n}")
    if args.dry_run:
        print("(dry run — nothing was moved)")


if __name__ == "__main__":
    main()
