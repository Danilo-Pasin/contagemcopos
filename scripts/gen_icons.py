#!/usr/bin/env python3
"""Gera ícones PWA do app Contagem com gradiente roxo/magenta."""
from PIL import Image, ImageDraw, ImageFont
import os, math

def gradient(size, c1, c2, vertical=False):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            if vertical:
                t = y / max(size - 1, 1)
            else:
                t = (x + y) / max(2 * (size - 1), 1)
            r = int(c1[0] + (c2[0] - c1[0]) * t)
            g = int(c1[1] + (c2[1] - c1[1]) * t)
            b = int(c1[2] + (c2[2] - c1[2]) * t)
            px[x, y] = (r, g, b)
    return img

def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask

def draw_beer(d, cx, cy, scale, color):
    # corpo do copo (cilindro)
    w = int(110 * scale)
    h = int(130 * scale)
    x0 = cx - w // 2
    y0 = cy - h // 2
    x1 = cx + w // 2
    y1 = cy + h // 2
    d.rounded_rectangle([x0, y0, x1, y1], radius=int(14 * scale), outline=color, width=int(8 * scale))
    # alça
    d.arc([x1 - int(6*scale), y0 + int(20*scale), x1 + int(46*scale), y0 + int(95*scale)],
          start=-90, end=90, fill=color, width=int(8 * scale))
    # espuma
    d.ellipse([x0 + int(8*scale), y0 - int(18*scale), x0 + int(48*scale), y0 + int(10*scale)], fill=color)
    d.ellipse([x0 + int(40*scale), y0 - int(26*scale), x0 + int(80*scale), y0 - int(2*scale)], fill=color)

def make_icon(size, maskable=False):
    bg = gradient(size, (124, 77, 255), (224, 64, 251))
    radius = int(size * 0.22) if not maskable else int(size * 0.5)
    mask = rounded_mask(size, radius)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(bg, (0, 0), mask)
    d = ImageDraw.Draw(canvas)
    offset = int(size * 0.12) if maskable else 0
    draw_beer(d, size // 2, size // 2 + offset, scale=size / 512, color=(255, 255, 255, 255))
    return canvas

out = "web/icons"
os.makedirs(out, exist_ok=True)
for size in (192, 512):
    make_icon(size).save(f"{out}/Icon-{size}.png")
    make_icon(size, maskable=True).save(f"{out}/Icon-maskable-{size}.png")

# favicon
make_icon(64).save("web/favicon.png")
print("icons generated")
