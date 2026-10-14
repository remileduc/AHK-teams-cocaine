#!/usr/bin/env python3
"""Writes a grayscale copy of a .ico file: python make-gray-icon.py coffee.ico coffee-gray.ico

Every image in the icon is converted (PNG-compressed or plain 32-bit BMP entries) and
transparency is kept. Standard library only.
"""
import struct
import sys
import zlib

PNG_SIG = b"\x89PNG\r\n\x1a\n"


def luma(r, g, b):
    return (r * 299 + g * 587 + b * 114 + 500) // 1000


def predictor(ft, a, b, c):
    """PNG filter predictor: a = left, b = above, c = above-left."""
    if ft == 0:
        return 0
    if ft == 1:
        return a
    if ft == 2:
        return b
    if ft == 3:
        return (a + b) // 2
    if ft == 4:
        p = a + b - c
        pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
        if pa <= pb and pa <= pc:
            return a
        return b if pb <= pc else c
    raise ValueError(f"bad PNG filter type {ft}")


def chunk(ctype, data):
    return struct.pack(">I", len(data)) + ctype + data + struct.pack(">I", zlib.crc32(ctype + data))


def gray_png(png):
    chunks, idat, hdr = [], b"", None
    pos = 8
    while pos < len(png):
        length, ctype = struct.unpack(">I4s", png[pos:pos + 8])
        data = png[pos + 8:pos + 8 + length]
        pos += 12 + length
        if ctype == b"IDAT":
            idat += data
            continue
        if ctype == b"IHDR":
            hdr = struct.unpack(">IIBBBBB", data)
        chunks.append((ctype, data))
    w, h, depth, color, _, _, interlace = hdr
    if depth != 8 or color not in (2, 6) or interlace:
        raise ValueError("unsupported PNG: need 8-bit RGB/RGBA, non-interlaced")
    bpp = 4 if color == 6 else 3  # bytes per pixel
    stride = w * bpp

    # Undo the per-row filters, gray each pixel, then re-apply the same filters.
    raw = zlib.decompress(idat)
    prev_orig = prev_gray = bytes(stride)  # previous row before and after graying
    out = bytearray()
    for y in range(h):
        row = raw[y * (stride + 1):(y + 1) * (stride + 1)]
        ft, r = row[0], bytearray(row[1:])
        p = prev_orig
        for i in range(stride):
            a = r[i - bpp] if i >= bpp else 0
            c = p[i - bpp] if i >= bpp else 0
            r[i] = (r[i] + predictor(ft, a, p[i], c)) & 0xFF
        prev_orig = bytes(r)
        for i in range(0, stride, bpp):
            r[i] = r[i + 1] = r[i + 2] = luma(r[i], r[i + 1], r[i + 2])
        p = prev_gray
        f = bytearray(stride)
        for i in range(stride):
            a = r[i - bpp] if i >= bpp else 0
            c = p[i - bpp] if i >= bpp else 0
            f[i] = (r[i] - predictor(ft, a, p[i], c)) & 0xFF
        out.append(ft)
        out += f
        prev_gray = bytes(r)

    png_out = PNG_SIG
    for ctype, data in chunks:
        if ctype == b"IEND":
            png_out += chunk(b"IDAT", zlib.compress(bytes(out), 9))
        png_out += chunk(ctype, data)
    return png_out


def gray_bmp(bmp):
    """Plain entry: BITMAPINFOHEADER, 32-bit BGRA pixels (height counts XOR + AND masks), AND mask."""
    hsize, w, h2, _, bits = struct.unpack("<IIIHH", bmp[:16])
    if hsize != 40 or bits != 32:
        raise ValueError("unsupported BMP icon entry: need 32 bpp")
    npix = w * (h2 // 2)
    px = bytearray(bmp[hsize:hsize + npix * 4])
    for i in range(0, len(px), 4):
        px[i] = px[i + 1] = px[i + 2] = luma(px[i + 2], px[i + 1], px[i])
    return bmp[:hsize] + bytes(px) + bmp[hsize + npix * 4:]


def main():
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} input.ico output.ico")
    src, dst = sys.argv[1:]
    with open(src, "rb") as fh:
        ico = fh.read()
    reserved, itype, count = struct.unpack("<HHH", ico[:6])
    if reserved != 0 or itype != 1 or count == 0:
        sys.exit(f"{src} is not an icon file")

    entries = [struct.unpack("<BBBBHHII", ico[6 + 16 * i:22 + 16 * i]) for i in range(count)]
    images = []
    for *_, size, offset in entries:
        img = ico[offset:offset + size]
        images.append(gray_png(img) if img.startswith(PNG_SIG) else gray_bmp(img))

    directory = struct.pack("<HHH", 0, 1, count)
    offset = 6 + 16 * count
    for entry, img in zip(entries, images):
        directory += struct.pack("<BBBBHHII", *entry[:6], len(img), offset)
        offset += len(img)
    with open(dst, "wb") as fh:
        fh.write(directory + b"".join(images))
    print(f"{dst}: {count} images written")


if __name__ == "__main__":
    main()
