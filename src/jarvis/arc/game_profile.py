"""ARC-AGI-3 GameProfile — persistent per-game mechanic profile with learning metrics."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Literal

from jarvis.utils.logging import get_logger

__all__ = ["GameProfile", "StrategyMetrics"]

log = get_logger(__name__)

_DEFAULT_BASE_DIR = Path.home() / ".jarvis" / "arc"


@dataclass
class StrategyMetrics:
    """Tracks success metrics for a single solver strategy."""

    attempts: int = 0
    wins: int = 0
    total_levels_solved: int = 0
    avg_steps_to_win: float = 0.0
    avg_budget_ratio: float = 0.0

    @property
    def win_rate(self) -> float:
        if self.attempts == 0:
            return 0.0
        return self.wins / self.attempts


@dataclass
class GameProfile:
    """Persistent per-game mechanic profile."""

    game_id: str
    game_type: Literal["click", "keyboard", "mixed"]
    available_actions: list[int]

    # Analysis results
    click_zones: list[tuple[int, int]]
    target_colors: list[int]
    movement_effects: dict[int, str]
    win_condition: str
    vision_description: str
    vision_strategy: str

    # Learning metrics
    strategy_metrics: dict[str, StrategyMetrics]
    total_runs: int = 0
    best_score: int = 0

    # Meta
    analyzed_at: str = ""
    profile_version: int = 1

    def to_dict(self) -> dict[str, Any]:
        d = {
            "game_id": self.game_id,
            "game_type": self.game_type,
            "available_actions": self.available_actions,
            "click_zones": [list(z) for z in self.click_zones],
            "target_colors": self.target_colors,
            "movement_effects": {str(k): v for k, v in self.movement_effects.items()},
            "win_condition": self.win_condition,
            "vision_description": self.vision_description,
            "vision_strategy": self.vision_strategy,
            "strategy_metrics": {
                name: asdict(m) for name, m in self.strategy_metrics.items()
            },
            "total_runs": self.total_runs,
            "best_score": self.best_score,
            "analyzed_at": self.analyzed_at,
            "profile_version": self.profile_version,
        }
        return d

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> GameProfile:
        metrics = {}
        for name, m in d.get("strategy_metrics", {}).items():
            metrics[name] = StrategyMetrics(**m)
        movement = {int(k): v for k, v in d.get("movement_effects", {}).items()}
        click_zones = [tuple(z) for z in d.get("click_zones", [])]
        return cls(
            game_id=d["game_id"],
            game_type=d["game_type"],
            available_actions=d.get("available_actions", []),
            click_zones=click_zones,
            target_colors=d.get("target_colors", []),
            movement_effects=movement,
            win_condition=d.get("win_condition", "unknown"),
            vision_description=d.get("vision_description", ""),
            vision_strategy=d.get("vision_strategy", ""),
            strategy_metrics=metrics,
            total_runs=d.get("total_runs", 0),
            best_score=d.get("best_score", 0),
            analyzed_at=d.get("analyzed_at", ""),
            profile_version=d.get("profile_version", 1),
        )

    def save(self, base_dir: Path | None = None) -> None:
        base = base_dir or _DEFAULT_BASE_DIR
        profile_dir = base / "game_profiles"
        profile_dir.mkdir(parents=True, exist_ok=True)
        path = profile_dir / f"{self.game_id}.json"
        path.write_text(json.dumps(self.to_dict(), indent=2), encoding="utf-8")
        log.info("arc.profile_saved", game_id=self.game_id, path=str(path))

    @classmethod
    def load(cls, game_id: str, base_dir: Path | None = None) -> GameProfile | None:
        base = base_dir or _DEFAULT_BASE_DIR
        path = base / "game_profiles" / f"{game_id}.json"
        if not path.exists():
            return None
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            return cls.from_dict(data)
        except (json.JSONDecodeError, KeyError, TypeError) as exc:
            log.warning("arc.profile_load_failed", game_id=game_id, error=str(exc))
            return None

    @classmethod
    def exists(cls, game_id: str, base_dir: Path | None = None) -> bool:
        base = base_dir or _DEFAULT_BASE_DIR
        return (base / "game_profiles" / f"{game_id}.json").exists()
