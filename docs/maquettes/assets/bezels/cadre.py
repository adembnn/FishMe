# usage: python3 cadre.py <capture.png> <out.png> [couleur]
import sys
from PIL import Image, ImageDraw
import numpy as np
src, out = sys.argv[1], sys.argv[2]
col = sys.argv[3] if len(sys.argv) > 3 else 'Black'
bez = Image.open(f'/mnt/project-files/maquettes/assets/bezels/iPhone 17 - {col} - Portrait.png').convert('RGBA')
a = np.array(bez)[:, :, 3]
h, w = a.shape
# screen = transparent region connected to the centre
cy, cx = h // 2, w // 2
row = a[cy]; col_ = a[:, cx]
l = cx
while l > 0 and row[l-1] < 10: l -= 1
r = cx
while r < w-1 and row[r+1] < 10: r += 1
t = cy
while t > 0 and col_[t-1] < 10: t -= 1
b = cy
while b < h-1 and col_[b+1] < 10: b += 1
sw = r - l + 1
sh = round(sw * 874 / 402)  # iPhone 17 screen ratio; the island blocks the top scan
t = b - sh + 1
cap = Image.open(src).convert('RGBA').resize((sw, sh), Image.LANCZOS)
# round corners of the capture to the screen radius
mask = Image.new('L', (sw, sh), 0)
ImageDraw.Draw(mask).rounded_rectangle([0, 0, sw-1, sh-1], radius=int(sw*0.135), fill=255)
canvas = Image.new('RGBA', (w, h), (0, 0, 0, 0))
canvas.paste(cap, (l, t), mask)
canvas.alpha_composite(bez)
canvas.save(out)
print(out, (sw, sh), (l, t))
