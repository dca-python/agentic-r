#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# 🎹 MAKE VS CODE FEEL LIKE RSTUDIO
# Installs R packages and configures VS Code settings
# to replicate the RStudio experience.
# Safe to run multiple times.
# ──────────────────────────────────────────────

REPO_URL="https://raw.githubusercontent.com/dca-python/agentic-r/main"

# ── Detect script directory (repo root) ──
_SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [[ -n "$_SCRIPT_PATH" ]] && [[ -f "$_SCRIPT_PATH" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "$_SCRIPT_PATH")" && pwd)"
else
    SCRIPT_DIR=""
fi

clear
echo "=========================================="
echo "🎹 RSTUDIO-FEEL SETUP"
echo "=========================================="
echo ""
echo "This script will:"
echo "  1. Install 'httpgd' (plot viewer panel, like RStudio's Plots tab)"
echo "  2. Install 'R Shortcuts' extension (Alt+- for <- arrow)"
echo "  3. Set Cmd+Enter to run code and move to the next line"
echo "  4. Set Ctrl+Shift+M to insert the pipe operator (|>)"
echo "  5. Enable rainbow brackets for nested R expressions"
echo "  6. Enable the Environment/Workspace viewer (like RStudio's top-right panel)"
echo "  7. Auto-open an R terminal when you open a .R file"
echo "  8. Switch to a clean, light theme (RStudio uses a light background by default)"
echo "  9. Remove visual clutter (welcome tab, minimap, breadcrumbs)"
echo ""
echo "------------------------------------------"
echo ""

# ── Detect architecture for R binary path ──
if [[ $(uname -m) == "arm64" ]]; then
    R_BINARY_PATH="/opt/homebrew/bin/R"
else
    R_BINARY_PATH="/usr/local/bin/R"
fi

# ── Ensure VS Code CLI is available ──
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
if [[ -d "$VSCODE_BIN" ]] && ! command -v code &> /dev/null; then
    export PATH="$PATH:$VSCODE_BIN"
fi

# ── Pre-flight: check that R and VS Code are actually present ──
MISSING=""
if ! command -v Rscript &> /dev/null; then
    MISSING="R"
fi
if ! command -v code &> /dev/null; then
    if [[ -n "$MISSING" ]]; then MISSING="$MISSING and VS Code"; else MISSING="VS Code"; fi
fi
if [[ -n "$MISSING" ]]; then
    echo "⚠️  $MISSING not found."
    echo "   Run setup.sh first, then close and reopen Terminal."
    echo ""
    echo "   If you already ran setup.sh, the Terminal just needs a refresh:"
    echo "   Close Terminal (Cmd + Q), open a new one, try again."
    echo ""
    # Continue anyway for partial setup — don't exit
fi

# Global keybindings path (VS Code has no workspace-scoped keybindings)
VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_KEYBINDINGS="$VSCODE_USER_DIR/keybindings.json"

# ──────────────────────────────────────────────
# R PACKAGES
# ──────────────────────────────────────────────

if command -v Rscript &> /dev/null; then
    echo "📦 Installing R packages..."

    # Create user R library directory if it doesn't exist
    R_LIB_USER=$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))" 2>/dev/null || echo "")
    if [[ -n "$R_LIB_USER" ]] && [[ ! -d "$R_LIB_USER" ]]; then
        mkdir -p "$R_LIB_USER"
    fi

    # httpgd — interactive plot viewer
    Rscript -e "if (!requireNamespace('httpgd', quietly = TRUE)) install.packages('httpgd', repos = 'https://cloud.r-project.org')" || {
        echo "⚠️  httpgd installation had an issue. Install manually: install.packages('httpgd')"
    }
    echo "  ✅ httpgd"

    # Verify R binary path exists — warn if not
    if [[ ! -x "$R_BINARY_PATH" ]]; then
        # Try to find the actual R binary
        ACTUAL_R=$(command -v R 2>/dev/null || echo "")
        if [[ -n "$ACTUAL_R" ]]; then
            R_BINARY_PATH="$ACTUAL_R"
            echo "  ℹ️  R binary found at $R_BINARY_PATH (using this for VS Code config)"
        else
            echo "  ⚠️  R binary not found at $R_BINARY_PATH"
            echo "     After setup, open VS Code → Cmd+Shift+P → 'R: Select R Binary'"
        fi
    fi
else
    echo "⚠️  Rscript not found. Make sure R is installed (run setup.sh first)."
fi

echo ""

# ──────────────────────────────────────────────
# VS CODE EXTENSIONS
# ──────────────────────────────────────────────

if command -v code &> /dev/null; then
    INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")

    # R Shortcuts — Alt+- for <- arrow
    if echo "$INSTALLED_EXTENSIONS" | grep -qi "MilesCranmer.rshortcuts"; then
        echo "✅ R Shortcuts extension already installed."
    else
        echo "🧩 Installing R Shortcuts (Alt+- for <- arrow)..."
        code --install-extension MilesCranmer.rshortcuts --force 2>/dev/null || {
            echo "⚠️  Could not install R Shortcuts. Search 'R Shortcuts' in the VS Code extension sidebar."
        }
    fi

else
    echo "⚠️  'code' command not found. Open VS Code, press Cmd+Shift+P,"
    echo "   type 'Shell Command: Install', then re-run this script."
fi

echo ""

# ──────────────────────────────────────────────
# VS CODE WORKSPACE SETTINGS (.vscode/settings.json)
# Written to the repo/project root so global
# user settings stay untouched.
# ──────────────────────────────────────────────

# Determine where to write .vscode/settings.json
if [[ -n "$SCRIPT_DIR" ]]; then
    WORKSPACE_DIR="$SCRIPT_DIR"
else
    # Running via curl — use the current working directory
    WORKSPACE_DIR="$(pwd)"
fi
VSCODE_WS_DIR="$WORKSPACE_DIR/.vscode"
VSCODE_WS_SETTINGS="$VSCODE_WS_DIR/settings.json"

echo "⚙️  Writing workspace settings to $VSCODE_WS_DIR/settings.json..."

mkdir -p "$VSCODE_WS_DIR"

cat > "$VSCODE_WS_SETTINGS" << SETTINGS_EOF
{
    "r.rpath.mac": "$R_BINARY_PATH",
    "r.plot.useHttpgd": true,
    "r.bracketedPaste": true,
    "r.alwaysUseActiveTerminal": true,
    "r.sessionWatcher": true,
    "r.workspaceViewer.showObjectSize": true,
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": "active",
    "editor.formatOnType": true,
    "workbench.colorTheme": "Default Light Modern",
    "workbench.startupEditor": "none",
    "editor.minimap.enabled": false,
    "breadcrumbs.enabled": false
}
SETTINGS_EOF
echo "✅ Workspace settings written."

echo ""

# ──────────────────────────────────────────────
# VS CODE KEYBINDINGS (keybindings.json)
# ──────────────────────────────────────────────

echo "⌨️  Configuring keyboard shortcuts..."

if [[ -f "$VSCODE_KEYBINDINGS" ]] && grep -q "r.runSelection" "$VSCODE_KEYBINDINGS" 2>/dev/null; then
    # Check if pipe is also already there
    if grep -q "ctrl+shift+m" "$VSCODE_KEYBINDINGS" 2>/dev/null; then
        echo "✅ All keybindings already configured."
    else
        # Add pipe keybinding to existing file
        TEMP_KB=$(mktemp)
        sed '$ s/\]$//' "$VSCODE_KEYBINDINGS" > "$TEMP_KB"
        cat >> "$TEMP_KB" << 'KB_PIPE'
,
    {
        "key": "ctrl+shift+m",
        "command": "type",
        "args": { "text": " |> " },
        "when": "editorTextFocus && editorLangId == 'r'"
    }
]
KB_PIPE
        cp "$TEMP_KB" "$VSCODE_KEYBINDINGS"
        rm -f "$TEMP_KB"
        echo "✅ Added pipe shortcut (Ctrl+Shift+M)."
    fi
else
    # R keybindings to add
    R_KEYBINDINGS='    {
        "key": "cmd+enter",
        "command": "r.runSelection",
        "when": "editorTextFocus && editorLangId == '\''r'\''"
    },
    {
        "key": "ctrl+shift+m",
        "command": "type",
        "args": { "text": " |> " },
        "when": "editorTextFocus && editorLangId == '\''r'\''"
    }'

    if [[ -f "$VSCODE_KEYBINDINGS" ]] && grep -q '"' "$VSCODE_KEYBINDINGS" 2>/dev/null; then
        # File exists with content — ask before modifying
        echo ""
        echo "  You already have custom keybindings in:"
        echo "  $VSCODE_KEYBINDINGS"
        echo ""
        echo "  This will ADD (not replace) two R shortcuts:"
        echo "    • Cmd+Enter      → run current line (only in .R files)"
        echo "    • Ctrl+Shift+M   → insert |> pipe (only in .R files)"
        echo ""
        read -rp "  Add these R keybindings to your existing file? (y/n): " KB_ANSWER
        if [[ "$KB_ANSWER" =~ ^[Yy] ]]; then
            # Append to existing array
            TEMP_KB=$(mktemp)
            sed '$ s/\]$//' "$VSCODE_KEYBINDINGS" > "$TEMP_KB"
            echo "," >> "$TEMP_KB"
            echo "$R_KEYBINDINGS" >> "$TEMP_KB"
            echo "]" >> "$TEMP_KB"
            cp "$TEMP_KB" "$VSCODE_KEYBINDINGS"
            rm -f "$TEMP_KB"
            echo "  ✅ R keybindings added to existing file."
        else
            echo "  ⏭  Skipped. You can add them manually later."
        fi
    else
        # No file or empty — create fresh
        mkdir -p "$VSCODE_USER_DIR"
        cat > "$VSCODE_KEYBINDINGS" << 'KB_FRESH'
[
    {
        "key": "cmd+enter",
        "command": "r.runSelection",
        "when": "editorTextFocus && editorLangId == 'r'"
    },
    {
        "key": "ctrl+shift+m",
        "command": "type",
        "args": { "text": " |> " },
        "when": "editorTextFocus && editorLangId == 'r'"
    }
]
KB_FRESH
        echo "✅ Keybindings configured (Cmd+Enter, Ctrl+Shift+M)."
    fi
fi

echo ""
echo "=========================================="
echo "🎉 RSTUDIO-FEEL SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "What changed:"
echo "  • httpgd         → plots appear in a VS Code side panel"
echo "  • R Shortcuts    → Alt+- types the <- arrow"
echo "  • Cmd+Enter      → runs current line and moves to the next one"
echo "  • Ctrl+Shift+M   → inserts |> (pipe operator)"
echo "  • .vscode/settings.json → workspace-level R config (global settings untouched)"
echo ""
echo "👉 Restart VS Code now (Cmd+Q, then reopen) to activate everything."
echo ""
echo "------------------------------------------"
echo ""
echo "What's next?"
echo ""
echo "  📦 Install an AI agent (pick one or all — they don't conflict):"
echo "     npm install -g @anthropic-ai/claude-code    # Claude Code"
echo "     npm install -g @google/gemini-cli           # Gemini CLI (free tier)"
echo "     npm install -g kirocli                      # Kiro CLI"
echo ""
echo "  📁 Start a new project:"
echo "     /bin/bash -c \"\$(curl -fsSL $REPO_URL/new-project.sh)\""
echo ""
echo "  🗑  Undo everything this script did:"
echo "     /bin/bash -c \"\$(curl -fsSL $REPO_URL/uninstall.sh)\""
echo ""
