#!/bin/bash
#
# Claude Code Template Setup Script
# Copies template files to a new project directory and configures .env
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Get the directory where this script lives (the template)
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         Claude Code Project Template Setup                     ║"
echo "║                                                                 ║"
echo "║  This script will copy the Claude Code hooks template to       ║"
echo "║  your project directory and configure your environment.        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check for UV
if ! command -v uv &> /dev/null; then
    echo -e "${YELLOW}Warning: UV is not installed. Hooks require UV to run.${NC}"
    echo -e "Install with: ${CYAN}curl -LsSf https://astral.sh/uv/install.sh | sh${NC}"
    echo ""
fi

# Step 1: Get target directory
echo -e "${BOLD}Step 1: Target Directory${NC}"
echo -e "Where do you want to set up the Claude Code template?"
echo -e "(Enter '.' for current directory, or provide a path)"
read -p "Target directory: " TARGET_DIR

# Expand ~ and make absolute
TARGET_DIR="${TARGET_DIR/#\~/$HOME}"
if [[ "$TARGET_DIR" == "." ]]; then
    TARGET_DIR="$(pwd)"
elif [[ ! "$TARGET_DIR" = /* ]]; then
    TARGET_DIR="$(pwd)/$TARGET_DIR"
fi

# Create directory if it doesn't exist
if [[ ! -d "$TARGET_DIR" ]]; then
    echo -e "${YELLOW}Directory doesn't exist. Create it? [Y/n]${NC}"
    read -p "" CREATE_DIR
    if [[ "$CREATE_DIR" =~ ^[Nn]$ ]]; then
        echo -e "${RED}Aborted.${NC}"
        exit 1
    fi
    mkdir -p "$TARGET_DIR"
    echo -e "${GREEN}Created $TARGET_DIR${NC}"
fi

# Check if .claude already exists
if [[ -d "$TARGET_DIR/.claude" ]]; then
    echo -e "${YELLOW}Warning: $TARGET_DIR/.claude already exists.${NC}"
    echo -e "Options:"
    echo -e "  ${CYAN}[O]verwrite${NC} - Replace existing .claude directory"
    echo -e "  ${CYAN}[M]erge${NC}     - Copy only missing files (preserves existing)"
    echo -e "  ${CYAN}[A]bort${NC}     - Cancel setup"
    read -p "Choice [O/M/A]: " EXISTING_CHOICE
    case "$EXISTING_CHOICE" in
        [Oo]*)
            echo -e "${YELLOW}Removing existing .claude directory...${NC}"
            rm -rf "$TARGET_DIR/.claude"
            ;;
        [Mm]*)
            echo -e "${CYAN}Will merge (skip existing files)...${NC}"
            MERGE_MODE=true
            ;;
        *)
            echo -e "${RED}Aborted.${NC}"
            exit 1
            ;;
    esac
fi

echo ""

# Step 2: Copy template files
echo -e "${BOLD}Step 2: Copying Template Files${NC}"

copy_file() {
    local src="$1"
    local dst="$2"

    if [[ "$MERGE_MODE" == "true" && -f "$dst" ]]; then
        echo -e "  ${YELLOW}Skip${NC} $(basename "$dst") (exists)"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo -e "  ${GREEN}Copy${NC} $(basename "$dst")"
}

copy_dir() {
    local src="$1"
    local dst="$2"

    if [[ ! -d "$src" ]]; then
        return
    fi

    mkdir -p "$dst"
    for file in "$src"/*; do
        if [[ -f "$file" ]]; then
            copy_file "$file" "$dst/$(basename "$file")"
        elif [[ -d "$file" ]]; then
            copy_dir "$file" "$dst/$(basename "$file")"
        fi
    done
}

# Copy .claude directory structure
echo -e "${CYAN}Copying .claude/ directory...${NC}"
copy_dir "$TEMPLATE_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"
copy_dir "$TEMPLATE_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"
copy_dir "$TEMPLATE_DIR/.claude/commands" "$TARGET_DIR/.claude/commands"
copy_dir "$TEMPLATE_DIR/.claude/output-styles" "$TARGET_DIR/.claude/output-styles"
copy_dir "$TEMPLATE_DIR/.claude/status_lines" "$TARGET_DIR/.claude/status_lines"
mkdir -p "$TARGET_DIR/.claude/data/sessions"
copy_file "$TEMPLATE_DIR/.claude/settings.json" "$TARGET_DIR/.claude/settings.json"

# Copy root files
echo -e "${CYAN}Copying root configuration files...${NC}"
copy_file "$TEMPLATE_DIR/ruff.toml" "$TARGET_DIR/ruff.toml"
copy_file "$TEMPLATE_DIR/ty.toml" "$TARGET_DIR/ty.toml"
copy_file "$TEMPLATE_DIR/.gitignore" "$TARGET_DIR/.gitignore"
copy_file "$TEMPLATE_DIR/.env.sample" "$TARGET_DIR/.env.sample"
copy_file "$TEMPLATE_DIR/.mcp.json.sample" "$TARGET_DIR/.mcp.json.sample"

# Copy CLAUDE.md only if it doesn't exist (user likely wants to customize)
if [[ ! -f "$TARGET_DIR/CLAUDE.md" ]]; then
    copy_file "$TEMPLATE_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"
else
    echo -e "  ${YELLOW}Skip${NC} CLAUDE.md (exists - preserve customizations)"
fi

# Create directories with .gitkeep
mkdir -p "$TARGET_DIR/logs"
mkdir -p "$TARGET_DIR/specs"
touch "$TARGET_DIR/logs/.gitkeep"
touch "$TARGET_DIR/specs/.gitkeep"
echo -e "  ${GREEN}Create${NC} logs/ and specs/ directories"

echo ""

# Step 3: Environment configuration
echo -e "${BOLD}Step 3: Environment Configuration${NC}"
echo -e "Let's set up your .env file with API keys and preferences."
echo ""

# Gather user info
read -p "Your name (for ENGINEER_NAME): " ENGINEER_NAME
ENGINEER_NAME="${ENGINEER_NAME:-Developer}"

echo ""
echo -e "${CYAN}API Keys (press Enter to skip any):${NC}"
echo -e "These enable optional features like TTS and AI-powered summaries."
echo ""

read -p "ANTHROPIC_API_KEY (for LLM summaries): " ANTHROPIC_API_KEY
read -p "OPENAI_API_KEY (for TTS + LLM fallback): " OPENAI_API_KEY
read -p "ELEVENLABS_API_KEY (for premium TTS): " ELEVENLABS_API_KEY
read -p "OLLAMA_HOST (local LLM, e.g., http://localhost:11434): " OLLAMA_HOST

echo ""
echo -e "${CYAN}Optional API Keys:${NC}"
read -p "FIRECRAWL_API_KEY (web scraping): " FIRECRAWL_API_KEY
read -p "DEEPSEEK_API_KEY: " DEEPSEEK_API_KEY
read -p "GEMINI_API_KEY: " GEMINI_API_KEY
read -p "GROQ_API_KEY: " GROQ_API_KEY

# Create .env file
cat > "$TARGET_DIR/.env" << EOF
# Claude Code Template Environment Configuration
# Generated by setup.sh on $(date)

# Your name (used in personalized messages)
ENGINEER_NAME=$ENGINEER_NAME

# AI Provider API Keys
ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY

# TTS Provider
ELEVENLABS_API_KEY=$ELEVENLABS_API_KEY

# Local LLM (optional)
OLLAMA_HOST=$OLLAMA_HOST

# Additional providers (optional)
DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY
FIRECRAWL_API_KEY=$FIRECRAWL_API_KEY
GEMINI_API_KEY=$GEMINI_API_KEY
GROQ_API_KEY=$GROQ_API_KEY
EOF

echo -e "${GREEN}Created .env file${NC}"

echo ""

# Step 4: Feature toggles
echo -e "${BOLD}Step 4: Feature Configuration${NC}"

# Check if TTS can work
TTS_AVAILABLE=false
if [[ -n "$ELEVENLABS_API_KEY" || -n "$OPENAI_API_KEY" ]]; then
    TTS_AVAILABLE=true
fi

if [[ "$TTS_AVAILABLE" == "false" ]]; then
    echo -e "${YELLOW}Note: No TTS API keys provided.${NC}"
    echo -e "TTS features will use local pyttsx3 fallback (limited quality)."
    echo ""
    echo -e "Disable TTS notifications entirely? [y/N]"
    read -p "" DISABLE_TTS
    if [[ "$DISABLE_TTS" =~ ^[Yy]$ ]]; then
        # Remove --notify flags from settings.json
        if [[ -f "$TARGET_DIR/.claude/settings.json" ]]; then
            sed -i '' 's/ --notify//g' "$TARGET_DIR/.claude/settings.json" 2>/dev/null || \
            sed -i 's/ --notify//g' "$TARGET_DIR/.claude/settings.json"
            echo -e "${GREEN}Disabled TTS notifications in settings.json${NC}"
        fi
    fi
fi

echo ""

# Agent naming feature
echo -e "Enable AI-powered agent naming? (requires LLM API key) [Y/n]"
read -p "" ENABLE_NAMING
if [[ "$ENABLE_NAMING" =~ ^[Nn]$ ]]; then
    if [[ -f "$TARGET_DIR/.claude/settings.json" ]]; then
        sed -i '' 's/ --name-agent//g' "$TARGET_DIR/.claude/settings.json" 2>/dev/null || \
        sed -i 's/ --name-agent//g' "$TARGET_DIR/.claude/settings.json"
        echo -e "${GREEN}Disabled agent naming in settings.json${NC}"
    fi
fi

echo ""

# Step 5: Git initialization
echo -e "${BOLD}Step 5: Git Repository${NC}"

if [[ -d "$TARGET_DIR/.git" ]]; then
    echo -e "${CYAN}Git repository already exists.${NC}"
else
    echo -e "Initialize a new git repository? [Y/n]"
    read -p "" INIT_GIT
    if [[ ! "$INIT_GIT" =~ ^[Nn]$ ]]; then
        cd "$TARGET_DIR"
        git init
        echo -e "${GREEN}Initialized git repository${NC}"
    fi
fi

echo ""

# Done!
echo -e "${GREEN}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete!                             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "Your Claude Code template has been set up at:"
echo -e "  ${CYAN}$TARGET_DIR${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. ${CYAN}cd $TARGET_DIR${NC}"
echo -e "  2. Review and customize ${CYAN}CLAUDE.md${NC} for your project"
echo -e "  3. Start Claude Code: ${CYAN}claude${NC}"
echo ""
echo -e "${BOLD}Verify hooks are working:${NC}"
echo -e "  - Check ${CYAN}logs/${NC} directory after running commands"
echo -e "  - Status line should appear at terminal bottom"
echo -e "  - Try ${CYAN}/plan${NC} command to test slash commands"
echo ""
echo -e "${BOLD}Useful commands:${NC}"
echo -e "  ${CYAN}/prime${NC}       - Load project context"
echo -e "  ${CYAN}/plan${NC}        - Create implementation plan"
echo -e "  ${CYAN}/build${NC}       - Execute a plan"
echo -e "  ${CYAN}/all_tools${NC}   - List available tools"
echo ""

if [[ -z "$ANTHROPIC_API_KEY" && -z "$OPENAI_API_KEY" && -z "$OLLAMA_HOST" ]]; then
    echo -e "${YELLOW}Note: No LLM API keys configured.${NC}"
    echo -e "Some features (task summaries, agent naming) will be limited."
    echo -e "Add keys to ${CYAN}.env${NC} when available."
    echo ""
fi

echo -e "Happy coding! ${GREEN}🚀${NC}"
