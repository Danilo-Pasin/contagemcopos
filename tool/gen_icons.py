#!/usr/bin/env python3
"""Gera os ícones do OGS a partir de docs/logo.png.

O logo-fonte tem fundo preto opaco nos cantos e um centro verde. Aqui o fundo
escuro e' removido via sinal de dominância do verde (G - max(R,B)), o que
preserva o logo e as bordas anti-aliasadas como opacidade parcial.
"""
from PIL import Image

SRC = 'docs/logo.png'
OUT_DIR = 'web/icons/'

GRADIENT_POWER = 2.0  # menor = borda mais suave; maior = corte mais duro


def remove_bg(img: Image.Image) -> Image.Image:
    img = img.convert('RGBA')
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            # Dominância do verde: quanto mais verde e' o pixel, mais opaco.
            score = g - max(r, b)
            alpha = max(0.0, min(1.0, score / 60.0))
            alpha = alpha ** GRADIENT_POWER
            px[x, y] = (r, g, b, int(255 * alpha * (a / 255)))
    return img


def fit(img: Image.Image, size: int, fill: float) -> Image.Image:
    """Escala o logo mantendo aspecto, centralizado a `fill`% do canvas."""
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    target = int(size * fill)
    ratio = min(target / img.width, target / img.height)
    resized = img.resize(
        (max(1, int(img.width * ratio)), max(1, int(img.height * ratio))),
        Image.LANCZOS,
    )
    x = (size - resized.width) // 2
    y = (size - resized.height) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main() -> None:
    trimmed = remove_bg(Image.open(SRC))

    assets_logo = trimmed.convert('RGBA')
    assets_logo.save('assets/logo.png')

    # Safe zone maskable: conteudo central em ~60% do canvas (20% de folga).
    maskable_192 = fit(trimmed, 192, 0.60)
    maskable_512 = fit(trimmed, 512, 0.60)
    # Ícones regulares: preenchem mais (sem necessidade de safe zone).
    icon_192 = fit(trimmed, 192, 0.82)
    icon_512 = fit(trimmed, 512, 0.82)

    maskable_192.save(f'{OUT_DIR}Icon-maskable-192.png')
    maskable_512.save(f'{OUT_DIR}Icon-maskable-512.png')
    icon_192.save(f'{OUT_DIR}Icon-192.png')
    icon_512.save(f'{OUT_DIR}Icon-512.png')

    # Favicon: composita o logo sem fundo sobre o fundo do app (nao preto).
    fav = Image.new('RGBA', trimmed.size, (11, 14, 20, 255))
    fav.paste(trimmed, (0, 0), trimmed)
    fav.convert('RGB').save('web/favicon.png')

    # Preview para o usuário validar a remoção do fundo sobre fundo escuro/claro.
    preview = Image.new('RGBA', (1288, 634), (11, 14, 20, 255))
    preview.paste(trimmed, (0, 0), trimmed)
    bright = Image.new('RGBA', (644, 634), (240, 240, 240, 255))
    bright.paste(trimmed, (0, 0), trimmed)
    preview.paste(bright, (644, 0))
    preview.convert('RGB').save('docs/logo-preview.png')

    total = trimmed.width * trimmed.height
    opaque = sum(1 for p in trimmed.getdata() if p[3] > 0)
    print(f'assets/logo.png {trimmed.size} {trimmed.mode}')
    print(f'% opaco apos remocao: {100*opaque/total:.1f}%')
    print('icons e favicon gerados; preview em docs/logo-preview.png')


if __name__ == '__main__':
    main()
