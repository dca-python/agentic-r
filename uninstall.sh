#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# 🧹 UNINSTALL R-RESEARCHER AI SETUP
# Reverses everything installed by setup.sh and rstudio-feel.sh.
# Interactive: asks before every single step.
# If you had any of these tools before running setup.sh,
# just say "n" to keep them.
# ──────────────────────────────────────────────

REPO_URL="https://raw.githubusercontent.com/dca-python/agentic-r/main"
MANIFEST_DIR="$HOME/.r-ai-powerpack"
MANIFEST_FILE="$MANIFEST_DIR/install-manifest.json"

clear
echo "=========================================="
echo "🧹 R-RESEARCHER AI UNINSTALL"
echo "=========================================="
echo ""
echo "This script will walk you through removing everything"
echo "that was installed by the R-Researcher AI Setup."
echo ""
echo "Each step asks for confirmation — nothing is deleted"
echo "without your explicit 'y'. If a tool was already on your"
echo "Mac before you ran setup.sh, just say 'n' to keep it."
echo ""
echo "------------------------------------------"
echo ""

# ── Helper: ask y/n ──
confirm() {
    local prompt="$1"
    local answer
    read -rp "$prompt (y/n): " answer
    [[ "$answer" =~ ^[Yy] ]]
}

# ── Helper: run next script ──
offer_next() {
    local prompt="$1"
    local script_url="$2"
    echo ""
    if confirm "$prompt"; then
        echo ""
        /bin/bash -c "$(curl -fsSL "$script_url")"
        exit 0
    fi
}

# ── Detect architecture ──
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
else
    BREW_PREFIX="/usr/local"
fi

# ── Ensure brew is on PATH for this session ──
if ! command -v brew &> /dev/null && [[ -x "$BREW_PREFIX/bin/brew" ]]; then
    eval "$($BREW_PREFIX/bin/brew shellenv)"
fi

# ── Ensure VS Code CLI is on PATH ──
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
if [[ -d "$VSCODE_BIN" ]] && ! command -v code &> /dev/null; then
    export PATH="$PATH:$VSCODE_BIN"
fi

REMOVED_SOMETHING=false

# ──────────────────────────────────────────────
# 1. AI AGENTS (npm global packages)
# ──────────────────────────────────────────────

echo "── AI Agents ──"
echo ""

if command -v npm &> /dev/null; then
    for AGENT_PKG in "@anthropic-ai/claude-code" "@google/gemini-cli" "kirocli"; do
        # Check if installed globally
        if npm list -g "$AGENT_PKG" &> /dev/null; then
            AGENT_NAME="$AGENT_PKG"
            case "$AGENT_PKG" in
                "@anthropic-ai/claude-code") AGENT_NAME="Claude Code" ;;
                "@google/gemini-cli")        AGENT_NAME="Gemini CLI" ;;
                "kirocli")                   AGENT_NAME="Kiro CLI" ;;
            esac
            if confirm "Remove $AGENT_NAME ($AGENT_PKG)?"; then
                npm uninstall -g "$AGENT_PKG"
                echo "  ✅ $AGENT_NAME removed."
                REMOVED_SOMETHING=true
            else
                echo "  ⏭  Keeping $AGENT_NAME."
            fi
        fi
    done
else
    echo "  npm not found — skipping AI agent check."
fi

echo ""

# ──────────────────────────────────────────────
# 2. VS CODE EXTENSIONS added by rstudio-feel.sh
# ──────────────────────────────────────────────

echo "── VS Code Extensions ──"
echo ""

if command -v code &> /dev/null; then
    INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")

    for EXT in "REditorSupport.r" "MilesCranmer.rshortcuts"; do
        if echo "$INSTALLED_EXTENSIONS" | grep -qi "$EXT"; then
            EXT_NAME="$EXT"
            case "$EXT" in
                "REditorSupport.r")       EXT_NAME="R extension (REditorSupport.r)" ;;
                "MilesCranmer.rshortcuts") EXT_NAME="R Shortcuts (MilesCranmer.rshortcuts)" ;;
            esac
            if confirm "Remove VS Code extension: $EXT_NAME?"; then
                code --uninstall-extension "$EXT" 2>/dev/null || true
                echo "  ✅ $EXT_NAME removed."
                REMOVED_SOMETHING=true
            else
                echo "  ⏭  Keeping $EXT_NAME."
            fi
        fi
    done
else
    echo "  VS Code CLI not found — skipping extension check."
fi

echo ""

# ──────────────────────────────────────────────
# 3. VS CODE SETTINGS & KEYBINDINGS
#    Uses the install manifest to restore the
#    exact state from before the Power-Pack
#    installation. Settings you changed or added
#    independently after that point stay untouched.
# ──────────────────────────────────────────────

echo "── VS Code Settings ──"
echo ""

VSCODE_USER_DIR="$HOME/Library/Application Support/Code/User"
VSCODE_SETTINGS="$VSCODE_USER_DIR/settings.json"
VSCODE_KEYBINDINGS="$VSCODE_USER_DIR/keybindings.json"

if [[ -f "$MANIFEST_FILE" ]]; then
    INSTALL_DATE=$(python3 -c "
import json
with open('$MANIFEST_FILE') as f:
    m = json.load(f)
print(m.get('installed_at', 'unknown'))
" 2>/dev/null || echo "unknown")
    echo "  Found install manifest from: $INSTALL_DATE"
    echo ""
    echo "  This will restore the following VS Code settings to their state"
    echo "  from BEFORE the Power-Pack was installed ($INSTALL_DATE)."
    echo "  Any settings you changed or added independently since then"
    echo "  will NOT be affected."
    echo ""
fi

# ── Settings.json restore ──
if [[ -f "$VSCODE_SETTINGS" ]] && grep -q "r.plot.useHttpgd" "$VSCODE_SETTINGS" 2>/dev/null; then
    if confirm "Restore VS Code settings.json to pre-Power-Pack state?"; then
        if [[ -f "$MANIFEST_FILE" ]]; then
            # Manifest-based restore: surgical, key-by-key
            python3 -c "
import json, sys

manifest_path = '$MANIFEST_FILE'
settings_path = '$VSCODE_SETTINGS'

with open(manifest_path, 'r') as f:
    manifest = json.load(f)

with open(settings_path, 'r') as f:
    current = json.load(f)

before = manifest.get('settings_before', {})

for key, old_value in before.items():
    if old_value is None:
        # Key didn't exist before installation → remove it
        current.pop(key, None)
    else:
        # Key had a value before installation → restore it
        current[key] = old_value

with open(settings_path, 'w') as f:
    json.dump(current, f, indent=4)

print('  ✅ VS Code settings restored to pre-Power-Pack state.')
print('     All other settings left untouched.')
"
        else
            # No manifest — fallback: remove only the known keys
            echo "  ⚠️  No install manifest found. Removing known Power-Pack keys only."
            echo "     (Original values for these keys cannot be restored.)"
            python3 -c "
import json, sys
keys_to_remove = [
    'r.rpath.mac', 'r.plot.useHttpgd', 'r.bracketedPaste',
    'r.alwaysUseActiveTerminal', 'r.sessionWatcher',
    'r.workspaceViewer.showObjectSize',
    'editor.bracketPairColorization.enabled', 'editor.guides.bracketPairs',
    'editor.formatOnType', 'workbench.colorTheme', 'workbench.startupEditor',
    'editor.minimap.enabled', 'breadcrumbs.enabled'
]
try:
    with open(sys.argv[1], 'r') as f:
        settings = json.load(f)
    for k in keys_to_remove:
        settings.pop(k, None)
    with open(sys.argv[1], 'w') as f:
        json.dump(settings, f, indent=4)
    print('  ✅ Power-Pack keys removed from settings.json.')
except Exception as e:
    print(f'  ⚠️  Could not edit settings.json automatically: {e}')
    print('     You can remove the R-related keys manually.')
" "$VSCODE_SETTINGS"
        fi

        # If settings.json is now empty ({}), and it didn't exist before, remove it
        if [[ -f "$MANIFEST_FILE" ]]; then
            python3 -c "
import json
manifest_path = '$MANIFEST_FILE'
settings_path = '$VSCODE_SETTINGS'
with open(manifest_path) as f:
    m = json.load(f)
if not m.get('settings_file_existed', True):
    with open(settings_path) as f:
        s = json.load(f)
    if not s:
        import os
        os.remove(settings_path)
        print('  🧹 settings.json removed (it did not exist before Power-Pack).')
" 2>/dev/null || true
        fi

        REMOVED_SOMETHING=true
    else
        echo "  ⏭  Keeping VS Code settings."
    fi
fi

# ── Keybindings.json restore ──
if [[ -f "$VSCODE_KEYBINDINGS" ]] && grep -q "r.runSelection" "$VSCODE_KEYBINDINGS" 2>/dev/null; then
    if confirm "Restore VS Code keybindings.json to pre-Power-Pack state?"; then
        if [[ -f "$MANIFEST_FILE" ]]; then
            python3 -c "
import json, os

manifest_path = '$MANIFEST_FILE'
keybindings_path = '$VSCODE_KEYBINDINGS'

with open(manifest_path, 'r') as f:
    manifest = json.load(f)

if not manifest.get('keybindings_file_existed', True):
    # File didn't exist before → remove it entirely
    os.remove(keybindings_path)
    print('  ✅ keybindings.json removed (it did not exist before Power-Pack).')
else:
    # Restore original keybindings
    with open(keybindings_path, 'w') as f:
        json.dump(manifest.get('keybindings_before', []), f, indent=4)
    print('  ✅ keybindings.json restored to pre-Power-Pack state.')
"
        else
            # No manifest — fallback: remove only R-specific keybindings
            python3 -c "
import json, sys
try:
    with open(sys.argv[1], 'r') as f:
        bindings = json.load(f)
    bindings = [b for b in bindings
                if not (b.get('command') == 'r.runSelection'
                        or (b.get('key') == 'ctrl+shift+m'
                            and b.get('args', {}).get('text', '') == ' |> '))]
    with open(sys.argv[1], 'w') as f:
        json.dump(bindings, f, indent=4)
    print('  ✅ R keybindings removed.')
except Exception as e:
    print(f'  ⚠️  Could not edit keybindings.json automatically: {e}')
    print('     You can remove them manually.')
" "$VSCODE_KEYBINDINGS"
        fi
        REMOVED_SOMETHING=true
    else
        echo "  ⏭  Keeping VS Code keybindings."
    fi
fi

echo ""

# ──────────────────────────────────────────────
# 4. R PACKAGES added by setup.sh / rstudio-feel.sh
# ──────────────────────────────────────────────

echo "── R Packages ──"
echo ""

if command -v Rscript &> /dev/null; then
    for R_PKG in "languageserver" "httpgd" "here"; do
        INSTALLED=$(Rscript -e "cat(requireNamespace('$R_PKG', quietly = TRUE))" 2>/dev/null || echo "FALSE")
        if [[ "$INSTALLED" == "TRUE" ]]; then
            if confirm "Remove R package '$R_PKG'?"; then
                Rscript -e "remove.packages('$R_PKG')" 2>/dev/null || true
                echo "  ✅ $R_PKG removed."
                REMOVED_SOMETHING=true
            else
                echo "  ⏭  Keeping $R_PKG."
            fi
        fi
    done
else
    echo "  R not found — skipping R package check."
fi

echo ""

# ──────────────────────────────────────────────
# 5. NODE.JS (installed via Homebrew)
# ──────────────────────────────────────────────

echo "── Node.js ──"
echo ""

if command -v brew &> /dev/null && brew list node &> /dev/null 2>&1; then
    if confirm "Remove Node.js? (This was installed for AI agents)"; then
        brew uninstall node
        echo "  ✅ Node.js removed."
        REMOVED_SOMETHING=true
    else
        echo "  ⏭  Keeping Node.js."
    fi
fi

# Clean up npm global directory if it exists and is empty
if [[ -d "$HOME/.npm-global" ]]; then
    NPM_COUNT=$(find "$HOME/.npm-global" -type f 2>/dev/null | head -1)
    if [[ -z "$NPM_COUNT" ]]; then
        rm -rf "$HOME/.npm-global"
        echo "  🧹 Cleaned up empty ~/.npm-global directory."
    elif confirm "Remove ~/.npm-global directory (npm global packages)?"; then
        rm -rf "$HOME/.npm-global"
        echo "  ✅ ~/.npm-global removed."
        REMOVED_SOMETHING=true
    else
        echo "  ⏭  Keeping ~/.npm-global."
    fi
fi

echo ""

# ──────────────────────────────────────────────
# 6. VS CODE (installed via Homebrew)
# ──────────────────────────────────────────────

echo "── VS Code ──"
echo ""

if command -v brew &> /dev/null && brew list --cask visual-studio-code &> /dev/null 2>&1; then
    if confirm "Remove Visual Studio Code?"; then
        brew uninstall --cask visual-studio-code
        echo "  ✅ VS Code application removed."
        REMOVED_SOMETHING=true

        # Offer to remove VS Code user data
        if [[ -d "$HOME/Library/Application Support/Code" ]]; then
            if confirm "Also remove VS Code user data (settings, extensions, etc.)?"; then
                rm -rf "$HOME/Library/Application Support/Code"
                rm -rf "$HOME/.vscode"
                echo "  ✅ VS Code user data removed."
            else
                echo "  ⏭  Keeping VS Code user data."
            fi
        fi
    else
        echo "  ⏭  Keeping VS Code."
    fi
elif [[ -d "/Applications/Visual Studio Code.app" ]]; then
    echo "  VS Code found but not managed by Homebrew — skipping."
    echo "  (You can remove it manually from Applications.)"
fi

echo ""

# ──────────────────────────────────────────────
# 7. R (installed via Homebrew cask)
# ──────────────────────────────────────────────

echo "── R ──"
echo ""

if command -v brew &> /dev/null && brew list --cask r &> /dev/null 2>&1; then
    if confirm "Remove R?"; then
        brew uninstall --cask r
        echo "  ✅ R removed."
        REMOVED_SOMETHING=true

        # Offer to remove R user library
        R_LIB_DIRS=("$HOME/Library/R" "$HOME/.R")
        for R_DIR in "${R_LIB_DIRS[@]}"; do
            if [[ -d "$R_DIR" ]]; then
                if confirm "Also remove R user library ($R_DIR)?"; then
                    rm -rf "$R_DIR"
                    echo "  ✅ $R_DIR removed."
                else
                    echo "  ⏭  Keeping $R_DIR."
                fi
            fi
        done
    else
        echo "  ⏭  Keeping R."
    fi
fi

echo ""

# ──────────────────────────────────────────────
# 8. HOMEBREW
# ──────────────────────────────────────────────

echo "── Homebrew ──"
echo ""

if command -v brew &> /dev/null; then
    # Count remaining formulae — warn if Homebrew is still in use
    REMAINING=$(brew list --formula 2>/dev/null | wc -l | tr -d ' ')
    REMAINING_CASKS=$(brew list --cask 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$REMAINING" -gt 0 ]] || [[ "$REMAINING_CASKS" -gt 0 ]]; then
        echo "  ⚠️  Homebrew still has $REMAINING formula(e) and $REMAINING_CASKS cask(s) installed."
        echo "     Removing Homebrew will also remove everything it manages."
        echo ""
    fi

    if confirm "Remove Homebrew entirely? (This is the nuclear option)"; then
        echo "  Uninstalling Homebrew... (this may ask for your password)"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
        echo "  ✅ Homebrew removed."
        REMOVED_SOMETHING=true
    else
        echo "  ⏭  Keeping Homebrew."
    fi
else
    echo "  Homebrew not found — nothing to do."
fi

echo ""

# ──────────────────────────────────────────────
# 9. SHELL CONFIG CLEANUP
# ──────────────────────────────────────────────

echo "── Shell Configuration ──"
echo ""
echo "  The setup script added a few lines to your shell config files"
echo "  (~/.zshrc and ~/.zprofile) for Homebrew PATH and npm."
echo ""

if confirm "Remove lines added by R-Researcher AI Setup from shell configs?"; then
    for RC_FILE in "$HOME/.zshrc" "$HOME/.zprofile"; do
        if [[ -f "$RC_FILE" ]]; then
            # Remove the specific lines we added (and their comment markers)
            TEMP_RC=$(mktemp)
            grep -v '# Added by R-Researcher AI Setup' "$RC_FILE" \
                | grep -v '# npm global packages (added by R-Researcher AI Setup)' \
                | grep -v '# npm global packages (added by fix-permissions.sh)' \
                | grep -v 'eval "$(/opt/homebrew/bin/brew shellenv)"' \
                | grep -v '.npm-global/bin' \
                > "$TEMP_RC" || true
            # Remove trailing blank lines that we left behind
            sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$TEMP_RC" > "$RC_FILE"
            rm -f "$TEMP_RC"
        fi
    done
    echo "  ✅ Shell config lines removed."
    REMOVED_SOMETHING=true
else
    echo "  ⏭  Keeping shell config changes."
fi

echo ""

# ──────────────────────────────────────────────
# 10. CLEAN UP MANIFEST
# ──────────────────────────────────────────────

if [[ -d "$MANIFEST_DIR" ]]; then
    if confirm "Remove the Power-Pack manifest (~/.r-ai-powerpack/)?"; then
        rm -rf "$MANIFEST_DIR"
        echo "  ✅ Manifest removed."
    else
        echo "  ⏭  Keeping manifest."
    fi
fi

echo ""

# ──────────────────────────────────────────────
# DONE
# ──────────────────────────────────────────────

if [[ "$REMOVED_SOMETHING" == true ]]; then
    echo "=========================================="
    echo "🧹 UNINSTALL FINISHED"
    echo "=========================================="
    echo ""
    echo "Close Terminal (Cmd + Q) and open a new one"
    echo "for all changes to take effect."
else
    echo "=========================================="
    echo "Nothing was removed."
    echo "=========================================="
fi

echo ""
echo "------------------------------------------"
echo ""
echo "Want to start fresh?"
echo ""
offer_next "Re-run the full setup?" "$REPO_URL/setup.sh"
echo ""
