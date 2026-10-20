"""Extract Usagi's unobstructed dance from the supplied video.

Usage: python extract_dance.py /path/to/video.mp4
Requires numpy, opencv-python-headless, pillow.
The color/position mask is specific to S_a8LU5MYVY, around 13 seconds.
"""
from pathlib import Path
import sys
import cv2
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Assets" / "DanceFrames"
OUT.mkdir(parents=True, exist_ok=True)
video = cv2.VideoCapture(sys.argv[1])
if not video.isOpened():
    raise SystemExit("Could not open source video")

frames = []
for index in range(24):
    video.set(cv2.CAP_PROP_POS_MSEC, (13.0 + index / 30) * 1000)
    ok, full = video.read()
    if not ok:
        raise SystemExit(f"Missing source frame {index}")
    # Analyze at the reference resolution, but keep native pixels for output.
    # Scaling the existing 360p frames would not recover image detail.
    sx, sy = full.shape[1] / 514, full.shape[0] / 360
    crop = full[round(90 * sy):round(270 * sy),
                round(185 * sx):round(350 * sx)].copy()
    analysis = cv2.resize(full, (514, 360))[90:270, 185:350]
    hsv = cv2.cvtColor(analysis, cv2.COLOR_BGR2HSV)
    skin = cv2.inRange(hsv, (0, 35, 165), (35, 150, 255))
    count, labels, stats, centers = cv2.connectedComponentsWithStats(skin)
    candidates = [i for i in range(1, count)
                  if stats[i, cv2.CC_STAT_AREA] > 200 and 35 < centers[i, 0] < 125]
    if not candidates:
        raise SystemExit(f"No character in frame {index}")
    selected = [i for i in candidates if stats[i, cv2.CC_STAT_AREA] > 400]
    body = np.uint8(np.isin(labels, selected)) * 255
    body = cv2.morphologyEx(body, cv2.MORPH_CLOSE, np.ones((5, 5), np.uint8))
    # Fill sunglasses, mouth and other enclosed details.
    contours, _ = cv2.findContours(body, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    body[:] = 0
    cv2.drawContours(body, contours, -1, 255, cv2.FILLED)
    body = cv2.resize(body, (crop.shape[1], crop.shape[0]), interpolation=cv2.INTER_NEAREST)
    def kernel(size):
        scaled = max(3, round(size * sy)) | 1
        return np.ones((scaled, scaled), np.uint8)
    inner = body.copy()
    outer = cv2.dilate(body, kernel(9))
    likely = cv2.dilate(body, kernel(5))
    mask = np.zeros(body.shape, np.uint8)
    mask[outer > 0] = cv2.GC_PR_BGD
    mask[likely > 0] = cv2.GC_PR_FGD
    mask[inner > 0] = cv2.GC_FGD
    cv2.grabCut(crop, mask, None, np.zeros((1, 65)), np.zeros((1, 65)),
                5, cv2.GC_INIT_WITH_MASK)
    alpha = np.uint8((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)) * 255
    contours, _ = cv2.findContours(alpha, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    alpha[:] = 0
    cv2.drawContours(alpha, [c for c in contours if cv2.contourArea(c) > 100 * sx * sy],
                     -1, 255, cv2.FILLED)
    # The original dark ink outline sits just outside the cream color mask.
    alpha = cv2.dilate(alpha, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3)))
    rgba = cv2.cvtColor(crop, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = alpha
    image = Image.fromarray(rgba)
    frames.append(image)

video.release()
for old in OUT.glob("frame-*.png"):
    old.unlink()
for index, frame in enumerate(frames):
    frame.save(OUT / f"frame-{index:03}.png")

sheet = Image.new("RGB", (165 * 6, 200 * 4), "#e5e9ee")
draw = ImageDraw.Draw(sheet)
for index, frame in enumerate(frames):
    x, y = (index % 6) * 165, (index // 6) * 200
    thumbnail = frame.resize((165, 180), Image.Resampling.LANCZOS)
    sheet.paste(thumbnail, (x, y), thumbnail)
    draw.text((x + 6, y + 181), f"{13 + index/30:.2f}s", fill="#263342")
sheet.save(ROOT / "dance-contact.png")
frames[0].save(ROOT / "dance-preview.gif", save_all=True, append_images=frames[1:],
               duration=33, loop=0, disposal=2)
print(f"Extracted {len(frames)} frames to {OUT}")
