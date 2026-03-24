# 🚀 The R-Researcher's AI Power-Pack

If you are a researcher stuck in RStudio and feeling left behind by the AI Agent revolution, this is for you. This repository transforms a factory-fresh MacBook into a high-performance AI coding environment in about 10 minutes.

No technical knowledge required.

---

## 🔒 What Am I Installing? Is This Safe?

Everything the setup script installs is mainstream, open-source or vendor-backed software used by millions of developers and researchers worldwide. Nothing obscure, nothing experimental. AI agents are a different story – see the disclaimer in that section below.

| Tool | Popularity | In a nutshell |
|------|-----------|---------------|
| **Homebrew** | 92% of Mac developers | App Store for the Terminal |
| **R** | ~2 million users | You already know this one |
| **VS Code** | ~35 million monthly users | The code editor that ate the world |
| **Node.js** | 98% of Fortune 500 | Makes AI agents run |

The setup script itself is open-source – you can [read every line of it](setup.sh) before running it.

---

## 📦 How Long Will This Take? How Much Space?

On a MacBook M2 (2022) with a typical Berlin apartment Wi-Fi (~40 Mbps): about **10-15 minutes** and **~3 GB** of disk space.

---

## ⚡ The 3-Step Setup

### Step 1: Open Terminal

Press `Cmd + Space`, type **Terminal**, and hit **Enter**. A window with a blinking cursor appears – that's your command line.

### Step 2: Paste This Command

Copy the entire block below, paste it into the Terminal window, and hit **Enter**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh)"
```

Your Mac will ask for your password once.

> 💡 **You won't see dots or stars when you type your password** – this is normal! macOS hides it completely so nobody can even count the characters. Type it confidently and hit Enter.

### Step 3: Lean Back

The script will show you what it's doing at every step. When it says `🎉 SETUP COMPLETE`, you're done.

---

## 🤖 Install Your AI Agent

Once the setup finishes, choose your "Pilot." All three are made by major tech companies (Anthropic, Google, Amazon) – these aren't hobby projects. That said, AI coding agents are a new category of software. They can read and modify files on your machine, which is the whole point – but it means you should understand what you're granting access to. Each agent asks for permission before taking actions, and none of them send your files anywhere without your involvement. You can install one or all three – they don't conflict, and you can switch between them freely (useful if you hit the free tier limit on one).

### Claude Code (by Anthropic) – Best for Complex R Code

Strongest at structured reasoning, debugging statistical models, and writing multi-step analysis scripts from scratch.

```bash
npm install -g @anthropic-ai/claude-code
```

Cost: No free tier. Starts at $20/mo. (As of March 2026.)

### Gemini CLI (by Google) – Best Free Option

Generous free tier. Can process very large files and entire project folders at once.

```bash
npm install -g @google/gemini-cli
```

Cost: Generous free tier. Paid option starts at ~$20/mo. (As of March 2026.)

### Kiro CLI (by Amazon/AWS) – Best for Spec-Driven Development

Generates code from structured specs and requirements. Strong AWS integration.

```bash
npm install -g kirocli
```

Cost: Free tier with 50 credits/month. Paid option starts at $20/mo. (As of March 2026.)

> 💡 Not sure which one? Start with **Gemini CLI** – it's free and gets you going immediately.

---

## 🎹 Make VS Code Feel Like RStudio

VS Code is more powerful than RStudio, but it feels different out of the box. The command below makes it feel much closer.

**What it does (before you paste it):**

1. Makes plots appear in a side panel, similar to RStudio's Plots tab (installs the `httpgd` R package)
2. Brings back `Alt + -` for the `<-` assignment arrow (installs the R Shortcuts extension)
3. Makes `Cmd + Enter` run the current line and jump to the next one, just like RStudio
4. Brings back `Ctrl + Shift + M` for the pipe operator (`|>`)
5. Turns on rainbow-colored brackets so you can see which parentheses belong together in nested code
6. Shows your loaded variables in a side panel, like RStudio's Environment tab (top-right)
7. Keeps track of your R session so VS Code knows what's in memory
8. Switches to a clean, light theme (VS Code defaults to dark – RStudio doesn't)
9. Removes visual clutter: welcome tab, minimap, breadcrumb navigation

**Paste this into Terminal:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/rstudio-feel.sh)"
```

After it finishes, **restart VS Code** (`Cmd + Q`, then reopen) to activate everything.

---

## 📁 Start a New Project (Optional)

If you want to create a clean, organized folder for a new analysis, this script sets one up for you. It asks for a project name (use kebab-case, like `my-first-repo`), then creates a ready-to-go structure with folders for data, scripts, and output – plus some starter R files.

**What you get:**

```
my-project/
├── data/
│   ├── raw/          ← put your original CSVs, Excel files, etc. here
│   └── processed/    ← cleaned data goes here
├── output/
│   ├── figures/      ← plots and visualizations
│   └── tables/       ← exported tables
├── src/
│   ├── 01_load_data.R
│   ├── 02_clean_data.R
│   └── 03_analysis.R
└── README.md
```

The starter scripts are templates – open them, edit the commented-out lines, and you're running.

**Paste this into Terminal:**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/new-project.sh)"
```

---

## 🚑 Troubleshooting (Don't Panic)

Most of these issues are now handled automatically by the scripts. If something still goes wrong:

**"Everything is stuck / frozen."**

If nothing has happened for more than 10 minutes, press `Ctrl + C` a few times until the cursor comes back. Then run the command again. Every script is safe to re-run.

**"VS Code doesn't recognize R / no autocomplete."**

This should be set up automatically by `rstudio-feel.sh`. If it still doesn't work, open VS Code, press `Cmd + Shift + P`, type `R: Select R Binary`, and make sure it points to `/usr/local/bin/R` (Intel Mac) or `/opt/homebrew/bin/R` (Apple Silicon M1/M2/M3/M4).

**"I see errors about 'permission denied'."**

The setup script handles the most common permission issues preemptively. If you still hit one, paste this command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/fix-permissions.sh)"
```

Then close Terminal, reopen it, and try the original command again.

---

## 🧪 Verification

The setup script runs a verification check automatically at the end. If you want to re-check later, paste this into Terminal:

```bash
echo "--- Checking installations ---"
{ brew --version | head -1 && echo "✅ Homebrew"; } || echo "❌ Homebrew"
{ R --version 2>/dev/null | head -1 && echo "✅ R"; } || echo "❌ R"
{ node --version && echo "✅ Node.js"; } || echo "❌ Node.js"
{ code --version 2>/dev/null | head -1 && echo "✅ VS Code"; } || echo "❌ VS Code"
```

Every line should show a version number and a ✅.

---

## 🗑 Uninstall Everything

If you want to reverse the setup — partially or completely — use the uninstall script. It walks you through every component one by one and asks before removing anything. If something was already on your Mac before you ran `setup.sh`, just say "n" to keep it.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/uninstall.sh)"
```

The script covers, in this order:

1. **AI agents** (Claude Code, Gemini CLI, Kiro CLI)
2. **VS Code extensions** (R extension, R Shortcuts)
3. **VS Code settings & keybindings** added by `rstudio-feel.sh`
4. **R packages** (`languageserver`, `httpgd`, `here`)
5. **Node.js**
6. **VS Code** (with optional user data cleanup)
7. **R** (with optional user library cleanup)
8. **Homebrew** (warns you if other tools still depend on it)
9. **Shell config lines** added to `~/.zshrc` and `~/.zprofile`

After the uninstall finishes, close Terminal (`Cmd + Q`) and open a new one.
