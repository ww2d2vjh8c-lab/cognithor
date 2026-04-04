"""Tests for CognithorArcAgent — dual-mode (RL + Classic DSL)."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from jarvis.arc.agent import CognithorArcAgent


class TestAgentCreation:
    def test_create_agent(self):
        agent = CognithorArcAgent(game_id="test_001")
        assert agent.game_id == "test_001"
        assert agent.audit_trail is not None
        assert agent.memory is not None

    def test_rl_not_initialized_on_creation(self):
        agent = CognithorArcAgent(game_id="test")
        assert agent._rl_initialized is False
        assert agent.adapter is None

    def test_accepts_all_params(self):
        agent = CognithorArcAgent(
            game_id="test",
            use_llm_planner=True,
            llm_call_interval=10,
            max_steps_per_level=100,
            max_resets_per_level=5,
        )
        assert agent.use_llm_planner is True
        assert agent.max_steps_per_level == 100


class TestModeDetection:
    def test_classic_mode_for_unknown_game(self):
        agent = CognithorArcAgent(game_id="nonexistent_puzzle_xyz")
        with patch.object(agent, "_is_interactive_game", return_value=False):
            with patch.object(agent, "_run_classic", return_value={"win": False}):
                result = agent.run()
                assert result is not None

    def test_rl_mode_for_interactive_game(self):
        agent = CognithorArcAgent(game_id="ls20")
        with patch.object(agent, "_is_interactive_game", return_value=True):
            with patch.object(agent, "_run_rl", return_value={"score": 0.0}):
                result = agent.run()
                assert result is not None


class TestClassicMode:
    def test_classic_solver_with_mock_task(self):
        agent = CognithorArcAgent(game_id="test_classic")
        with patch.object(agent, "_is_interactive_game", return_value=False):
            with patch.object(
                agent,
                "_load_classic_task",
                return_value=MagicMock(
                    task_id="test",
                    examples=[([[1, 2], [3, 4]], [[3, 1], [4, 2]])],
                    test_input=[[5, 6], [7, 8]],
                ),
            ):
                result = agent._run_classic()
                assert result["win"] is True  # DSL finds rotate_90

    def test_classic_no_task_returns_loss(self):
        agent = CognithorArcAgent(game_id="nonexistent")
        with patch.object(agent, "_load_classic_task", return_value=None):
            result = agent._run_classic()
            assert result["win"] is False
