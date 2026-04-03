"""Tests for Skill Lifecycle Fix — context pipeline, registry injection, lifecycle cron."""

from __future__ import annotations

from unittest.mock import MagicMock

import pytest


class TestContextPipelineSkillLookup:
    def test_get_skill_context_returns_matches(self):
        from jarvis.core.context_pipeline import ContextPipeline

        cp = ContextPipeline.__new__(ContextPipeline)
        cp._skill_registry = MagicMock()

        mock_skill = MagicMock()
        mock_skill.name = "ARC-AGI-3 Benchmark"
        mock_skill.description = "Spielt ARC-AGI-3 Games"
        mock_skill.trigger_keywords = ["arc", "benchmark", "puzzle"]

        mock_match = MagicMock()
        mock_match.skill = mock_skill

        cp._skill_registry.match.return_value = [mock_match]

        result = cp._get_skill_context("spiele arc benchmark")

        assert "ARC-AGI-3 Benchmark" in result
        assert "Spielt ARC-AGI-3" in result
        assert "arc" in result
        cp._skill_registry.match.assert_called_once()

    def test_get_skill_context_no_registry_returns_empty(self):
        from jarvis.core.context_pipeline import ContextPipeline

        cp = ContextPipeline.__new__(ContextPipeline)
        cp._skill_registry = None

        result = cp._get_skill_context("anything")
        assert result == ""

    def test_get_skill_context_no_matches_returns_empty(self):
        from jarvis.core.context_pipeline import ContextPipeline

        cp = ContextPipeline.__new__(ContextPipeline)
        cp._skill_registry = MagicMock()
        cp._skill_registry.match.return_value = []

        result = cp._get_skill_context("something unrelated")
        assert result == ""

    def test_get_skill_context_exception_returns_empty(self):
        from jarvis.core.context_pipeline import ContextPipeline

        cp = ContextPipeline.__new__(ContextPipeline)
        cp._skill_registry = MagicMock()
        cp._skill_registry.match.side_effect = RuntimeError("DB error")

        result = cp._get_skill_context("test")
        assert result == ""
