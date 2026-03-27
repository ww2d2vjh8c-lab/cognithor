"""Tests for SystemDetector — hardware/software detection."""

import json
import pytest
from pathlib import Path


class TestDetectionResult:
    def test_create_ok_result(self):
        from jarvis.system.detector import DetectionResult

        r = DetectionResult(key="cpu", value="AMD Ryzen 9", status="ok", raw_data={"cores": 16})
        assert r.key == "cpu"
        assert r.status == "ok"
        assert r.raw_data["cores"] == 16

    def test_create_fail_result(self):
        from jarvis.system.detector import DetectionResult

        r = DetectionResult(key="gpu", value="No GPU found", status="fail", raw_data={})
        assert r.status == "fail"

    def test_to_dict(self):
        from jarvis.system.detector import DetectionResult

        r = DetectionResult(key="ram", value="32 GB", status="ok", raw_data={"total_gb": 32})
        d = r.to_dict()
        assert d["key"] == "ram"
        assert d["raw_data"]["total_gb"] == 32


class TestSystemProfile:
    def test_empty_profile(self):
        from jarvis.system.detector import SystemProfile

        p = SystemProfile()
        assert len(p.results) == 0

    def test_add_result(self):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["cpu"] = DetectionResult(key="cpu", value="Test", status="ok", raw_data={})
        assert "cpu" in p.results

    def test_get_tier_minimal(self):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["ram"] = DetectionResult(
            key="ram", value="4 GB", status="fail", raw_data={"total_gb": 4}
        )
        p.results["cpu"] = DetectionResult(
            key="cpu", value="2 cores", status="warn", raw_data={"physical_cores": 2}
        )
        p.results["gpu"] = DetectionResult(
            key="gpu", value="None", status="fail", raw_data={"vram_total_gb": 0}
        )
        assert p.get_tier() == "minimal"

    def test_get_tier_power(self):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["ram"] = DetectionResult(
            key="ram", value="64 GB", status="ok", raw_data={"total_gb": 64}
        )
        p.results["cpu"] = DetectionResult(
            key="cpu", value="16 cores", status="ok", raw_data={"physical_cores": 16}
        )
        p.results["gpu"] = DetectionResult(
            key="gpu", value="RTX 4090", status="ok", raw_data={"vram_total_gb": 24}
        )
        assert p.get_tier() in ("power", "enterprise")

    def test_get_available_modes_offline_only(self):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["gpu"] = DetectionResult(
            key="gpu", value="RTX", status="ok", raw_data={"vram_total_gb": 24}
        )
        p.results["ollama"] = DetectionResult(
            key="ollama", value="Running", status="ok", raw_data={"running": True}
        )
        p.results["network"] = DetectionResult(
            key="network", value="No internet", status="fail", raw_data={"internet": False}
        )
        modes = p.get_available_modes()
        assert "offline" in modes
        assert "online" not in modes

    def test_get_recommended_mode(self):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["gpu"] = DetectionResult(
            key="gpu", value="RTX", status="ok", raw_data={"vram_total_gb": 24}
        )
        p.results["ollama"] = DetectionResult(
            key="ollama",
            value="Running",
            status="ok",
            raw_data={"running": True, "models": ["qwen3:32b"]},
        )
        p.results["network"] = DetectionResult(
            key="network", value="OK", status="ok", raw_data={"internet": True}
        )
        mode = p.get_recommended_mode()
        assert mode in ("offline", "hybrid")

    def test_to_dict_roundtrip(self):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["cpu"] = DetectionResult(
            key="cpu", value="Test CPU", status="ok", raw_data={"cores": 8}
        )
        d = p.to_dict()
        assert d["results"]["cpu"]["value"] == "Test CPU"

    def test_save_and_load(self, tmp_path):
        from jarvis.system.detector import DetectionResult, SystemProfile

        p = SystemProfile()
        p.results["ram"] = DetectionResult(
            key="ram", value="32 GB", status="ok", raw_data={"total_gb": 32}
        )
        path = tmp_path / "profile.json"
        p.save(path)
        loaded = SystemProfile.load(path)
        assert loaded is not None
        assert loaded.results["ram"].raw_data["total_gb"] == 32

    def test_load_nonexistent_returns_none(self, tmp_path):
        from jarvis.system.detector import SystemProfile

        result = SystemProfile.load(tmp_path / "nonexistent.json")
        assert result is None
