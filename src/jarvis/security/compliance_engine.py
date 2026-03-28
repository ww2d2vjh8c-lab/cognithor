"""GDPR Compliance Engine — central runtime enforcement.

Every data processing operation must pass through this engine.
It enforces: consent requirements, legal basis validation,
purpose limitations, and privacy mode.
"""
from __future__ import annotations

from jarvis.security.consent import ConsentManager
from jarvis.security.gdpr import DataPurpose, ProcessingBasis
from jarvis.utils.logging import get_logger

log = get_logger(__name__)

__all__ = ["ComplianceEngine", "ComplianceViolation"]


class ComplianceViolation(Exception):
    """Raised when a processing operation violates GDPR policy."""


class ComplianceEngine:
    """Central GDPR policy enforcer. Called before every processing operation.

    Rules:
    1. Consent-based processing requires actual consent
    2. Privacy mode blocks all persistent storage except security
    3. OSINT requires explicit OSINT consent
    4. Legitimate interest bypasses consent (security monitoring, audit)
    """

    def __init__(
        self,
        consent_manager: ConsentManager | None = None,
        enabled: bool = True,
    ) -> None:
        self._consent = consent_manager
        self._enabled = enabled
        self._privacy_mode = False

    def set_privacy_mode(self, enabled: bool) -> None:
        self._privacy_mode = enabled
        log.info("privacy_mode_changed", enabled=enabled)

    @property
    def privacy_mode(self) -> bool:
        return self._privacy_mode

    def check(
        self,
        user_id: str,
        channel: str,
        legal_basis: ProcessingBasis,
        purpose: DataPurpose,
        data_types: list[str] | None = None,
    ) -> None:
        """Verify that the processing operation is GDPR-compliant.

        Raises ComplianceViolation if not allowed.
        Does nothing if engine is disabled (development mode).
        """
        if not self._enabled:
            return

        # Rule 1: Privacy mode blocks everything except security
        if self._privacy_mode and purpose != DataPurpose.SECURITY:
            raise ComplianceViolation(
                f"Privacy mode active — {purpose.value} processing blocked"
            )

        # Rule 2: Consent-based processing requires actual consent
        if legal_basis == ProcessingBasis.CONSENT:
            if self._consent and not self._consent.has_consent(user_id, channel):
                raise ComplianceViolation(
                    f"No consent for {purpose.value} on channel {channel}. "
                    f"User {user_id[:8]} must accept the privacy notice first."
                )

        # Rule 3: OSINT requires explicit OSINT consent (above and beyond data_processing)
        if purpose == DataPurpose.OSINT:
            if self._consent and not self._consent.has_consent(user_id, channel, "osint"):
                raise ComplianceViolation(
                    f"OSINT investigation requires explicit osint consent from user {user_id[:8]}"
                )

        # Rule 4: Legitimate interest is allowed without consent
        # (security monitoring, audit trails, fraud detection)
        # No check needed — this is the bypass

        log.debug(
            "compliance_check_passed",
            user=user_id[:8],
            channel=channel,
            basis=legal_basis.value,
            purpose=purpose.value,
        )
