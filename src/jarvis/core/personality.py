"""Personality Engine: Adds warmth, greetings, and empathy to Jarvis responses.

Provides configurable personality directives that are injected into the
SYSTEM_PROMPT, making Jarvis feel less robotic and more human.
"""

from __future__ import annotations

from datetime import datetime
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from jarvis.config import PersonalityConfig


class PersonalityEngine:
    """Generates personality-enriched prompt fragments.

    Configurable via PersonalityConfig (warmth, humor, follow-up questions, etc.).
    """

    def __init__(self, config: PersonalityConfig | None = None) -> None:
        if config is None:
            from jarvis.config import PersonalityConfig
            config = PersonalityConfig()
        self._config = config

    @property
    def config(self) -> PersonalityConfig:
        return self._config

    def get_greeting_fragment(self) -> str:
        """Returns a time-of-day greeting fragment (German).

        Returns empty string if greetings are disabled.
        """
        if not self._config.greeting_enabled:
            return ""

        hour = datetime.now().hour

        if 5 <= hour < 12:
            return "Guten Morgen! "
        elif 12 <= hour < 17:
            return "Guten Nachmittag! "
        elif 17 <= hour < 22:
            return "Guten Abend! "
        else:
            return "Hallo Nachtschwärmer! "

    def get_personality_directives(self) -> str:
        """Returns personality directives for the SYSTEM_PROMPT.

        The directives are scaled by the warmth and humor config values.
        """
        directives: list[str] = []

        # Warmth directives (0.0 = neutral, 1.0 = very warm)
        if self._config.warmth >= 0.3:
            directives.append(
                "- Sei freundlich und zugewandt in deiner Kommunikation."
            )
        if self._config.warmth >= 0.6:
            directives.append(
                "- Zeige Empathie und Verständnis für die Situation des Users."
            )
        if self._config.warmth >= 0.8:
            directives.append(
                "- Formuliere Antworten wertschätzend. Erkenne Fortschritte und gute Ideen an."
            )

        # Humor directives (0.0 = serious, 1.0 = playful)
        if self._config.humor >= 0.3:
            directives.append(
                "- Ein gelegentlicher lockerer Kommentar ist erlaubt, aber übertreibe nicht."
            )
        if self._config.humor >= 0.6:
            directives.append(
                "- Du darfst ruhig mal eine witzige Bemerkung machen, wenn es passt."
            )

        # Success celebration
        if self._config.success_celebration:
            directives.append(
                "- Wenn eine Aufgabe erfolgreich abgeschlossen wurde, bestätige das positiv "
                "(z.B. \"Perfekt, hat geklappt!\", \"Erledigt!\", \"Alles fertig!\")."
            )

        # Follow-up questions
        if self._config.follow_up_questions:
            directives.append(
                "- Wenn es sinnvoll ist, stelle am Ende eine kurze Nachfrage, "
                "ob der User noch etwas braucht oder ob dir weitere Details helfen würden."
            )

        return "\n".join(directives)

    def build_personality_block(self) -> str:
        """Builds the complete personality block for SYSTEM_PROMPT injection.

        Returns empty string if all personality features are disabled.
        """
        directives = self.get_personality_directives()
        if not directives:
            return ""

        return f"\n## Persönlichkeit\n{directives}\n"
