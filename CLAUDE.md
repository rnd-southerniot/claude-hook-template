# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

<!-- CUSTOMIZE: Replace this section with your project description -->
[YOUR PROJECT DESCRIPTION]

**Tech Stack:** [YOUR TECH STACK]

**Key Directories:**
- `src/` - [Description]
- `tests/` - [Description]

---

## Claude Code Features

This project uses the Claude Code Hooks template for enhanced development workflows.

### Quick Start

1. Run `./setup.sh` to configure the template for your project
2. Copy `.env.sample` to `.env` and add your API keys
3. Start Claude Code: `claude`

---

## Architecture: UV Single-File Scripts

All hooks use **UV single-file scripts** with inline dependency declarations. Each hook is a standalone Python script in `.claude/hooks/` that:

- Declares dependencies in PEP 723 format (shebang: `#!/usr/bin/env -S uv run --script`)
- Runs without virtual environment management
- Has dependencies like `python-dotenv`, `anthropic`, `openai`, etc. embedded in script headers
- Executes via `uv run` automatically

**Example structure:**
```python
#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "python-dotenv",
# ]
# ///
```

## Environment Configuration

Copy `.env.sample` to `.env` and configure:

```bash
ANTHROPIC_API_KEY=      # For LLM-powered completions
OPENAI_API_KEY=         # For TTS and LLM fallback
ELEVENLABS_API_KEY=     # For premium TTS
ENGINEER_NAME=          # Your name (used in personalized messages)
OLLAMA_HOST=            # Local LLM endpoint (optional)
```

## Hook System

### Hook Configuration Location

All hooks are configured in `.claude/settings.json` with paths using `$CLAUDE_PROJECT_DIR` variable:

```json
"hooks": {
  "UserPromptSubmit": [
    {
      "hooks": [{
        "type": "command",
        "command": "uv run $CLAUDE_PROJECT_DIR/.claude/hooks/user_prompt_submit.py --log-only"
      }]
    }
  ]
}
```

### Hook Flow Control

Hooks use exit codes to control behavior:

| Exit Code | Behavior | When to Use |
|-----------|----------|-------------|
| 0 | Success | Hook completed successfully |
| 2 | Block + Feedback | Block operation and send stderr to Claude |
| Other | Non-blocking Error | Show error to user but continue |

### Blocking Hooks

Only these hooks can block operations:
- **UserPromptSubmit** - Block prompts before Claude sees them
- **PreToolUse** - Block tool execution before it happens
- **Stop** - Prevent Claude from stopping (force continuation)
- **SubagentStop** - Prevent subagent from stopping

### JSON Decision Control

Hooks can return structured JSON for advanced control:

```json
{
  "decision": "approve" | "block",
  "reason": "Explanation shown to Claude",
  "continue": true | false,
  "suppressOutput": true | false
}
```

## Key Hook Scripts

| Hook | File | Purpose | Key Flags |
|------|------|---------|-----------|
| UserPromptSubmit | `user_prompt_submit.py` | Log prompts, name agents, store session data | `--log-only`, `--store-last-prompt`, `--name-agent` |
| PreToolUse | `pre_tool_use.py` | Block dangerous commands (rm -rf, .env access) | None |
| PostToolUse | `post_tool_use.py` | Log tool completions, convert transcripts | `--chat` (generates chat.json) |
| Stop | `stop.py` | AI-generated completion messages with TTS | `--chat`, `--notify` |
| Notification | `notification.py` | TTS alerts for user input needed | `--notify` |
| SubagentStop | `subagent_stop.py` | Announce subagent completion | `--notify` |

## Logging System

All hooks log to `logs/` directory as JSON arrays:

```
logs/
├── user_prompt_submit.json    # All prompts submitted
├── pre_tool_use.json          # All tool calls (with blocking info)
├── post_tool_use.json         # All tool completions
├── stop.json                  # All stop events
├── session_start.json         # Session initialization
├── session_end.json           # Session cleanup
├── chat.json                  # Readable transcript (latest session only)
└── ...
```

**Warning:** `chat.json` is overwritten each session - other logs append.

## Sub-Agent System

### Agent Storage Hierarchy

```
.claude/agents/              # Project-specific (higher priority)
├── team/                    # Build/validate workflow agents
│   ├── builder.md          # Implementation agent (all tools)
│   └── validator.md        # Read-only validation agent
├── meta-agent.md           # Agent that creates agents
└── hello-world-agent.md    # Example template
```

**Global agents:** `~/.claude/agents/` (lower priority)

### Agent File Structure

```yaml
---
name: agent-name
description: When primary agent should use this (critical!)
tools: Tool1, Tool2  # Optional - omit to inherit all
color: Cyan
model: opus  # haiku | sonnet | opus
---

# Purpose
You are a [role]. [System prompt instructions]

## Instructions
[Step-by-step what agent should do]

## Report Format
[How to communicate results back to primary agent]
```

### Critical Concepts

1. **System Prompts, Not User Prompts** - Agent files are system prompts that configure behavior
2. **Information Flow** - User → Primary Agent → Sub-Agent → Primary Agent → User
3. **No Direct Communication** - Sub-agents never talk directly to users
4. **Fresh Context** - Sub-agents start with no conversation history
5. **Description Field** - Tells primary agent WHEN to delegate

### The Meta-Agent

`.claude/agents/meta-agent.md` generates new sub-agents from descriptions:

```bash
# Just describe what you want
"Create a sub-agent that runs Python tests and reports failures"

# Meta-agent automatically:
# - Creates properly formatted agent file
# - Determines minimal tools needed
# - Follows system prompt best practices
# - Uses latest Claude Code docs
```

## Custom Commands (Slash Commands)

Commands in `.claude/commands/` extend Claude with specialized workflows:

| Command | Purpose | Key Features |
|---------|---------|--------------|
| `/plan` | Create implementation plans | Saves to specs/ directory |
| `/plan_w_team` | Team-based planning with validation | Uses builder/validator agents, self-validating hooks |
| `/build` | Execute plan from specs/ | Reads plan and implements |
| `/prime` | Load project context | Analyzes structure and README |
| `/update_status_line` | Update status metadata | Adds custom key-value pairs to session |

### Self-Validating Commands

`/plan_w_team` demonstrates **self-validating commands** with embedded hooks in YAML frontmatter:

```yaml
hooks:
  stop:
    - command: "uv run $CLAUDE_PROJECT_DIR/.claude/hooks/validators/validate_new_file.py specs/*.md"
    - command: "uv run $CLAUDE_PROJECT_DIR/.claude/hooks/validators/validate_file_contains.py"
```

After command executes, validators ensure output meets criteria. If validation fails (exit code 2), Claude receives feedback and continues working.

## Team-Based Validation Pattern

The builder/validator agent pair demonstrates quality assurance through increased compute:

**Builder Agent** (`.claude/agents/team/builder.md`):
- Has all tools (Read, Write, Edit, Bash, etc.)
- Implements features and fixes
- Auto-validated by Ruff and Ty on Python files

**Validator Agent** (`.claude/agents/team/validator.md`):
- Read-only tools (no Write/Edit)
- Verifies builder's work
- Checks acceptance criteria

**Workflow:**
1. `/plan_w_team` creates orchestrated task list
2. Builder agents implement features
3. Validator agents verify completion
4. Task system coordinates dependencies

## Code Quality Validators

PostToolUse hooks in `.claude/hooks/validators/`:

| Validator | Trigger | Config File | Action |
|-----------|---------|-------------|--------|
| `ruff_validator.py` | Write/Edit on .py files | `ruff.toml` | Blocks on lint errors (exit 2) |
| `ty_validator.py` | Write/Edit on .py files | `ty.toml` | Blocks on type errors (exit 2) |

## Status Lines

Status lines provide real-time terminal displays. Configure in `.claude/settings.json`:

```json
"statusLine": {
  "type": "command",
  "command": "uv run $CLAUDE_PROJECT_DIR/.claude/status_lines/status_line_v6.py"
}
```

**Available versions:**
- `status_line.py` (v1) - Basic git/directory/model
- `status_line_v2.py` - Smart prompts with color coding
- `status_line_v3.py` - Agent sessions with history
- `status_line_v4.py` - Extended metadata support
- `status_line_v5.py` - Cost tracking with line changes
- `status_line_v6.py` - Context window usage bar
- `status_line_v7.py` - Session duration timer
- `status_line_v8.py` - Token usage with cache stats
- `status_line_v9.py` - Minimal powerline style

## Output Styles

Transform Claude's response formatting via `.claude/output-styles/`:

| Style | Use Case |
|-------|----------|
| `genui.md` | Beautiful HTML with embedded styling (browser preview) |
| `table-based.md` | Structured data in markdown tables |
| `yaml-structured.md` | Configuration-style responses |
| `bullet-points.md` | Clean action items and docs |
| `ultra-concise.md` | Minimal words for experienced devs |

**Usage:** `/output-style genui`

## Session Management

Sessions are tracked in `.claude/data/sessions/<session_id>.json`:

```json
{
  "session_id": "unique-id",
  "prompts": ["prompt1", "prompt2"],
  "agent_name": "Phoenix",  // Auto-generated via LLM
  "extras": {              // Custom metadata (v4+ status lines)
    "project": "myapp",
    "status": "debugging"
  }
}
```

## TTS System

Intelligent text-to-speech in `.claude/hooks/utils/tts/`:

**Provider Priority:**
1. ElevenLabs (premium, requires API key)
2. OpenAI (good quality, requires API key)
3. pyttsx3 (local fallback, no API key)

**Queue System:** `tts_queue.py` prevents overlapping audio playback.

## LLM System

AI-powered features in `.claude/hooks/utils/llm/`:

**Task Summarizer** (`task_summarizer.py`):
- Generates completion messages for Stop hook
- Priority: OpenAI → Anthropic → Ollama → Random messages

**Agent Naming:**
- Generates unique agent names per session
- Priority: Ollama (local) → Anthropic → OpenAI → Fallback names
- Enabled via `--name-agent` flag in `user_prompt_submit.py`

## Common Development Tasks

### Testing Hooks

```bash
# Trigger specific hooks by using Claude Code
# All hooks log to logs/ directory

# Test UserPromptSubmit
claude "test prompt"

# Check logs
cat logs/user_prompt_submit.json | jq '.'

# Test PreToolUse with dangerous command (will be blocked)
claude "run rm -rf /"
```

### Modifying Hook Behavior

1. Edit hook script in `.claude/hooks/`
2. Modify flags in `.claude/settings.json`
3. No restart needed - changes take effect immediately

### Creating New Sub-Agents

```bash
# Use meta-agent
claude "Create a sub-agent that validates JSON schemas"

# Or manually create in .claude/agents/
# Follow the agent file structure above
```

### Adding Custom Status Line

1. Create new script in `.claude/status_lines/`
2. Update `.claude/settings.json` statusLine.command
3. Read session data from `.claude/data/sessions/<session_id>.json`

## Path Variables

Always use `$CLAUDE_PROJECT_DIR` in settings.json for reliable path resolution:

```json
"command": "uv run $CLAUDE_PROJECT_DIR/.claude/hooks/my_hook.py"
```

This ensures hooks work correctly regardless of current working directory.

## Important Notes

- UV must be installed: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- Hook timeout: 60 seconds per execution
- All hooks run in parallel when multiple match
- Hooks inherit Claude Code's environment variables
- Status lines update on message changes (300ms throttle)
