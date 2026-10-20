"""Video-specific cutout for PN0VmWYBRII, 56.7–58.3 seconds.

Usage: python extract_rakko.py /path/to/video.mp4
Requires numpy, opencv-python-headless, pillow.
"""
from pathlib import Path
import sys
import cv2
import numpy as np
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
out = root / "Assets" / "RakkoFrames"
out.mkdir(parents=True, exist_ok=True)
cap = cv2.VideoCapture(sys.argv[1])
frames = []
polygon = np.array([(215, 0), (380, 0), (425, 50), (450, 100),
                    (460, 190), (430, 242), (406, 250), (433, 310),
                    (393, 359), (298, 359), (256, 293), (254, 242),
                    (185, 242), (178, 143), (183, 65)], np.int32)
for index in range(48):
    cap.set(cv2.CAP_PROP_POS_MSEC, (56.7 + index / 30) * 1000)
    ok, image = cap.read()
    if not ok:
        raise SystemExit(f"Missing frame {index}")
    image = cv2.resize(image, (640, 360))
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    region = np.zeros((360, 640), np.uint8)
    cv2.fillPoly(region, [polygon], 255)
    mask = np.zeros_like(region)
    mask[region > 0] = cv2.GC_PR_FGD
    # Cream fur and white scarf/glass are distinct from the beige scenery.
    cream = cv2.inRange(hsv, (15, 15, 225), (40, 95, 255))
    white = cv2.inRange(hsv, (0, 0, 235), (179, 35, 255))
    seed = cv2.bitwise_and(cream | white, region)
    seed = cv2.erode(seed, np.ones((3, 3), np.uint8))
    mask[seed > 0] = cv2.GC_FGD
    cv2.grabCut(image, mask, None, np.zeros((1, 65)), np.zeros((1, 65)),
                5, cv2.GC_INIT_WITH_MASK)
    alpha = np.uint8((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD)) * 255
    contours, _ = cv2.findContours(alpha, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    alpha[:] = 0
    cv2.drawContours(alpha, [c for c in contours if cv2.contourArea(c) > 350],
                     -1, 255, cv2.FILLED)
    rgba = cv2.cvtColor(image, cv2.COLOR_BGR2RGBA)
    rgba[:, :, 3] = alpha
    # Fixed framing preserves chewing motion without per-frame crop jitter.
    frames.append(Image.fromarray(rgba[0:360, 170:465]))
cap.release()
for old in out.glob("frame-*.png"):
    old.unlink()
for i, frame in enumerate(frames):
    frame.save(out / f"frame-{i:03}.png")
sheet = Image.new("RGB", (295 * 4, 380 * 3), "#dfe5ec")
draw = ImageDraw.Draw(sheet)
for cell, i in enumerate(range(0, 48, 4)):
    x, y = cell % 4 * 295, cell // 4 * 380
    sheet.paste(frames[i], (x, y), frames[i])
    draw.text((x+8, y+362), f"{56.7+i/30:.2f}s", fill="#273444")
sheet.save(root / "rakko-contact.png")
frames[0].save(root / "rakko-preview.gif", save_all=True, append_images=frames[1:],
               duration=33, loop=0, disposal=2)
print(f"Extracted {len(frames)} frames")
