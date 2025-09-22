"""
vision_utils.py

Safe, standalone vision utilities extracted from external Riko project.
Provides:
- OCRAssetCache (LRU cache for OCR results)
- lazy Tesseract setup (_ensure_pytesseract)
- capture_screen_mss() -> PIL.Image using mss
- encode_image_to_base64()

This file is self-contained and safe to import into your main project. It avoids
any direct calls that control input or start containers. It is intended for
use in dry-run and VM workflows.
"""

from collections import OrderedDict
import threading
import time
import hashlib
import io
from pathlib import Path
from typing import Optional

try:
    from PIL import Image, ImageEnhance
except Exception:
    raise ImportError("Pillow is required: pip install pillow")

try:
    import numpy as np
except Exception:
    raise ImportError("numpy is required: pip install numpy")

try:
    import cv2
except Exception:
    cv2 = None  # Optional

# mss for fast capture
try:
    from mss import mss
except Exception:
    mss = None

# pytesseract is imported lazily to avoid binary dependency issues
pytesseract = None
OCR_AVAILABLE = False


class OCRAssetCache:
    """LRU cache for OCR results to avoid redundant processing of similar images."""

    def __init__(self, max_size: int = 100, similarity_threshold: float = 0.95):
        self.max_size = max_size
        self.similarity_threshold = similarity_threshold
        self.cache = OrderedDict()
        self.lock = threading.Lock()
        self.stats = {"hits": 0, "misses": 0, "total_requests": 0, "cache_size": 0}

    def _generate_image_hash(self, image) -> str:
        try:
            if isinstance(image, np.ndarray):
                if image.ndim == 3:
                    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY) if cv2 is not None else np.mean(image, axis=2).astype(np.uint8)
                else:
                    gray = image
            else:
                # PIL Image
                gray = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2GRAY) if cv2 is not None else np.array(image.convert('L'))

            resized = cv2.resize(gray, (8, 8), interpolation=cv2.INTER_AREA) if cv2 is not None else np.array(Image.fromarray(gray).resize((8, 8))).astype(np.uint8)
            mean = np.mean(resized)
            hash_array = (resized > mean).flatten()
            return ''.join('1' if bit else '0' for bit in hash_array)
        except Exception:
            try:
                image_bytes = np.array(image).tobytes()
                return hashlib.md5(image_bytes).hexdigest()[:16]
            except Exception:
                return hashlib.md5(str(image).encode()).hexdigest()[:16]

    def _calculate_similarity(self, hash1: str, hash2: str) -> float:
        if len(hash1) != len(hash2):
            return 0.0
        distance = sum(c1 != c2 for c1, c2 in zip(hash1, hash2))
        return 1.0 - (distance / len(hash1))

    def get(self, image):
        with self.lock:
            self.stats["total_requests"] += 1
            if not self.cache:
                self.stats["misses"] += 1
                return None
            image_hash = self._generate_image_hash(image)
            if image_hash in self.cache:
                self.stats["hits"] += 1
                cached_result, timestamp = self.cache[image_hash]
                self.cache.move_to_end(image_hash)
                return cached_result
            best_match = None
            best_similarity = 0.0
            for cached_hash, (cached_result, timestamp) in self.cache.items():
                sim = self._calculate_similarity(image_hash, cached_hash)
                if sim >= self.similarity_threshold and sim > best_similarity:
                    best_match = (cached_result, cached_hash)
                    best_similarity = sim
            if best_match is not None:
                self.stats["hits"] += 1
                cached_result, cached_hash = best_match
                self.cache.move_to_end(cached_hash)
                return cached_result
            else:
                self.stats["misses"] += 1
                return None

    def put(self, image, ocr_result: str):
        with self.lock:
            image_hash = self._generate_image_hash(image)
            if image_hash in self.cache:
                del self.cache[image_hash]
            self.cache[image_hash] = (ocr_result, time.time())
            if len(self.cache) > self.max_size:
                self.cache.popitem(last=False)
            self.stats["cache_size"] = len(self.cache)

    def clear(self):
        with self.lock:
            self.cache.clear()
            self.stats = {k: 0 for k in self.stats.keys()}

    def get_stats(self):
        with self.lock:
            stats = self.stats.copy()
            hit_rate = (stats["hits"] / stats["total_requests"] * 100) if stats["total_requests"] > 0 else 0
            stats["hit_rate_percent"] = hit_rate
            return stats


_ocr_cache = OCRAssetCache(max_size=50, similarity_threshold=0.90)


def _ensure_pytesseract(tesseract_cmd: Optional[str] = None) -> bool:
    """Lazy import and configure pytesseract. Returns True if tesseract binary available."""
    global pytesseract, OCR_AVAILABLE
    if pytesseract is not None:
        return OCR_AVAILABLE
    try:
        import pytesseract as _pytess
        pytesseract = _pytess
        # Auto-detect if possible
        if tesseract_cmd:
            pytesseract.pytesseract.tesseract_cmd = tesseract_cmd
        else:
            # Try common Windows path
            common = [r"C:\Program Files\Tesseract-OCR\tesseract.exe", r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"]
            for p in common:
                if Path(p).exists():
                    pytesseract.pytesseract.tesseract_cmd = str(p)
                    break
        try:
            _ = pytesseract.get_tesseract_version()
            OCR_AVAILABLE = True
            return True
        except Exception:
            OCR_AVAILABLE = False
            return False
    except ImportError:
        OCR_AVAILABLE = False
        return False


def capture_screen_mss(monitor: int = 1, region: Optional[tuple] = None):
    """Capture a PIL Image using mss. Returns PIL.Image or raises if mss not available."""
    if mss is None:
        raise RuntimeError("mss is not installed. Install with: pip install mss")
    with mss() as sct:
        if len(sct.monitors) <= monitor:
            monitor = 1
        mon = sct.monitors[monitor]
        if region:
            x, y, w, h = region
            monitor_spec = {"top": mon["top"] + y, "left": mon["left"] + x, "width": w, "height": h, "mon": monitor}
        else:
            monitor_spec = {"top": mon["top"], "left": mon["left"], "width": mon["width"], "height": mon["height"], "mon": monitor}
        sct_img = sct.grab(monitor_spec)
        img = Image.frombytes("RGB", sct_img.size, sct_img.bgra, "raw", "BGRX")
        return img


def encode_image_to_base64(image, format: str = "JPEG", max_size: tuple = (512, 512)) -> str:
    """Encode PIL.Image to base64 string, resizing to max_size if larger."""
    if image.size[0] > max_size[0] or image.size[1] > max_size[1]:
        image = image.copy()
        image.thumbnail(max_size, Image.Resampling.LANCZOS)
    buffered = io.BytesIO()
    image.save(buffered, format=format)
    import base64
    return base64.b64encode(buffered.getvalue()).decode("utf-8")


def extract_text_with_cache(image, lang: str = "eng", tesseract_cmd: Optional[str] = None, timeout: int = 30) -> str:
    """Extract text from PIL.Image using pytesseract with caching."""
    if not _ensure_pytesseract(tesseract_cmd):
        return ""
    cached = _ocr_cache.get(image)
    if cached is not None:
        return cached
    try:
        # Convert PIL to OpenCV grayscale for thresholding if cv2 available
        if cv2 is not None:
            opencv_image = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
            gray = cv2.cvtColor(opencv_image, cv2.COLOR_BGR2GRAY)
            _, threshold = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
            text = pytesseract.image_to_string(threshold, lang=lang, timeout=timeout)
        else:
            text = pytesseract.image_to_string(image, lang=lang, timeout=timeout)
        result = text.strip()
        _ocr_cache.put(image, result)
        return result
    except Exception as e:
        return ""


def get_ocr_cache_stats():
    return _ocr_cache.get_stats()


def clear_ocr_cache():
    _ocr_cache.clear()
    return "OCR cache cleared"
