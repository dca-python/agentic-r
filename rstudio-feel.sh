#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# 🎹 MAKE VS CODE FEEL LIKE RSTUDIO
# Installs R packages and configures VS Code settings
# to replicate the RStudio experience.
# Safe to run multiple times.
# ──────────────────────────────────────────────

REPO_URL="https://raw.githubusercontent.com/dca-python/agentic-r/main"
MANIFEST_DIR="$HOME/.r-ai-powerpack"
MANIFEST_FILE="$MANIFEST_DIR/install-manifest.json"

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

# ──────────────────────────────────────────────
# MANIFEST: snapshot the pre-installation state
# Only created on the very first run. Subsequent
# runs leave the manifest untouched so that the
# snapshot always reflects the state BEFORE this
# Power-Pack was ever installed.
# ──────────────────────────────────────────────

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS="$VSCODE_USER_DIR/settings.json"
VSCODE_KEYBINDINGS="$VSCODE_USER_DIR/keybindings.json"

if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "📸 Saving a snapshot of your current VS Code settings..."
    echo "   (So uninstall.sh can restore exactly this state later.)"
    echo ""
    mkdir -p "$MANIFEST_DIR"

    python3 -c "
import json, os, datetime

manifest = {
    'installed_at': datetime.datetime.now().astimezone().isoformat(),
    'description': 'Snapshot of VS Code state before R AI Power-Pack installation. uninstall.sh uses this to restore your settings to exactly this point.',
    'settings_file_existed': False,
    'settings_before': {},
    'keybindings_file_existed': False,
    'keybindings_before': []
}

settings_path = os.path.expanduser('~/Library/Application Support/Code/User/settings.json')
keybindings_path = os.path.expanduser('~/Library/Application Support/Code/User/keybindings.json')

# Keys that rstudio-feel.sh will set
managed_keys = [
    'r.rpath.mac', 'r.plot.useHttpgd', 'r.bracketedPaste',
    'r.alwaysUseActiveTerminal', 'r.sessionWatcher',
    'r.workspaceViewer.showObjectSize',
    'editor.bracketPairColorization.enabled', 'editor.guides.bracketPairs',
    'editor.formatOnType', 'workbench.colorTheme', 'workbench.startupEditor',
    'editor.minimap.enabled', 'breadcrumbs.enabled'
]

# Snapshot settings.json
if os.path.isfile(settings_path):
    manifest['settings_file_existed'] = True
    try:
        with open(settings_path, 'r') as f:
            current = json.load(f)
        # Store only the keys we will touch — with their current values
        # Keys not present get null (= they didn't exist before)
        for key in managed_keys:
            if key in current:
                manifest['settings_before'][key] = current[key]
            else:
                manifest['settings_before'][key] = None
    except Exception:
        # Malformed JSON — treat as empty
        for key in managed_keys:
            manifest['settings_before'][key] = None

# Snapshot keybindings.json
if os.path.isfile(keybindings_path):
    manifest['keybindings_file_existed'] = True
    try:
        with open(keybindings_path, 'r') as f:
            manifest['keybindings_before'] = json.load(f)
    except Exception:
        manifest['keybindings_before'] = []

manifest_path = os.path.expanduser('~/.r-ai-powerpack/install-manifest.json')
with open(manifest_path, 'w') as f:
    json.dump(manifest, f, indent=2)
"
    echo "  ✅ Snapshot saved to ~/.r-ai-powerpack/install-manifest.json"
    echo ""
else
    echo "ℹ️  Manifest already exists (first install snapshot preserved)."
    echo ""
fi

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
# VS CODE SETTINGS (settings.json)
# ──────────────────────────────────────────────

echo "⚙️  Configuring VS Code settings..."

mkdir -p "$VSCODE_USER_DIR"

# The settings we want to ensure are present
declare -A R_SETTINGS
R_SETTINGS=(
    ["r.rpath.mac"]="\"$R_BINARY_PATH\""
    ["r.plot.useHttpgd"]="true"
    ["r.bracketedPaste"]="true"
    ["r.alwaysUseActiveTerminal"]="true"
    ["r.sessionWatcher"]="true"
    ["r.workspaceViewer.showObjectSize"]="true"
    ["editor.bracketPairColorization.enabled"]="true"
    ["editor.guides.bracketPairs"]="\"active\""
    ["editor.formatOnType"]="true"
    ["workbench.colorTheme"]="\"Default Light Modern\""
    ["workbench.startupEditor"]="\"none\""
    ["editor.minimap.enabled"]="false"
    ["breadcrumbs.enabled"]="false"
)

if [[ -f "$VSCODE_SETTINGS" ]] && grep -q '"r.plot.useHttpgd"' "$VSCODE_SETTINGS" 2>/dev/null; then
    echo "✅ R settings already present — skipping."
else
    # Build the settings block
    SETTINGS_BLOCK=""
    for key in "${!R_SETTINGS[@]}"; do
        SETTINGS_BLOCK="$SETTINGS_BLOCK    \"$key\": ${R_SETTINGS[$key]},
"
    done
    # Remove trailing comma from last line
    SETTINGS_BLOCK=$(echo "$SETTINGS_BLOCK" | sed '$ s/,$//')

    if [[ -f "$VSCODE_SETTINGS" ]]; then
        # Merge into existing settings
        TEMP_SETTINGS=$(mktemp)
        sed '$ s/}$//' "$VSCODE_SETTINGS" > "$TEMP_SETTINGS"
        if grep -q '"' "$TEMP_SETTINGS"; then
            echo "," >> "$TEMP_SETTINGS"
        fi
        echo "$SETTINGS_BLOCK" >> "$TEMP_SETTINGS"
        echo "}" >> "$TEMP_SETTINGS"
        cp "$TEMP_SETTINGS" "$VSCODE_SETTINGS"
        rm -f "$TEMP_SETTINGS"
        echo "✅ R settings merged into existing configuration."
    else
        echo "{" > "$VSCODE_SETTINGS"
        echo "$SETTINGS_BLOCK" >> "$VSCODE_SETTINGS"
        echo "}" >> "$VSCODE_SETTINGS"
        echo "✅ VS Code settings file created."
    fi
fi

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
    # Write fresh keybindings file
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
echo "  • Rainbow brackets → nested parentheses get distinct colors"
echo "  • Workspace viewer → see your loaded variables (like RStudio's Environment tab)"
echo "  • Session watcher  → VS Code tracks your R session state"
echo "  • Light theme      → clean, light background like RStudio"
echo "  • Decluttered      → welcome tab, minimap, breadcrumbs removed"
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
