"""ScheduleManager — creates cron jobs for recurring evolution source updates."""

from __future__ import annotations

import logging
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from jarvis.evolution.models import LearningPlan

logger = logging.getLogger(__name__)


class ScheduleManager:
    """Translates ScheduleSpecs from a LearningPlan into cron jobs.

    Each schedule in the plan is registered via ``cron_engine.add_cron_job()``
    so that sources are periodically re-fetched.
    """

    def __init__(self, cron_engine: Any | None = None) -> None:
        self._cron_engine = cron_engine

    async def create_schedules(self, plan: LearningPlan) -> int:
        """Create cron jobs for every ScheduleSpec in *plan*.

        Args:
            plan: The LearningPlan whose ``.schedules`` list is iterated.

        Returns:
            Number of cron jobs successfully created.
        """
        if self._cron_engine is None:
            return 0

        created = 0
        for spec in plan.schedules:
            job_name = f"evolution_{plan.goal_slug}_{spec.name}"
            source_url = spec.source_url or ""
            description = (
                f"[evolution-update:{plan.id}:{source_url}] "
                f"{spec.description or spec.name}"
            )

            try:
                await self._cron_engine.add_cron_job(
                    name=job_name,
                    schedule=spec.cron_expression,
                    description=description,
                )
                created += 1
                logger.info("Cron-Job erstellt: %s (%s)", job_name, spec.cron_expression)
            except Exception:
                logger.exception("Cron-Job konnte nicht erstellt werden: %s", job_name)

        return created
