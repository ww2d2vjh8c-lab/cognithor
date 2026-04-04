"""Tests for GameProfile dataclass and persistence."""

from __future__ import annotations

import json
import os
import tempfile

import pytest

from jarvis.arc.game_profile import GameProfile, StrategyMetrics


class TestStrategyMetrics:
    def test_defaults(self):
        m = StrategyMetrics()
        assert m.attempts == 0
        assert m.wins == 0
        assert m.total_levels_solved == 0
        assert m.avg_steps_to_win == 0.0
        assert m.avg_budget_ratio == 0.0

    def test_win_rate_no_attempts(self):
        m = StrategyMetrics()
        assert m.win_rate == 0.0

    def test_win_rate_with_data(self):
        m = StrategyMetrics(attempts=10, wins=3)
        assert m.win_rate == pytest.approx(0.3)


class TestGameProfile:
    def _make_profile(self, **overrides) -> GameProfile:
        defaults = dict(
            game_id="ft09",
            game_type="click",
            available_actions=[5, 6],
            click_zones=[(10, 20), (30, 40)],
            target_colors=[3],
            movement_effects={},
            win_condition="clear_board",
            vision_description="A grid puzzle with red clusters",
            vision_strategy="Click all red clusters",
            strategy_metrics={},
            analyzed_at="2026-04-04T12:00:00",
        )
        defaults.update(overrides)
        return GameProfile(**defaults)

    def test_create_profile(self):
        p = self._make_profile()
        assert p.game_id == "ft09"
        assert p.game_type == "click"
        assert p.total_runs == 0
        assert p.best_score == 0
        assert p.profile_version == 1

    def test_to_dict_roundtrip(self):
        p = self._make_profile(
            strategy_metrics={
                "cluster_click": StrategyMetrics(attempts=5, wins=2),
            },
        )
        d = p.to_dict()
        assert isinstance(d, dict)
        assert d["game_id"] == "ft09"
        assert d["strategy_metrics"]["cluster_click"]["attempts"] == 5

        p2 = GameProfile.from_dict(d)
        assert p2.game_id == p.game_id
        assert p2.strategy_metrics["cluster_click"].wins == 2

    def test_save_and_load(self, tmp_path):
        p = self._make_profile()
        p.save(base_dir=tmp_path)

        loaded = GameProfile.load("ft09", base_dir=tmp_path)
        assert loaded is not None
        assert loaded.game_id == "ft09"
        assert loaded.click_zones == [(10, 20), (30, 40)]

    def test_load_nonexistent_returns_none(self, tmp_path):
        assert GameProfile.load("nonexistent", base_dir=tmp_path) is None

    def test_exists(self, tmp_path):
        assert GameProfile.exists("ft09", base_dir=tmp_path) is False
        p = self._make_profile()
        p.save(base_dir=tmp_path)
        assert GameProfile.exists("ft09", base_dir=tmp_path) is True

    def test_save_creates_directory(self, tmp_path):
        sub = tmp_path / "deep" / "nested"
        p = self._make_profile()
        p.save(base_dir=sub)
        assert (sub / "game_profiles" / "ft09.json").exists()

    def test_load_corrupt_json_returns_none(self, tmp_path):
        profile_dir = tmp_path / "game_profiles"
        profile_dir.mkdir(parents=True)
        (profile_dir / "broken.json").write_text("{invalid json")
        assert GameProfile.load("broken", base_dir=tmp_path) is None
