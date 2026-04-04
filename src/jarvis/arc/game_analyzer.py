"""ARC-AGI-3 GameAnalyzer — sacrifice-level analysis + 2 vision calls to build GameProfile."""

from __future__ import annotations

import base64
import io
import json
import re
from dataclasses import dataclass, field
from typing import Any

import numpy as np

from jarvis.utils.logging import get_logger

__all__ = ["GameAnalyzer"]

log = get_logger(__name__)

PALETTE = [
    (255, 255, 255), (0, 0, 0), (0, 116, 217), (255, 65, 54),
    (46, 204, 64), (255, 220, 0), (170, 170, 170), (255, 133, 27),
    (127, 219, 255), (135, 12, 37), (240, 18, 190), (200, 200, 200),
    (200, 200, 100), (100, 50, 150), (0, 200, 200), (128, 0, 255),
]

_ACTION_NAMES = {1: "UP", 2: "DOWN", 3: "LEFT", 4: "RIGHT", 5: "Interact", 6: "Click(x,y)"}


def _grid_to_png_b64(grid: np.ndarray, scale: int = 4) -> str:
    """Convert 64x64 colour-index grid to upscaled PNG as base64."""
    from PIL import Image

    if grid.ndim == 3:
        grid = grid[0]
    h, w = grid.shape
    img = np.zeros((h * scale, w * scale, 3), dtype=np.uint8)
    for r in range(h):
        for c in range(w):
            color = PALETTE[min(int(grid[r, c]), 15)]
            img[r * scale : (r + 1) * scale, c * scale : (c + 1) * scale] = color
    buf = io.BytesIO()
    Image.fromarray(img).save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("ascii")


def _parse_vision_json(raw: str) -> dict | None:
    """3-tier JSON extraction: direct parse, markdown block, balanced brace."""
    raw = re.sub(r"<think>.*?</think>", "", raw, flags=re.DOTALL).strip()

    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            return data
    except (json.JSONDecodeError, ValueError):
        pass

    md = re.search(r"```(?:json)?\s*\n?(.*?)\n?```", raw, re.DOTALL)
    if md:
        try:
            data = json.loads(md.group(1))
            if isinstance(data, dict):
                return data
        except (json.JSONDecodeError, ValueError):
            pass

    pos = raw.find("{")
    if pos != -1:
        depth = 0
        for i in range(pos, len(raw)):
            if raw[i] == "{":
                depth += 1
            elif raw[i] == "}":
                depth -= 1
            if depth == 0:
                try:
                    data = json.loads(raw[pos : i + 1])
                    if isinstance(data, dict):
                        return data
                except (json.JSONDecodeError, ValueError):
                    pass
                break

    return None


@dataclass
class SacrificeReport:
    """Results from the sacrifice level exploration."""

    clicks_tested: list[tuple[int, int, str]] = field(default_factory=list)
    movements_tested: dict[int, int] = field(default_factory=dict)
    unique_states_seen: int = 0
    game_over_trigger: str | None = None
    frames: list[np.ndarray] = field(default_factory=list)


class GameAnalyzer:
    """Analyzes ARC-AGI-3 games by sacrificing one level + 2 vision calls."""

    def __init__(self, arcade: Any | None = None):
        self._arcade = arcade
