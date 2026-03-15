# Cognithor Skills Guide

> How to create, install, and manage skills.
> For the skill file format reference, see [DEVELOPER.md](DEVELOPER.md#creating-a-skill).

## What Are Skills?

Skills are Markdown files with YAML frontmatter that teach Cognithor *how* to
handle specific types of requests. When a user message matches a skill's
trigger keywords, the skill body is injected into the Planner's context as
instructions.

Skills are **not code** — they are natural language procedures that guide the
Planner's reasoning. The Planner then uses MCP tools to execute the steps.

---

## Built-in Skills

| Skill | Category | Triggers |
|-------|----------|----------|
| `web-recherche` | research | Recherche, Internet, Web-Suche |
| `morgen-briefing` | productivity | Was steht an, Briefing, Tagesüberblick |
| `meeting-vorbereitung` | productivity | Meeting, Besprechung, vorbereiten |
| `email-triage` | communication | E-Mails, Inbox, sortieren |
| `dokument-analyse` | research | Dokument, analysieren, PDF |
| `todo-management` | productivity | Aufgabe, Todo, erledigen |
| `kontakt-recherche` | research | Kontakt, Person, Hintergrund |
| `wissens-synthese` | knowledge | Zusammenfassen, Synthese, Wissen |
| `projekt-setup` | coding | Projekt, Setup, initialisieren |
| `backup` | system | Backup, sichern |

---

## Creating a Skill

### 1. Choose a location

| Location | Purpose |
|----------|---------|
| `~/.jarvis/skills/` | Personal skills |
| `data/procedures/` | Built-in (ships with Cognithor) |

### 2. Create the skill file

```bash
mkdir -p ~/.jarvis/skills/my-skill
```

Create `~/.jarvis/skills/my-skill/skill.md`:

```markdown
---
name: my-skill
trigger_keywords: [Keyword1, Keyword2, "multi word trigger"]
tools_required: [web_search, write_file]
category: research
priority: 5
description: "What this skill does in one sentence"
enabled: true
---
# Skill Title

## When to Apply
Describe when the Planner should activate this skill.

## Steps
1. First step...
2. Second step...
3. Final step...

## Known Pitfalls
- Edge cases to watch for

## Quality Criteria
- How to evaluate success
```

### 3. Restart Cognithor

The SkillRegistry scans skill directories at startup. No registration code needed.

---

## Skill Matching

When a user sends a message, the SkillRegistry:

1. Extracts keywords from the message
2. Matches against each skill's `trigger_keywords`
   - Exact match (case-insensitive)
   - Fuzzy match (70% similarity threshold)
3. Scores by overlap count + success rate bonus
4. Injects the best match into Working Memory

The Planner then sees the skill body as part of its system prompt and follows
the instructions.

### Debugging Matches

Use the `list_skills` tool or check logs:
```
User > Zeige alle registrierten Skills
```

---

## YAML Frontmatter Reference

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | yes | — | Unique skill identifier |
| `trigger_keywords` | list | yes | — | Keywords that activate this skill |
| `tools_required` | list | no | `[]` | MCP tools the skill needs |
| `category` | string | no | `general` | Category for filtering |
| `priority` | int | no | `0` | Higher = preferred at tie |
| `description` | string | no | — | Short description |
| `enabled` | bool | no | `true` | Enable/disable |
| `model_preference` | string | no | — | Preferred LLM model |
| `agent` | string | no | — | Route to specific agent |

---

## Community Marketplace

### Browsing Skills

```
User > Suche Community-Skills zum Thema Datenanalyse
```

Or via the MCP tool:
```
search_community_skills(query="data analysis")
```

### Installing

```
User > Installiere den Community-Skill "data-analysis"
```

Or via tool:
```
install_community_skill(name="data-analysis")
```

Installed skills go to `~/.jarvis/skills/community/<name>/`.

### Security Chain

Community skills go through a 5-step validation:

1. **Syntax check** — Valid Markdown + YAML frontmatter
2. **Injection scan** — No prompt injection patterns
3. **Tool declaration** — All `tools_required` are valid MCP tools
4. **Safety check** — No dangerous patterns (file deletion, etc.)
5. **Hash verification** — SHA-256 content hash matches registry

At runtime, the **ToolEnforcer** restricts community skills to only their
declared `tools_required` — they cannot escalate to tools they didn't declare.

### Reporting Issues

```
User > Melde den Skill "suspicious-skill" als problematisch
```

Reports are tracked by the governance system and may trigger a recall.

---

## Tips for Good Skills

1. **Be specific** — "When the user asks about X" is better than "General helper"
2. **Use concrete tool names** — `web_search`, `write_file`, not "search the internet"
3. **Include failure modes** — What to do when a tool returns no results
4. **Set quality criteria** — How the Planner knows the task is complete
5. **Keep it focused** — One skill, one purpose. Don't try to handle everything
6. **Test your triggers** — Make sure keywords are distinctive enough to not
   overlap with other skills
