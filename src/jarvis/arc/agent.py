"""CognithorArcAgent — dual-mode ARC agent.

Mode 1 (ARC-AGI-3 Games): RL agent with explorer, state graph, CNN predictor.
Mode 2 (Classic ARC Puzzles): DSL + LLM hybrid solver for static grid tasks.

The mode is selected automatically based on whether the game_id matches
an ARC-AGI-3 SDK environment or a classic JSON puzzle file.
"""

from __future__ import annotations

from typing import Any

from jarvis.arc.adapter import ArcEnvironmentAdapter
from jarvis.arc.audit import ArcAuditTrail
from jarvis.arc.episode_memory import EpisodeMemory
from jarvis.arc.explorer import HypothesisDrivenExplorer
from jarvis.arc.goal_inference import GoalInferenceModule
from jarvis.arc.mechanics_model import MechanicsModel
from jarvis.arc.state_graph import StateGraphNavigator
from jarvis.arc.visual_encoder import VisualStateEncoder
from jarvis.utils.logging import get_logger

__all__ = ["CognithorArcAgent"]

log = get_logger(__name__)

_GOAL_REANALYSIS_INTERVAL = 5


class CognithorArcAgent:
    """Dual-mode ARC Agent.

    ARC-AGI-3 Games: RL agent (Explorer + StateGraph + CNN, >2000 FPS)
    Classic Puzzles:  DSL search + LLM code-generation

    Args:
        game_id: The ARC-AGI-3 environment or classic puzzle identifier.
        use_llm_planner: Whether to consult the LLM planner periodically (RL mode).
        llm_call_interval: Steps between LLM consultations (RL mode).
        max_steps_per_level: Max steps before abandoning a level (RL mode).
        max_resets_per_level: Max resets before giving up (RL mode).
    """

    def __init__(
        self,
        game_id: str,
        use_llm_planner: bool = False,
        llm_call_interval: int = 30,
        max_steps_per_level: int = 500,
        max_resets_per_level: int = 20,
        **kwargs: Any,
    ) -> None:
        self.game_id = game_id
        self.use_llm_planner = use_llm_planner
        self.llm_call_interval = llm_call_interval
        self.max_steps_per_level = max_steps_per_level
        self.max_resets_per_level = max_resets_per_level

        # Shared modules
        self.memory = EpisodeMemory()
        self.audit_trail = ArcAuditTrail(game_id)

        # RL modules (initialized lazily for ARC-AGI-3 games)
        self._rl_initialized = False
        self.adapter: ArcEnvironmentAdapter | None = None
        self.goals: GoalInferenceModule | None = None
        self.explorer: HypothesisDrivenExplorer | None = None
        self.encoder: VisualStateEncoder | None = None
        self.mechanics: MechanicsModel | None = None
        self.state_graph: StateGraphNavigator | None = None

    def _init_rl(self) -> None:
        """Initialize RL subsystems for ARC-AGI-3 interactive games."""
        if self._rl_initialized:
            return
        self.adapter = ArcEnvironmentAdapter(self.game_id)
        self.goals = GoalInferenceModule()
        self.explorer = HypothesisDrivenExplorer()
        self.encoder = VisualStateEncoder()
        self.mechanics = MechanicsModel()
        self.state_graph = StateGraphNavigator()
        self._rl_initialized = True

    def _is_interactive_game(self) -> bool:
        """Check if game_id is an ARC-AGI-3 interactive environment."""
        try:
            import arc_agi

            arcade = arc_agi.Arcade()
            envs = arcade.get_environments()
            game_ids = {e.game_id.split("-")[0] for e in envs}
            return self.game_id.split("-")[0] in game_ids or self.game_id in {
                e.game_id for e in envs
            }
        except Exception:
            pass

        # Fallback: check if environment_files directory exists
        from pathlib import Path

        env_dir = Path("environment_files") / self.game_id.split("-")[0]
        return env_dir.exists()

    def run(self) -> dict[str, Any]:
        """Run the agent. Auto-selects RL or DSL mode."""
        if self._is_interactive_game():
            log.info("arc_mode_rl", game=self.game_id)
            return self._run_rl()
        log.info("arc_mode_classic", game=self.game_id)
        return self._run_classic()

    # ── RL Mode (ARC-AGI-3 Interactive Games) ────────────────────

    def _run_rl(self) -> dict[str, Any]:
        """Run the RL agent on an ARC-AGI-3 interactive game."""
        self._init_rl()
        assert self.adapter is not None

        self.audit_trail.log_game_start()
        total_steps = 0
        levels_completed = 0

        try:
            obs = self.adapter.reset()
            self.state_graph.add_state(obs)

            while total_steps < self.max_steps_per_level:
                total_steps += 1

                # Encode state
                _state_desc = self.encoder.encode_for_llm(obs.raw_grid)

                # Goal inference (periodic)
                if total_steps % _GOAL_REANALYSIS_INTERVAL == 0 and self.goals:
                    self.goals.analyze(obs)

                # Select action
                action = self.explorer.select_action(obs, self.memory, self.mechanics)

                # Execute
                new_obs = self.adapter.step(action)

                # Record transition
                self.memory.record_transition(obs, action, new_obs)
                if self.mechanics:
                    self.mechanics.observe(obs, action, new_obs)

                # Check win/level completion
                if (
                    hasattr(new_obs, "levels_completed")
                    and new_obs.levels_completed > levels_completed
                ):
                        levels_completed = new_obs.levels_completed
                        log.info(
                            "arc_level_complete",
                            level=levels_completed,
                            steps=total_steps,
                        )

                # Log
                self.audit_trail.log_step(
                    level=getattr(new_obs, "level", 0),
                    step=total_steps,
                    action=str(action),
                    game_state=str(getattr(new_obs, "game_state", "")),
                    pixels_changed=getattr(new_obs, "changed_pixels", 0),
                )

                obs = new_obs

        except Exception as exc:
            log.warning("arc_rl_error", error=str(exc)[:200])

        score = levels_completed / max(1, getattr(self.adapter, "total_levels", 9))
        self.audit_trail.log_game_end(score)

        return {
            "game_id": self.game_id,
            "levels_completed": levels_completed,
            "total_steps": total_steps,
            "score": score,
        }

    # ── Classic Mode (Static Grid Puzzles) ───────────────────────

    def _run_classic(self) -> dict[str, Any]:
        """Run the DSL + LLM solver on a classic ARC puzzle."""
        import asyncio

        from jarvis.arc.classic.solver import ArcSolver

        task = self._load_classic_task()
        if task is None:
            return {
                "game_id": self.game_id,
                "win": False,
                "attempts": 0,
                "score": 0.0,
            }

        solver = ArcSolver()

        try:
            loop = asyncio.get_running_loop()
        except RuntimeError:
            loop = None

        if loop and loop.is_running():
            import concurrent.futures

            with concurrent.futures.ThreadPoolExecutor() as pool:
                solutions = pool.submit(asyncio.run, solver.solve(task)).result()
        else:
            solutions = asyncio.run(solver.solve(task))

        win = len(solutions) > 0
        return {
            "game_id": self.game_id,
            "win": win,
            "attempts": len(solutions),
            "levels_completed": 1 if win else 0,
            "total_steps": len(solutions),
            "score": 1.0 if win else 0.0,
        }

    def _load_classic_task(self) -> Any:
        """Load a classic ARC puzzle from JSON file."""
        import json
        from pathlib import Path

        from jarvis.arc.classic.task_parser import ArcTask

        for base in [
            Path.home() / ".jarvis" / "arc" / "tasks",
            Path("data") / "arc",
        ]:
            task_file = base / f"{self.game_id}.json"
            if task_file.exists():
                try:
                    data = json.loads(task_file.read_text())
                    examples = [(ex["input"], ex["output"]) for ex in data.get("train", [])]
                    test_input = data.get("test", [{}])[0].get("input", [[]])
                    return ArcTask(
                        task_id=self.game_id,
                        examples=examples,
                        test_input=test_input,
                    )
                except Exception:
                    pass

        log.warning("arc_classic_task_not_found", game=self.game_id)
        return None
