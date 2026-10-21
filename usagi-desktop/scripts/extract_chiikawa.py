"""Extract Chiikawa from the two user-selected 1080p clips.

python extract_chiikawa.py cry|snack|clover /path/to/video.mp4
Requires numpy, opencv-python-headless and pillow.
"""
from pathlib import Path
import sys
import cv2
import numpy as np
from PIL import Image, ImageDraw

kind, source = sys.argv[1:3]
if kind not in ("cry", "snack", "clover"):
    raise SystemExit("Choose cry, snack or clover")
root = Path(__file__).resolve().parents[1]
directory, start, count = ("ChiikawaCryFrames", 45.6, 102) if kind == "cry" else ("ChiikawaSnackFrames", 55.0, 60)
if kind == "clover":
    directory, start, count = "ChiikawaCloverFrames", 6.6, 72
canvas = 640 if kind == "clover" else 512
out = root / "Assets" / directory
out.mkdir(parents=True, exist_ok=True)
cap = cv2.VideoCapture(source)
cap.set(cv2.CAP_PROP_POS_MSEC, start * 1000)
frames = []
previous = np.array([615, 230] if kind == "cry" else ([490, 240] if kind == "clover" else [340, 305]))
for index in range(count):
    ok, full = cap.read()
    if not ok:
        raise SystemExit(f"Missing frame {index}")
    if full.shape[:2] != (1080, 1920):
        raise SystemExit("Expected 1920×1080 source")
    small = cv2.resize(full, (960, 540), interpolation=cv2.INTER_AREA)
    hsv = cv2.cvtColor(small, cv2.COLOR_BGR2HSV)
    white = cv2.inRange(hsv, (0, 0, 218), (179, 40, 255))
    n, labels, stats, centers = cv2.connectedComponentsWithStats(white)
    candidates = [i for i in range(1, n) if stats[i, 4] > 4000
                  and np.linalg.norm(centers[i] - previous) < 100]
    if not candidates:
        raise SystemExit(f"Character not found: {index}")
    selected = min(candidates, key=lambda i: np.linalg.norm(centers[i] - previous))
    previous = centers[selected]
    body = np.uint8(labels == selected) * 255
    body = cv2.morphologyEx(body, cv2.MORPH_CLOSE, np.ones((3, 3), np.uint8))
    contours, _ = cv2.findContours(body, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    body[:] = 0
    cv2.drawContours(body, contours, -1, 255, cv2.FILLED)
    # Fixed camera for crying; track camera motion in the snack scene.
    if kind == "cry":
        cx, cy = 1230, 455
    elif kind == "clover":
        cx, cy = 960, 460
    else:
        x, y, w, h, _ = stats[selected]
        cx, cy = int((x + w / 2) * 2), int((y + h / 2) * 2)
    left, top = cx - canvas // 2, cy - canvas // 2
    crop = full[top:top+canvas, left:left+canvas].copy()
    body = cv2.resize(body, (1920, 1080), interpolation=cv2.INTER_NEAREST)[top:top+canvas, left:left+canvas]
    mask = np.zeros((canvas, canvas), np.uint8)
    outer = cv2.dilate(body, np.ones((27, 27), np.uint8))
    probable = cv2.dilate(body, np.ones((15, 15), np.uint8))
    mask[outer > 0] = cv2.GC_PR_BGD
    mask[probable > 0] = cv2.GC_PR_FGD
    mask[body > 0] = cv2.GC_FGD
    # Retain the brown ink outline, which otherwise resembles dark scenery.
    crop_hsv = cv2.cvtColor(crop, cv2.COLOR_BGR2HSV)
    ink = (crop_hsv[:, :, 1] > 75) & (crop_hsv[:, :, 2] < 160)
    mask[(probable > 0) & ink] = cv2.GC_FGD
    cv2.grabCut(crop, mask, None, np.zeros((1, 65)), np.zeros((1, 65)), 3, cv2.GC_INIT_WITH_MASK)
    alpha = np.uint8((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)) * 255
    contours, _ = cv2.findContours(alpha, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    alpha[:] = 0
    cv2.drawContours(alpha, [max(contours, key=cv2.contourArea)], -1, 255, cv2.FILLED)
    rgba = cv2.cvtColor(crop, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = alpha
    rgba[alpha == 0, :3] = 0
    frames.append(Image.fromarray(rgba))
    if index % 20 == 0:
        print(f"{kind}: {index+1}/{count}", flush=True)
cap.release()
for old in out.glob("frame-*.png"):
    old.unlink()
for i, frame in enumerate(frames):
    frame.save(out / f"frame-{i:03}.png")
sheet = Image.new("RGB", (240 * 4, 260 * 3), "#dfe5ec")
draw = ImageDraw.Draw(sheet)
for cell, i in enumerate(np.linspace(0, count-1, 12, dtype=int)):
    x, y = cell % 4 * 240, cell // 4 * 260
    thumb = frames[i].resize((240, 240), Image.Resampling.LANCZOS)
    sheet.paste(thumb, (x, y), thumb)
    draw.text((x+8, y+242), f"{start+i/29.97:.2f}s", fill="#273444")
sheet.save(root / f"chiikawa-{kind}-contact.png")
frames[0].save(root / f"chiikawa-{kind}-preview.gif", save_all=True,
               append_images=frames[1:], duration=33, loop=0, disposal=2)
print(f"Saved {directory}: {count} frames", flush=True)
