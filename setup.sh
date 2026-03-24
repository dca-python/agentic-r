#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# 🌟 R-RESEARCHER AI SETUP
# Safe to run multiple times. Will skip anything already installed.
# ──────────────────────────────────────────────

REPO_URL="https://raw.githubusercontent.com/dca-python/agentic-r/main"

# ── Helper: offer to run the next script ──
offer_next() {
    local prompt="$1"
    local script_url="$2"
    local answer
    read -rp "$prompt (y/n): " answer
    if [[ "$answer" =~ ^[Yy] ]]; then
        echo ""
        /bin/bash -c "$(curl -fsSL "$script_url")"
        exit 0
    fi
}

clear
echo "=========================================="
echo "🌟 R-RESEARCHER AI SETUP STARTING"
echo "=========================================="
echo ""
echo "This script will install: Homebrew, R, VS Code, Node.js,"
echo "and the R Language Server for autocomplete."
echo ""
echo "------------------------------------------"

# ── Helper: detect architecture ──
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    BREW_PREFIX="/opt/homebrew"
    echo "🖥  Detected: Apple Silicon (M1/M2/M3/M4)"
else
    BREW_PREFIX="/usr/local"
    echo "🖥  Detected: Intel Mac"
fi
echo ""

# ── Helper: ensure brew is on PATH for this session ──
ensure_brew_path() {
    if ! command -v brew &> /dev/null && [[ -x "$BREW_PREFIX/bin/brew" ]]; then
        eval "$($BREW_PREFIX/bin/brew shellenv)"
    fi
}

# ── Helper: ensure VS Code CLI is on PATH ──
ensure_code_path() {
    local VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    if [[ -d "$VSCODE_BIN" ]] && ! command -v code &> /dev/null; then
        export PATH="$PATH:$VSCODE_BIN"
    fi
}

# ──────────────────────────────────────────────
# 0. PRE-FLIGHT: Xcode Command Line Tools
# ──────────────────────────────────────────────
# Without these, Homebrew and many compilers fail. Installing them
# up front prevents the hidden pop-up that confuses beginners.
if ! xcode-select -p &> /dev/null; then
    echo "📥 Installing Xcode Command Line Tools (required by Homebrew)..."
    echo "   A dialog box may appear — click 'Install' and wait for it to finish."
    echo "   This can take 5–10 minutes."
    echo ""
    xcode-select --install 2>/dev/null || true
    # Wait for the installation to complete
    echo "⏳ Waiting for Command Line Tools installation to finish..."
    until xcode-select -p &> /dev/null; do
        sleep 5
    done
    echo "  ✅ Command Line Tools installed."
else
    echo "✅ Xcode Command Line Tools already installed."
fi
echo ""

# ──────────────────────────────────────────────
# 1. Homebrew
# ──────────────────────────────────────────────
if command -v brew &> /dev/null; then
    echo "✅ Homebrew is already installed — skipping."
else
    echo "📥 Installing Homebrew (the Mac App Store for Terminal tools)..."
    echo "   This takes 2–5 minutes."
    echo ""
    echo "   ⚠️  Your Mac will ask for your password."
    echo "   You won't see dots or stars while you type — that's normal."
    echo "   Type your password carefully and press Enter."
    echo ""
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_path
fi

# ── Persist brew on PATH for Apple Silicon ──
if [[ "$ARCH" == "arm64" ]]; then
    BREW_SHELLENV='eval "$(/opt/homebrew/bin/brew shellenv)"'
    for RC_FILE in "$HOME/.zprofile" "$HOME/.zshrc"; do
        if [[ -f "$RC_FILE" ]] && grep -qF '/opt/homebrew/bin/brew shellenv' "$RC_FILE"; then
            : # already present
        else
            echo "" >> "$RC_FILE"
            echo "# Added by R-Researcher AI Setup" >> "$RC_FILE"
            echo "$BREW_SHELLENV" >> "$RC_FILE"
        fi
    done
fi

# Final PATH check — if brew still isn't found, something went wrong
ensure_brew_path
if ! command -v brew &> /dev/null; then
    echo ""
    echo "❌ Homebrew installed but 'brew' command not found in this session."
    echo "   This usually means the PATH didn't update. Try:"
    echo "   1. Close Terminal completely (Cmd + Q)"
    echo "   2. Open a new Terminal"
    echo "   3. Run this script again"
    exit 1
fi

echo ""

# ──────────────────────────────────────────────
# 2. Fix common permission issues BEFORE they cause trouble
# ──────────────────────────────────────────────
if [[ "$ARCH" == "arm64" ]] && [[ -d /opt/homebrew ]]; then
    BREW_OWNER=$(stat -f '%Su' /opt/homebrew 2>/dev/null || echo "unknown")
    if [[ "$BREW_OWNER" != "$(whoami)" ]]; then
        echo "🔧 Fixing Homebrew directory ownership..."
        sudo chown -R "$(whoami)" /opt/homebrew
        echo "  ✅ Fixed."
    fi
elif [[ "$ARCH" == "x86_64" ]] && [[ -d /usr/local/Homebrew ]]; then
    BREW_OWNER=$(stat -f '%Su' /usr/local/Homebrew 2>/dev/null || echo "unknown")
    if [[ "$BREW_OWNER" != "$(whoami)" ]]; then
        echo "🔧 Fixing Homebrew directory ownership..."
        sudo chown -R "$(whoami)" /usr/local/Homebrew
        echo "  ✅ Fixed."
    fi
fi

# ──────────────────────────────────────────────
# 3. R
# ──────────────────────────────────────────────
if brew list --cask r &> /dev/null 2>&1; then
    echo "✅ R is already installed — skipping."
else
    echo "📥 Installing R (the latest stable version)..."
    echo "   This may take a few minutes if R compiles from source."
    brew install --cask r
fi

# ──────────────────────────────────────────────
# 4. VS Code
# ──────────────────────────────────────────────
if brew list --cask visual-studio-code &> /dev/null 2>&1; then
    echo "✅ VS Code is already installed — skipping."
elif [[ -d "/Applications/Visual Studio Code.app" ]]; then
    echo "✅ VS Code is already in Applications — skipping."
else
    echo "📥 Installing Visual Studio Code..."
    brew install --cask visual-studio-code
fi

# ──────────────────────────────────────────────
# 5. Node.js
# ──────────────────────────────────────────────
if command -v node &> /dev/null; then
    echo "✅ Node.js is already installed ($(node --version)) — skipping."
else
    echo "📥 Installing Node.js (required for AI agents)..."
    brew install node
fi

# ── Fix npm global directory preemptively ──
if command -v npm &> /dev/null; then
    NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "")
    if [[ "$NPM_PREFIX" == "/usr/local" ]] || [[ "$NPM_PREFIX" == "/usr" ]]; then
        echo "🔧 Configuring npm global directory (avoids permission errors later)..."
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global"
        NPM_PATH_LINE='export PATH="$HOME/.npm-global/bin:$PATH"'
        for RC_FILE in "$HOME/.zshrc" "$HOME/.zprofile"; do
            if [[ -f "$RC_FILE" ]] && grep -qF '.npm-global/bin' "$RC_FILE"; then
                : # already present
            else
                echo "" >> "$RC_FILE"
                echo "# npm global packages (added by R-Researcher AI Setup)" >> "$RC_FILE"
                echo "$NPM_PATH_LINE" >> "$RC_FILE"
            fi
        done
        export PATH="$HOME/.npm-global/bin:$PATH"
        echo "  ✅ npm global directory set to ~/.npm-global"
    fi
fi

echo ""

# ──────────────────────────────────────────────
# 6. VS Code R Extension
# ──────────────────────────────────────────────
ensure_code_path

if command -v code &> /dev/null; then
    INSTALLED_EXTENSIONS=$(code --list-extensions 2>/dev/null || echo "")
    if echo "$INSTALLED_EXTENSIONS" | grep -qi "REditorSupport.r"; then
        echo "✅ VS Code R extension is already installed — skipping."
    else
        echo "🧩 Installing VS Code R extension..."
        code --install-extension REditorSupport.r --force
    fi
else
    echo "⚠️  Could not find the 'code' command. Open VS Code manually,"
    echo "   press Cmd+Shift+P, type 'Shell Command: Install', and hit Enter."
    echo "   Then re-run this script."
fi

echo ""

# ──────────────────────────────────────────────
# 7. R Language Server
# ──────────────────────────────────────────────
if command -v Rscript &> /dev/null; then
    echo "📦 Installing R Language Server (for autocomplete in VS Code)..."
    # Create user R library directory if it doesn't exist
    R_LIB_USER=$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))" 2>/dev/null || echo "")
    if [[ -n "$R_LIB_USER" ]] && [[ ! -d "$R_LIB_USER" ]]; then
        mkdir -p "$R_LIB_USER"
    fi
    Rscript -e "if (!requireNamespace('languageserver', quietly = TRUE)) install.packages('languageserver', repos = 'https://cloud.r-project.org')" || {
        echo "⚠️  R language server installation had an issue."
        echo "   You can install it manually later: install.packages('languageserver')"
    }
else
    echo "⚠️  Rscript not found on PATH. R may need a Terminal restart to be detected."
fi

echo ""

# ──────────────────────────────────────────────
# 8. Verification
# ──────────────────────────────────────────────
echo "=========================================="
echo "🧪 CHECKING INSTALLATIONS"
echo "=========================================="
echo ""

INSTALL_OK=true

check_tool() {
    local name="$1"
    local cmd="$2"
    local version
    version=$(eval "$cmd" 2>/dev/null) || version=""
    if [[ -n "$version" ]]; then
        echo "  ✅ $name  →  $version"
    else
        echo "  ❌ $name  →  not found (try restarting Terminal)"
        INSTALL_OK=false
    fi
}

check_tool "Homebrew" "brew --version | head -1"
check_tool "R"        "R --version 2>/dev/null | head -1"
check_tool "Node.js"  "node --version"
check_tool "VS Code"  "code --version 2>/dev/null | head -1"

echo ""

if [[ "$INSTALL_OK" == true ]]; then
    echo "=========================================="
    echo "🎉 SETUP COMPLETE — everything installed!"
    echo "=========================================="
else
    echo "=========================================="
    echo "⚠️  SETUP FINISHED WITH WARNINGS"
    echo "=========================================="
    echo ""
    echo "Some tools weren't detected. This usually fixes itself:"
    echo "  1. Close Terminal completely (Cmd + Q)"
    echo "  2. Open a new Terminal"
    echo "  3. Paste the verification command from the README"
fi

echo ""

# Open VS Code for the user
open -a "Visual Studio Code" 2>/dev/null || echo "💡 Open VS Code from your Applications folder."

echo ""
echo "------------------------------------------"
echo ""
echo "What's next?"
echo ""
offer_next "Make VS Code feel like RStudio? (recommended)" "$REPO_URL/rstudio-feel.sh"
echo ""
offer_next "Create a new R project folder?" "$REPO_URL/new-project.sh"
echo ""
