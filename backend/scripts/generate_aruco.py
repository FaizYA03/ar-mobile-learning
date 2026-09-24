#!/usr/bin/env python3
"""Generate a real ArUco marker image (PNG) using OpenCV.

Dipanggil dari Laravel (ArMarkerGenerator) — bukan untuk dijalankan manual,
tapi bisa:  python3 generate_aruco.py --dictionary DICT_4X4_50 --id 7 --size 800 --output marker.png

Butuh: pip install opencv-python-headless numpy
Keluar: file PNG + baris "OK <path>" di stdout. Error -> stderr + exit != 0.
"""

import argparse
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dictionary", required=True)
    parser.add_argument("--id", required=True, type=int)
    parser.add_argument("--size", type=int, default=800)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    try:
        import cv2
    except ImportError:
        print("ERROR: opencv-python-headless belum terinstal (pip install opencv-python-headless numpy)", file=sys.stderr)
        return 2

    get_dict = getattr(cv2.aruco, "getPredefinedDictionary", None)
    if get_dict is None:
        print("ERROR: cv2.aruco tidak tersedia di versi OpenCV ini", file=sys.stderr)
        return 2

    try:
        dictionary = get_dict(getattr(cv2.aruco, args.dictionary))
    except AttributeError:
        print(f"ERROR: dictionary {args.dictionary} tidak dikenal", file=sys.stderr)
        return 3

    if args.id < 0 or args.id >= dictionary.bytesList.shape[0]:
        print(f"ERROR: id {args.id} di luar rentang dictionary {args.dictionary}", file=sys.stderr)
        return 3

    size = max(200, min(args.size, 2000))
    # generateImageMarker tersedia di opencv-contrib & build modern (4.7+).
    # Fallback ke drawMarker untuk versi lama.
    if hasattr(cv2.aruco, "generateImageMarker"):
        img = cv2.aruco.generateImageMarker(dictionary, args.id, size)
    else:
        import numpy as np
        img = np.zeros((size, size), dtype=np.uint8)
        cv2.aruco.drawMarker(dictionary, args.id, size, img, 1)

    if not cv2.imwrite(args.output, img):
        print(f"ERROR: gagal menulis {args.output}", file=sys.stderr)
        return 4

    print(f"OK {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
