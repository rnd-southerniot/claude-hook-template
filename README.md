# Claude Code Project Template

A comprehensive template for supercharging Claude Code with hooks, sub-agents, custom commands, and more.

## Features

| Feature | Description |
|---------|-------------|
| **13 Lifecycle Hooks** | Control Claude's behavior at every stage |
| **4 Sub-Agents** | Builder, Validator, Meta-agent, Hello-world |
| **8 Slash Commands** | /plan, /build, /prime, and more |
| **9 Status Lines** | Real-time terminal displays |
| **8 Output Styles** | Transform response formatting |
| **Code Validators** | Auto-lint Python with Ruff and Ty |
| **TTS System** | Voice notifications (3 providers) |
| **LLM Integration** | AI-powered summaries and agent naming |

---

## Quick Start

### Prerequisites

1. **UV** (required for hooks):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. **Claude Code** CLI installed

---

## Installation

### Option 1: New Project

Create a new project with the full template:

```bash
# Run the interactive setup
~/claude-code-template/setup.sh

# When prompted, enter your new project path:
# Target directory: ~/my-new-project
```

The setup script will:
1. Create the directory structure
2. Copy all template files
3. Prompt for your name and API keys
4. Generate a configured `.env` file
5. Optionally initialize a git repository

### Option 2: Existing Project

Add Claude Code features to an existing project:

```bash
# Navigate to your project
cd ~/my-existing-project

# Run setup with current directory
~/claude-code-template/setup.sh

# When prompted:
# Target directory: .
```

If `.claude/` already exists, you'll be asked to:
- **Overwrite** - Replace existing configuration
- **Merge** - Keep existing files, only add missing ones
- **Abort** - Cancel setup

#### Manual Installation (Existing Project)

For fine-grained control, copy only what you need:

```bash
# Copy the entire .claude directory
cp -r ~/claude-code-template/.claude ~/my-project/

# Copy config files
cp ~/claude-code-template/{ruff.toml,ty.toml,.gitignore} ~/my-project/
cp ~/claude-code-template/.env.sample ~/my-project/

# Create required directories
mkdir -p ~/my-project/{logs,specs}

# Set up environment
cp ~/my-project/.env.sample ~/my-project/.env
# Edit .env with your values
```

---

## Configuration

### Environment Variables

Copy `.env.sample` to `.env` and configure:

```bash
# Required
ENGINEER_NAME=YourName          # Used in personalized messages

# Recommended (enables AI features)
ANTHROPIC_API_KEY=sk-ant-...    # LLM summaries
OPENAI_API_KEY=sk-...           # TTS + LLM fallback

# Optional TTS
ELEVENLABS_API_KEY=...          # Premium voice quality

# Optional Local LLM
OLLAMA_HOST=http://localhost:11434
```

### Feature Toggles

Edit `.claude/settings.json` to enable/disable features:

| Flag | Location | Effect |
|------|----------|--------|
| `--notify` | Notification, SubagentStop hooks | Enable TTS alerts |
| `--name-agent` | UserPromptSubmit hook | AI-generated session names |
| `--chat` | Stop hook | Generate chat transcript |
| `--log-only` | Various hooks | Log without blocking |

**Disable TTS notifications:**
```bash
# Remove --notify from settings.json
sed -i '' 's/ --notify//g' .claude/settings.json
```

**Disable agent naming:**
```bash
# Remove --name-agent from settings.json
sed -i '' 's/ --name-agent//g' .claude/settings.json
```

---

## Usage

### Starting a Session

```bash
cd ~/my-project
claude
```

### Verify Hooks Are Working

1. **Check logs directory** after running any command:
   ```bash
   ls logs/
   # Should see: user_prompt_submit.json, pre_tool_use.json, etc.
   ```

2. **Status line** should appear at terminal bottom

3. **Test a slash command:**
   ```
   /prime
   ```

### Available Slash Commands

| Command | Description |
|---------|-------------|
| `/prime` | Load project context (analyzes structure, README) |
| `/plan` | Create implementation plan (saves to specs/) |
| `/plan_w_team` | Team-based planning with builder/validator agents |
| `/build` | Execute a plan from specs/ |
| `/cook` | Run parallel sub-agent tasks |
| `/git_status` | Comprehensive git status |
| `/all_tools` | List all available tools |
| `/update_status_line` | Add custom metadata to status |

### Using Sub-Agents

Sub-agents are automatically available. Ask Claude to use them:

```
"Use the meta-agent to create a new agent for running pytest"
"Have the validator check if the authentication is implemented correctly"
```

### Output Styles

Change response formatting:

```
/output-style genui      # Beautiful HTML output
/output-style ultra-concise  # Minimal responses
/output-style table-based    # Structured tables
```

---

## Project Structure

```
your-project/
├── .claude/
│   ├── settings.json       # Hook configuration
│   ├── hooks/              # 13 lifecycle hooks
│   │   ├── utils/tts/      # TTS providers
│   │   ├── utils/llm/      # LLM providers
│   │   └── validators/     # Code quality checks
│   ├── agents/             # Sub-agent definitions
│   │   └── team/           # Builder/validator pair
│   ├── commands/           # Slash commands
│   ├── output-styles/      # Response formats
│   ├── status_lines/       # Terminal status scripts
│   └── data/sessions/      # Session tracking
├── logs/                   # Hook logs (gitignored)
├── specs/                  # Implementation plans
├── .env                    # API keys (gitignored)
├── .env.sample             # Template for .env
├── ruff.toml               # Python linter config
├── ty.toml                 # Type checker config
└── CLAUDE.md               # Project instructions
```

---

## Customization

### Customize CLAUDE.md

After setup, edit `CLAUDE.md` to describe your project:

```markdown
## Project Overview

<!-- Replace this section -->
[YOUR PROJECT DESCRIPTION]

**Tech Stack:** [YOUR TECH STACK]
```

### Add Custom Agents

Create new agents in `.claude/agents/`:

```yaml
---
name: my-custom-agent
description: When to use this agent (important!)
tools: Read, Grep, Glob
model: haiku
---

# Purpose
You are a specialized agent for [task].

## Instructions
1. Do this
2. Then this

## Report Format
Return results as [format].
```

Or use the meta-agent:
```
"Create a sub-agent that validates JSON schemas and reports errors"
```

### Add Custom Commands

Create new commands in `.claude/commands/`:

```markdown
---
description: My custom workflow
---

# Instructions

Do the following:
1. Step one
2. Step two
```

### Change Status Line

Edit `.claude/settings.json`:

```json
"statusLine": {
  "command": "uv run $CLAUDE_PROJECT_DIR/.claude/status_lines/status_line_v9.py"
}
```

Available versions: v1 (basic) through v9 (minimal powerline)

---

## Troubleshooting

### Hooks Not Running

1. **Check UV is installed:**
   ```bash
   uv --version
   ```

2. **Verify settings.json syntax:**
   ```bash
   cat .claude/settings.json | jq .
   ```

3. **Check hook permissions:**
   ```bash
   ls -la .claude/hooks/*.py
   ```

### TTS Not Working

1. Verify API keys in `.env`
2. Check for `--notify` flag in settings.json
3. Falls back to pyttsx3 if no API keys

### Status Line Not Showing

1. Ensure `statusLine` is configured in settings.json
2. Check script exists: `ls .claude/status_lines/`
3. Test script directly: `uv run .claude/status_lines/status_line_v6.py`

### Logs Not Appearing

1. Create logs directory: `mkdir -p logs`
2. Check write permissions
3. Verify hooks are configured in settings.json

---

## Updating the Template

To update an existing project with new template features:

```bash
# Re-run setup with merge option
~/claude-code-template/setup.sh
# Enter your project path
# Choose [M]erge when prompted
```

This preserves your customizations while adding new files.

---

## Security Notes

- `.env` files are blocked from Claude's access (by pre_tool_use hook)
- Dangerous commands (rm -rf, etc.) are blocked
- Credentials are gitignored by default
- Review `.claude/hooks/pre_tool_use.py` for blocked patterns

---

## License

MIT - Use freely in your projects.
