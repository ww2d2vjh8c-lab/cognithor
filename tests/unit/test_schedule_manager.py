"""Tests for ScheduleManager — cron jobs for recurring source updates."""

from __future__ import annotations

from unittest.mock import AsyncMock, MagicMock

import pytest

from jarvis.evolution.models import LearningPlan, ScheduleSpec
from jarvis.evolution.schedule_manager import ScheduleManager


def _make_plan(
    schedules: list[ScheduleSpec] | None = None,
    goal: str = "Learn Rust",
) -> LearningPlan:
    plan = LearningPlan(goal=goal)
    if schedules:
        plan.schedules = schedules
    return plan


def _make_cron_engine() -> MagicMock:
    engine = MagicMock()
    engine.add_cron_job = AsyncMock()
    return engine


@pytest.mark.asyncio
async def test_create_schedules():
    """1 ScheduleSpec -> cron add_cron_job called once, returns 1."""
    engine = _make_cron_engine()
    mgr = ScheduleManager(cron_engine=engine)

    plan = _make_plan(schedules=[
        ScheduleSpec(name="daily-rust", cron_expression="0 8 * * *", source_url="https://doc.rust-lang.org"),
    ])

    count = await mgr.create_schedules(plan)

    assert count == 1
    engine.add_cron_job.assert_called_once()


@pytest.mark.asyncio
async def test_create_multiple_schedules():
    """2 ScheduleSpecs -> 2 jobs, returns 2."""
    engine = _make_cron_engine()
    mgr = ScheduleManager(cron_engine=engine)

    plan = _make_plan(schedules=[
        ScheduleSpec(name="daily-rust", cron_expression="0 8 * * *", source_url="https://doc.rust-lang.org"),
        ScheduleSpec(name="weekly-crates", cron_expression="0 9 * * 1", source_url="https://crates.io"),
    ])

    count = await mgr.create_schedules(plan)

    assert count == 2
    assert engine.add_cron_job.call_count == 2


@pytest.mark.asyncio
async def test_skip_empty_schedules():
    """No schedules -> returns 0, no cron calls."""
    engine = _make_cron_engine()
    mgr = ScheduleManager(cron_engine=engine)

    plan = _make_plan(schedules=[])

    count = await mgr.create_schedules(plan)

    assert count == 0
    engine.add_cron_job.assert_not_called()


@pytest.mark.asyncio
async def test_cron_job_name_prefixed():
    """Job name includes 'evolution_' prefix."""
    engine = _make_cron_engine()
    mgr = ScheduleManager(cron_engine=engine)

    plan = _make_plan(schedules=[
        ScheduleSpec(name="daily-rust", cron_expression="0 8 * * *", source_url="https://doc.rust-lang.org"),
    ])

    await mgr.create_schedules(plan)

    call_kwargs = engine.add_cron_job.call_args
    # name could be positional or keyword — check the actual value
    # We expect name= kwarg with "evolution_" prefix
    name_arg = call_kwargs.kwargs.get("name") or call_kwargs.args[0]
    assert name_arg.startswith("evolution_")
    assert "learn-rust" in name_arg  # goal_slug
    assert "daily-rust" in name_arg  # spec.name


@pytest.mark.asyncio
async def test_no_cron_engine():
    """cron_engine=None -> returns 0, no crash."""
    mgr = ScheduleManager(cron_engine=None)

    plan = _make_plan(schedules=[
        ScheduleSpec(name="daily-rust", cron_expression="0 8 * * *", source_url="https://doc.rust-lang.org"),
    ])

    count = await mgr.create_schedules(plan)

    assert count == 0
