"""System Detector — comprehensive hardware and software profiling.

Detects CPU, RAM, GPU, disk, network, Ollama, LM Studio at startup.
Results cached to ~/.jarvis/system_profile.json.
"""

from __future__ import annotations

import json
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from jarvis.utils.logging import get_logger

log = get_logger(__name__)

__all__ = ["DetectionResult", "SystemProfile"]


@dataclass
class DetectionResult:
    """Result of a single detection target."""

    key: str
    value: str
    status: str  # "ok" | "warn" | "fail"
    raw_data: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "value": self.value,
            "status": self.status,
            "raw_data": self.raw_data,
        }

    @classmethod
    def from_dict(cls, d: dict[str, Any]) -> DetectionResult:
        return cls(
            key=d["key"], value=d["value"], status=d["status"], raw_data=d.get("raw_data", {})
        )


@dataclass
class SystemProfile:
    """Complete system profile with all detection results."""

    results: dict[str, DetectionResult] = field(default_factory=dict)
    detected_at: str = field(
        default_factory=lambda: time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
    )

    def get_tier(self) -> str:
        ram_gb = self.results.get("ram", DetectionResult("ram", "", "fail", {})).raw_data.get(
            "total_gb", 0
        )
        cores = self.results.get("cpu", DetectionResult("cpu", "", "fail", {})).raw_data.get(
            "physical_cores", 0
        )
        vram = self.results.get("gpu", DetectionResult("gpu", "", "fail", {})).raw_data.get(
            "vram_total_gb", 0
        )
        if ram_gb >= 64 and cores >= 16 and vram >= 48:
            return "enterprise"
        if vram >= 16 and ram_gb >= 32:
            return "power"
        if vram >= 8 and ram_gb >= 16:
            return "standard"
        return "minimal"

    def get_available_modes(self) -> list[str]:
        modes = []
        ollama = self.results.get("ollama", DetectionResult("ollama", "", "fail", {}))
        network = self.results.get("network", DetectionResult("network", "", "fail", {}))
        gpu = self.results.get("gpu", DetectionResult("gpu", "", "fail", {}))
        if ollama.raw_data.get("running") or gpu.raw_data.get("vram_total_gb", 0) >= 4:
            modes.append("offline")
        if network.raw_data.get("internet"):
            modes.append("online")
        if "offline" in modes and "online" in modes:
            modes.append("hybrid")
        if not modes:
            modes.append("offline")
        return modes

    def get_recommended_mode(self) -> str:
        modes = self.get_available_modes()
        ollama = self.results.get("ollama", DetectionResult("ollama", "", "fail", {}))
        gpu = self.results.get("gpu", DetectionResult("gpu", "", "fail", {}))
        if (
            "offline" in modes
            and ollama.raw_data.get("running")
            and gpu.raw_data.get("vram_total_gb", 0) >= 8
        ):
            return "offline"
        if "hybrid" in modes:
            return "hybrid"
        if "online" in modes:
            return "online"
        return "offline"

    def to_dict(self) -> dict[str, Any]:
        return {
            "detected_at": self.detected_at,
            "tier": self.get_tier(),
            "recommended_mode": self.get_recommended_mode(),
            "available_modes": self.get_available_modes(),
            "results": {k: v.to_dict() for k, v in self.results.items()},
        }

    def save(self, path: Path) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(self.to_dict(), indent=2), encoding="utf-8")

    @classmethod
    def load(cls, path: Path) -> SystemProfile | None:
        if not path.exists():
            return None
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            profile = cls(detected_at=data.get("detected_at", ""))
            for k, v in data.get("results", {}).items():
                profile.results[k] = DetectionResult.from_dict(v)
            return profile
        except Exception:
            return None
