/**
 * Lightweight frontend i18n for Cognithor Control Center.
 *
 * Usage:
 *   import { t, setLocale, getLocale } from "../utils/i18n";
 *   t("chat.placeholder")  // → "Type a message..."
 *   setLocale("de")        // switches all strings
 *
 * The locale is kept in sync with the backend config.language setting.
 * Components re-render via a simple event emitter pattern.
 */

// ── Translation packs ────────────────────────────────────────────────────

const packs = {
  en: {
    // Sidebar navigation
    "nav.chat": "Chat",
    "nav.general": "General",
    "nav.language": "Language",
    "nav.providers": "LLM Providers",
    "nav.models": "Models",
    "nav.planner": "PGE Trinity",
    "nav.executor": "Executor",
    "nav.memory": "Memory",
    "nav.channels": "Channels",
    "nav.security": "Security",
    "nav.web": "Web Tools",
    "nav.mcp": "Integrations",
    "nav.cron": "Cron & Heartbeat",
    "nav.database": "Database",
    "nav.logging": "Logging",
    "nav.prompts": "Prompts & Policies",
    "nav.agents": "Agents",
    "nav.bindings": "Bindings",
    "nav.workflows": "Workflows",
    "nav.knowledge_graph": "Knowledge Graph",
    "nav.system": "System",

    // Chat
    "chat.title": "Chat with Jarvis",
    "chat.placeholder": "Type a message...",
    "chat.empty": "Hello! Ask me anything...",
    "chat.send": "Send (Enter)",
    "chat.attach": "Attach file",
    "chat.voice": "Voice",
    "chat.voice_on": "Voice On",
    "chat.clear": "Clear",
    "chat.canvas": "Canvas",
    "chat.canvas_active": "Canvas active",
    "chat.canvas_close": "Close canvas",
    "chat.canvas_title": "Jarvis Canvas",
    "chat.stop_recording": "Stop recording",
    "chat.voice_message": "Voice message",

    // Voice
    "voice.wake": 'Say "Jarvis"...',
    "voice.listening": 'Listening... (say "Jarvis stop" to end)',
    "voice.processing": "Processing...",
    "voice.speaking": "Speaking...",

    // Language settings
    "lang.title": "Language Settings",
    "lang.subtitle": "System language, locale selection, and prompt translation",
    "lang.active": "Active Language",
    "lang.system": "System language",
    "lang.system_desc": "Controls UI messages, error texts, and status outputs. Changing this triggers a prompt translation offer below.",
    "lang.packs_info": "Installed language packs: {packs} · Prompt presets available for: {presets}",
    "lang.translate_title": "System Prompt Translation",
    "lang.translate_desc": "You changed the language to {lang}.",
    "lang.translate_question": "Would you like to translate the system prompts?",
    "lang.method_preset": "Use curated preset (instant, recommended)",
    "lang.method_ollama": "Translate via Ollama (slower, custom)",
    "lang.translate_btn": "Translate Prompts",
    "lang.translating": "Translating...",
    "lang.skip": "Skip \u2014 keep current prompts",
    "lang.preview_title": "Translation Preview",
    "lang.preview_desc": "Review the translated prompts below. Click Accept & Apply to write them, or Discard to keep the originals.",
    "lang.accept": "Accept & Apply",
    "lang.discard": "Discard",
    "lang.planner_prompt": "Planner System-Prompt",
    "lang.replan_prompt": "Replan-Prompt",
    "lang.escalation_prompt": "Escalation-Prompt",

    // Header / Power
    "header.power_on": "Power On",
    "header.power_off": "Power Off",
    "header.version": "Control Center v{version}",
    "header.backend_stopped": "Backend not started. Click \"Power On\" above to launch Cognithor.",
    "header.backend_error": "Backend unreachable \u2014 is Cognithor running?",

    // Prompts & Policies page
    "prompts.title": "Prompts & Policies",
    "prompts.subtitle": "View and customize system prompts, gatekeeper policies, CORE.md, HEARTBEAT.md",
    "prompts.core_title": "CORE.md \u2014 System Personality",
    "prompts.core_desc": "Core Memory (Markdown)",
    "prompts.core_hint": "Personality, rules and preferences of Jarvis",
    "prompts.planner": "Planner System-Prompt",
    "prompts.replan": "Replan-Prompt",
    "prompts.escalation": "Escalation-Prompt",
    "prompts.gatekeeper": "Gatekeeper-Policies (YAML)",
    "prompts.heartbeat": "HEARTBEAT.md \u2014 Heartbeat Checklist",
    "prompts.reset": "Reset",

    // Common
    "common.save": "Save",
    "common.cancel": "Cancel",
    "common.loading": "Loading...",
    "common.error": "Error",
    "common.search": "Search...",
  },

  de: {
    "nav.chat": "Chat",
    "nav.general": "Allgemein",
    "nav.language": "Sprache",
    "nav.providers": "LLM-Anbieter",
    "nav.models": "Modelle",
    "nav.planner": "PGE Trinity",
    "nav.executor": "Executor",
    "nav.memory": "Speicher",
    "nav.channels": "Kan\u00e4le",
    "nav.security": "Sicherheit",
    "nav.web": "Web-Tools",
    "nav.mcp": "Integrationen",
    "nav.cron": "Cron & Heartbeat",
    "nav.database": "Datenbank",
    "nav.logging": "Logging",
    "nav.prompts": "Prompts & Richtlinien",
    "nav.agents": "Agenten",
    "nav.bindings": "Bindings",
    "nav.workflows": "Workflows",
    "nav.knowledge_graph": "Wissensgraph",
    "nav.system": "System",

    "chat.title": "Chat mit Jarvis",
    "chat.placeholder": "Nachricht eingeben...",
    "chat.empty": "Hallo! Frag mich etwas...",
    "chat.send": "Senden (Enter)",
    "chat.attach": "Datei anh\u00e4ngen",
    "chat.voice": "Sprache",
    "chat.voice_on": "Sprache An",
    "chat.clear": "Leeren",
    "chat.canvas": "Canvas",
    "chat.canvas_active": "Canvas aktiv",
    "chat.canvas_close": "Canvas schlie\u00dfen",
    "chat.canvas_title": "Jarvis Canvas",
    "chat.stop_recording": "Aufnahme stoppen",
    "chat.voice_message": "Sprachnachricht",

    "voice.wake": "Sag \"Jarvis\"...",
    "voice.listening": "H\u00f6re zu... (sag \"Jarvis stop\" zum Beenden)",
    "voice.processing": "Verarbeite...",
    "voice.speaking": "Spreche...",

    "lang.title": "Spracheinstellungen",
    "lang.subtitle": "Systemsprache, Sprachpaket-Auswahl und Prompt-\u00dcbersetzung",
    "lang.active": "Aktive Sprache",
    "lang.system": "Systemsprache",
    "lang.system_desc": "Steuert UI-Nachrichten, Fehlertexte und Statusausgaben. Eine \u00c4nderung l\u00f6st ein \u00dcbersetzungsangebot f\u00fcr die Prompts aus.",
    "lang.packs_info": "Installierte Sprachpakete: {packs} \u00b7 Prompt-Presets verf\u00fcgbar f\u00fcr: {presets}",
    "lang.translate_title": "System-Prompt-\u00dcbersetzung",
    "lang.translate_desc": "Du hast die Sprache auf {lang} ge\u00e4ndert.",
    "lang.translate_question": "M\u00f6chtest du die System-Prompts \u00fcbersetzen?",
    "lang.method_preset": "Kuratiertes Preset verwenden (sofort, empfohlen)",
    "lang.method_ollama": "Via Ollama \u00fcbersetzen (langsamer, individuell)",
    "lang.translate_btn": "Prompts \u00fcbersetzen",
    "lang.translating": "\u00dcbersetze...",
    "lang.skip": "\u00dcberspringen \u2014 aktuelle Prompts behalten",
    "lang.preview_title": "\u00dcbersetzungsvorschau",
    "lang.preview_desc": "Pr\u00fcfe die \u00fcbersetzten Prompts. Klicke \u00dcbernehmen zum Speichern, oder Verwerfen f\u00fcr die Originale.",
    "lang.accept": "\u00dcbernehmen",
    "lang.discard": "Verwerfen",
    "lang.planner_prompt": "Planner System-Prompt",
    "lang.replan_prompt": "Replan-Prompt",
    "lang.escalation_prompt": "Eskalations-Prompt",

    "header.power_on": "Einschalten",
    "header.power_off": "Ausschalten",
    "header.version": "Control Center v{version}",
    "header.backend_stopped": "Backend nicht gestartet. Klicke oben auf \"Einschalten\" um Cognithor zu starten.",
    "header.backend_error": "Backend nicht erreichbar \u2014 l\u00e4uft Cognithor?",

    "prompts.title": "Prompts & Richtlinien",
    "prompts.subtitle": "System-Prompts, Gatekeeper-Richtlinien, CORE.md und HEARTBEAT.md anzeigen und bearbeiten",
    "prompts.core_title": "CORE.md \u2014 System-Pers\u00f6nlichkeit",
    "prompts.core_desc": "Kern-Ged\u00e4chtnis (Markdown)",
    "prompts.core_hint": "Pers\u00f6nlichkeit, Regeln und Pr\u00e4ferenzen von Jarvis",
    "prompts.planner": "Planner System-Prompt",
    "prompts.replan": "Replan-Prompt",
    "prompts.escalation": "Eskalations-Prompt",
    "prompts.gatekeeper": "Gatekeeper-Richtlinien (YAML)",
    "prompts.heartbeat": "HEARTBEAT.md \u2014 Heartbeat-Checkliste",
    "prompts.reset": "Zur\u00fccksetzen",

    "common.save": "Speichern",
    "common.cancel": "Abbrechen",
    "common.loading": "Laden...",
    "common.error": "Fehler",
    "common.search": "Suchen...",
  },

  zh: {
    "nav.chat": "\u5bf9\u8bdd",
    "nav.general": "\u901a\u7528\u8bbe\u7f6e",
    "nav.language": "\u8bed\u8a00",
    "nav.providers": "LLM \u670d\u52a1\u5546",
    "nav.models": "\u6a21\u578b",
    "nav.planner": "PGE Trinity",
    "nav.executor": "\u6267\u884c\u5668",
    "nav.memory": "\u8bb0\u5fc6",
    "nav.channels": "\u901a\u9053",
    "nav.security": "\u5b89\u5168",
    "nav.web": "Web \u5de5\u5177",
    "nav.mcp": "\u96c6\u6210",
    "nav.cron": "\u5b9a\u65f6 & \u5fc3\u8df3",
    "nav.database": "\u6570\u636e\u5e93",
    "nav.logging": "\u65e5\u5fd7",
    "nav.prompts": "\u63d0\u793a\u8bcd & \u7b56\u7565",
    "nav.agents": "\u667a\u80fd\u4f53",
    "nav.bindings": "\u7ed1\u5b9a",
    "nav.workflows": "\u5de5\u4f5c\u6d41",
    "nav.knowledge_graph": "\u77e5\u8bc6\u56fe\u8c31",
    "nav.system": "\u7cfb\u7edf",

    "chat.title": "\u4e0e Jarvis \u5bf9\u8bdd",
    "chat.placeholder": "\u8f93\u5165\u6d88\u606f...",
    "chat.empty": "\u4f60\u597d\uff01\u8bf7\u95ee\u6211\u4efb\u4f55\u95ee\u9898...",
    "chat.send": "\u53d1\u9001 (Enter)",
    "chat.attach": "\u6dfb\u52a0\u9644\u4ef6",
    "chat.voice": "\u8bed\u97f3",
    "chat.voice_on": "\u8bed\u97f3\u5f00\u542f",
    "chat.clear": "\u6e05\u9664",
    "chat.canvas": "\u753b\u5e03",
    "chat.canvas_active": "\u753b\u5e03\u5df2\u6fc0\u6d3b",
    "chat.canvas_close": "\u5173\u95ed\u753b\u5e03",
    "chat.canvas_title": "Jarvis \u753b\u5e03",
    "chat.stop_recording": "\u505c\u6b62\u5f55\u97f3",
    "chat.voice_message": "\u8bed\u97f3\u6d88\u606f",

    "voice.wake": "\u8bf4 \"Jarvis\"...",
    "voice.listening": "\u8046\u542c\u4e2d...\uff08\u8bf4 \"Jarvis stop\" \u7ed3\u675f\uff09",
    "voice.processing": "\u5904\u7406\u4e2d...",
    "voice.speaking": "\u64ad\u653e\u4e2d...",

    "lang.title": "\u8bed\u8a00\u8bbe\u7f6e",
    "lang.subtitle": "\u7cfb\u7edf\u8bed\u8a00\u3001\u8bed\u8a00\u5305\u9009\u62e9\u548c\u63d0\u793a\u8bcd\u7ffb\u8bd1",
    "lang.active": "\u5f53\u524d\u8bed\u8a00",
    "lang.system": "\u7cfb\u7edf\u8bed\u8a00",
    "lang.system_desc": "\u63a7\u5236\u754c\u9762\u6d88\u606f\u3001\u9519\u8bef\u6587\u672c\u548c\u72b6\u6001\u8f93\u51fa\u3002\u66f4\u6539\u540e\u5c06\u63d0\u4f9b\u63d0\u793a\u8bcd\u7ffb\u8bd1\u9009\u9879\u3002",
    "lang.translate_btn": "\u7ffb\u8bd1\u63d0\u793a\u8bcd",
    "lang.accept": "\u5e94\u7528",
    "lang.discard": "\u653e\u5f03",

    "header.power_on": "\u542f\u52a8",
    "header.power_off": "\u5173\u95ed",
    "header.version": "\u63a7\u5236\u4e2d\u5fc3 v{version}",

    "prompts.title": "\u63d0\u793a\u8bcd & \u7b56\u7565",
    "prompts.reset": "\u91cd\u7f6e",

    "common.save": "\u4fdd\u5b58",
    "common.cancel": "\u53d6\u6d88",
    "common.loading": "\u52a0\u8f7d\u4e2d...",
    "common.error": "\u9519\u8bef",
    "common.search": "\u641c\u7d22...",
  },
};

// ── State ────────────────────────────────────────────────────────────────

let _locale = "en";
const _listeners = new Set();

/**
 * Translate a key, with optional {placeholder} interpolation.
 * Falls back to English, then to the raw key.
 */
export function t(key, params) {
  const pack = packs[_locale] || packs.en;
  let text = pack[key] || packs.en[key] || key;
  if (params) {
    for (const [k, v] of Object.entries(params)) {
      text = text.replace(`{${k}}`, v);
    }
  }
  return text;
}

/** Get the current locale. */
export function getLocale() {
  return _locale;
}

/** Set locale and notify all listeners. */
export function setLocale(locale) {
  if (!packs[locale] && locale !== _locale) {
    // Unknown locale — fall back to en
    locale = "en";
  }
  if (locale === _locale) return;
  _locale = locale;
  for (const fn of _listeners) {
    try { fn(locale); } catch { /* ignore */ }
  }
}

/** Subscribe to locale changes. Returns unsubscribe function. */
export function onLocaleChange(fn) {
  _listeners.add(fn);
  return () => _listeners.delete(fn);
}
