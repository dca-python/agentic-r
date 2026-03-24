#!/bin/bash
set -euo pipefail

# ──────────────────────────────────────────────
# 🔧 DEAL WITH PERMISSION ISSUES
# Resolves common macOS "permission denied" blocks
# that prevent Homebrew, R packages, or npm from installing.
# Safe to run multiple times.
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
echo "🔧 DEALING WITH PERMISSION ISSUES"
echo "=========================================="
echo ""
echo "macOS sometimes blocks installations because it thinks"
echo "you don't own certain folders. This script sorts that out."
echo "Your Mac will ask for your password."
echo ""
echo "------------------------------------------"
echo ""

FIXED_SOMETHING=false

# ── 1. Fix Homebrew directory ownership (Apple Silicon) ──
if [[ $(uname -m) == "arm64" ]] && [[ -d /opt/homebrew ]]; then
    BREW_OWNER=$(stat -f '%Su' /opt/homebrew)
    if [[ "$BREW_OWNER" != "$(whoami)" ]]; then
        echo "🔧 Fixing Homebrew directory ownership..."
        sudo chown -R "$(whoami)" /opt/homebrew
        echo "  ✅ Fixed."
        FIXED_SOMETHING=true
    else
        echo "✅ Homebrew directory ownership is correct."
    fi
fi

# ── 2. Fix Homebrew directory ownership (Intel) ──
if [[ $(uname -m) == "x86_64" ]] && [[ -d /usr/local/Homebrew ]]; then
    BREW_OWNER=$(stat -f '%Su' /usr/local/Homebrew)
    if [[ "$BREW_OWNER" != "$(whoami)" ]]; then
        echo "🔧 Fixing Homebrew directory ownership..."
        sudo chown -R "$(whoami)" /usr/local/Homebrew
        echo "  ✅ Fixed."
        FIXED_SOMETHING=true
    else
        echo "✅ Homebrew directory ownership is correct."
    fi
fi

# ── 3. Fix npm global directory ──
# npm global installs can fail if the global prefix directory
# is owned by root. Fix: set it to a user-owned location.
if command -v npm &> /dev/null; then
    NPM_PREFIX=$(npm config get prefix 2>/dev/null || echo "")
    if [[ "$NPM_PREFIX" == "/usr/local" ]] || [[ "$NPM_PREFIX" == "/usr" ]]; then
        echo "🔧 Fixing npm global install directory..."
        mkdir -p "$HOME/.npm-global"
        npm config set prefix "$HOME/.npm-global"

        # Add to PATH if not already there
        NPM_PATH_LINE='export PATH="$HOME/.npm-global/bin:$PATH"'
        for RC_FILE in "$HOME/.zshrc" "$HOME/.zprofile"; do
            if [[ -f "$RC_FILE" ]] && grep -qF '.npm-global/bin' "$RC_FILE"; then
                : # already present
            else
                echo "" >> "$RC_FILE"
                echo "# npm global packages (added by fix-permissions.sh)" >> "$RC_FILE"
                echo "$NPM_PATH_LINE" >> "$RC_FILE"
            fi
        done
        echo "  ✅ npm now installs global packages to ~/.npm-global"
        echo "  ⚠️  Close and reopen Terminal for this to take effect."
        FIXED_SOMETHING=true
    else
        echo "✅ npm global directory is fine."
    fi
fi

# ── 4. Fix R library directory ──
if command -v Rscript &> /dev/null; then
    R_LIB_USER=$(Rscript -e "cat(Sys.getenv('R_LIBS_USER'))" 2>/dev/null || echo "")
    if [[ -n "$R_LIB_USER" ]] && [[ ! -d "$R_LIB_USER" ]]; then
        echo "🔧 Creating user R library directory..."
        mkdir -p "$R_LIB_USER"
        echo "  ✅ Created $R_LIB_USER"
        FIXED_SOMETHING=true
    elif [[ -n "$R_LIB_USER" ]] && [[ -d "$R_LIB_USER" ]]; then
        echo "✅ R user library directory exists."
    fi
fi

echo ""

if [[ "$FIXED_SOMETHING" == true ]]; then
    echo "=========================================="
    echo "🎉 PERMISSIONS FIXED!"
    echo "=========================================="
    echo ""
    echo "Close this Terminal window and open a new one,"
    echo "then try your original command again."
else
    echo "=========================================="
    echo "✅ NO ISSUES FOUND"
    echo "=========================================="
    echo ""
    echo "All permissions look correct. If you're still seeing errors,"
    echo "try closing Terminal completely (Cmd+Q) and reopening it."
fi

echo ""
echo "------------------------------------------"
echo ""
echo "What's next?"
echo ""
offer_next "Re-run the full setup?" "$REPO_URL/setup.sh"
echo ""
offer_next "Make VS Code feel like RStudio?" "$REPO_URL/rstudio-feel.sh"
echo ""
