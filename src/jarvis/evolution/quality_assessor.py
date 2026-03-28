"""QualityAssessor — coverage check + LLM self-examination for Phase 5C."""
from __future__ import annotations

import json
import logging
from typing import Any, Callable, Coroutine, Optional

from jarvis.evolution.models import QualityQuestion, SubGoal

__all__ = ["QualityAssessor"]

logger = logging.getLogger(__name__)

# Coverage thresholds per metric
_COVERAGE_THRESHOLDS = {
    "vault_entries": 5,
    "chunks_created": 20,
    "entities_created": 5,
    "sources_fetched": 3,
}


class QualityAssessor:
    """Assess learning quality via coverage metrics and LLM-generated exam."""

    def __init__(
        self,
        mcp_client: Any,
        llm_fn: Callable[[str], Coroutine[Any, Any, str]],
        coverage_threshold: float = 0.7,
        quality_threshold: float = 0.8,
    ) -> None:
        self._mcp = mcp_client
        self._llm = llm_fn
        self._coverage_threshold = coverage_threshold
        self._quality_threshold = quality_threshold

    # ------------------------------------------------------------------
    # Coverage
    # ------------------------------------------------------------------

    def check_coverage(self, subgoal: SubGoal) -> float:
        """Return ratio of coverage checks that pass (0.0 .. 1.0)."""
        checks = [
            subgoal.vault_entries >= _COVERAGE_THRESHOLDS["vault_entries"],
            subgoal.chunks_created >= _COVERAGE_THRESHOLDS["chunks_created"],
            subgoal.entities_created >= _COVERAGE_THRESHOLDS["entities_created"],
            subgoal.sources_fetched >= _COVERAGE_THRESHOLDS["sources_fetched"],
        ]
        return sum(checks) / len(checks)

    # ------------------------------------------------------------------
    # Question generation
    # ------------------------------------------------------------------

    async def generate_questions(
        self, topic: str, count: int = 5
    ) -> list[QualityQuestion]:
        """Ask the LLM to produce *count* exam questions about *topic*."""
        prompt = (
            f"Generate exactly {count} exam questions about the topic: {topic}\n"
            "Return ONLY valid JSON in this format:\n"
            '{"questions": [{"question": "...", "expected_answer": "..."}]}\n'
            "No extra text."
        )
        raw = await self._llm(prompt)
        data = json.loads(raw)
        return [
            QualityQuestion(
                question=q["question"],
                expected_answer=q["expected_answer"],
            )
            for q in data["questions"]
        ]

    # ------------------------------------------------------------------
    # Answering (from memory, not web)
    # ------------------------------------------------------------------

    async def answer_question(self, q: QualityQuestion) -> QualityQuestion:
        """Search vault + memory for an answer; fill *actual_answer*."""
        parts: list[str] = []

        vault_result = await self._mcp.call_tool(
            "vault_search", {"query": q.question}
        )
        if vault_result.content:
            parts.append(vault_result.content)

        memory_result = await self._mcp.call_tool(
            "search_memory", {"query": q.question}
        )
        if memory_result.content:
            parts.append(memory_result.content)

        q.actual_answer = "\n".join(parts) if parts else ""
        return q

    # ------------------------------------------------------------------
    # Grading
    # ------------------------------------------------------------------

    async def grade_question(self, q: QualityQuestion) -> QualityQuestion:
        """Let the LLM grade *actual_answer* against *expected_answer*."""
        prompt = (
            "Grade the following answer.\n"
            f"Question: {q.question}\n"
            f"Expected answer: {q.expected_answer}\n"
            f"Actual answer: {q.actual_answer}\n\n"
            "Return ONLY valid JSON: {\"score\": <0.0-1.0>, \"correct\": <bool>}\n"
            "No extra text."
        )
        raw = await self._llm(prompt)
        data = json.loads(raw)
        q.score = float(data["score"])
        q.passed = bool(data["correct"])
        return q

    # ------------------------------------------------------------------
    # Full pipeline
    # ------------------------------------------------------------------

    async def run_quality_test(
        self, subgoal: SubGoal, goal_slug: str
    ) -> dict[str, Any]:
        """Run the complete quality-test pipeline and return a result dict."""
        coverage_score = self.check_coverage(subgoal)

        if coverage_score < self._coverage_threshold:
            logger.info(
                "Coverage too low (%.2f < %.2f) — skipping quality test for %s",
                coverage_score,
                self._coverage_threshold,
                goal_slug,
            )
            return {
                "coverage_score": coverage_score,
                "quality_score": 0,
                "passed": False,
                "questions": [],
                "failed_questions": [],
            }

        questions = await self.generate_questions(subgoal.title)

        for q in questions:
            await self.answer_question(q)
            await self.grade_question(q)

        scores = [q.score for q in questions if q.score is not None]
        quality_score = sum(scores) / len(scores) if scores else 0.0
        failed = [q for q in questions if not q.passed]

        return {
            "coverage_score": coverage_score,
            "quality_score": quality_score,
            "passed": quality_score >= self._quality_threshold and not failed,
            "questions": questions,
            "failed_questions": failed,
        }
