"""Tests for GameAnalyzer — opferlevel + vision analysis."""

from __future__ import annotations

import json
import re
from dataclasses import asdict
from unittest.mock import MagicMock, patch

import numpy as np
import pytest

from jarvis.arc.game_analyzer import (
    GameAnalyzer,
    SacrificeReport,
    _grid_to_png_b64,
    _parse_vision_json,
)


class TestVisionHelpers:
    def test_grid_to_png_b64_produces_base64(self):
        grid = np.zeros((64, 64), dtype=np.int8)
        grid[10:20, 10:20] = 3  # red block
        b64 = _grid_to_png_b64(grid, scale=4)
        assert isinstance(b64, str)
        assert len(b64) > 100
        # Should be valid base64
        import base64
        raw = base64.b64decode(b64)
        assert raw[:4] == b"\x89PNG"

    def test_grid_to_png_b64_handles_3d(self):
        grid = np.zeros((1, 64, 64), dtype=np.int8)
        b64 = _grid_to_png_b64(grid, scale=2)
        assert isinstance(b64, str)

    def test_parse_vision_json_direct(self):
        raw = '{"game_type": "click", "target_color": 3}'
        result = _parse_vision_json(raw)
        assert result["game_type"] == "click"

    def test_parse_vision_json_markdown(self):
        raw = 'Some text\n```json\n{"game_type": "keyboard"}\n```\nMore text'
        result = _parse_vision_json(raw)
        assert result["game_type"] == "keyboard"

    def test_parse_vision_json_with_think_tags(self):
        raw = '<think>reasoning here</think>\n{"game_type": "mixed"}'
        result = _parse_vision_json(raw)
        assert result["game_type"] == "mixed"

    def test_parse_vision_json_balanced_brace(self):
        raw = 'The answer is {"game_type": "click", "nested": {"a": 1}} and more'
        result = _parse_vision_json(raw)
        assert result["game_type"] == "click"

    def test_parse_vision_json_unparseable(self):
        assert _parse_vision_json("no json here at all") is None


class TestSacrificeReport:
    def test_defaults(self):
        r = SacrificeReport()
        assert r.clicks_tested == []
        assert r.movements_tested == {}
        assert r.unique_states_seen == 0
        assert r.game_over_trigger is None
        assert r.frames == []
