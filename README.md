# OPTCG — One Piece TCG Digital
### Setup Guide for macOS

---

## What's in this project

```
optcg/
├── CLAUDE.md          ← Read this first — every agent reads this before touching code
├── PRD.md             ← Product requirements
├── ARCHITECTURE.md    ← Full technical architecture
├── AGENTS.md          ← Parallel build plan (13 agents across 5 waves)
├── project.godot      ← Godot 4 project file
├── data/cards/        ← OP01.json card database (Agent 1 fills this)
├── scenes/            ← All Godot scenes (agents fill these)
├── scripts/           ← All GDScript files (stubs ready, agents implement)
└── api/               ← Cloud Run backend API (Node.js, Agent 6)
```

All GDScript files are stubbed with correct class names, signals, type hints,
and `# TODO: Agent X` comments. Claude Code fills them in one agent at a time.

---

## Step 1 — Install everything (run once)

Open Terminal (Cmd+Space → type "Terminal" → Enter) and run each block:

```bash
# Install Homebrew (macOS package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
# Install Git
brew install git
```

```bash
# Install VS Code
brew install --cask visual-studio-code
```

```bash
# Install Godot 4
brew install --cask godot
```

```bash
# Install Claude Code (native installer — no Node.js needed)
curl -fsSL https://claude.ai/install.sh | bash
```

```bash
# Close and reopen Terminal, then verify Claude Code installed
claude --version
```

---

## Step 2 — Open the project in VS Code

```bash
# Navigate to where you extracted this folder (adjust path if needed)
cd ~/Desktop/optcg

# Open in VS Code
code .
```

---

## Step 3 — Install VS Code extensions

When VS Code opens you'll see a notification: **"Install recommended extensions?"**
Click **Install All**. This installs:

- **godot-tools** — GDScript language support, autocomplete, debugger
- **Prettier** — code formatting
- **Git Graph** — visual git history

If the notification doesn't appear:
1. Press `Cmd+Shift+X` to open Extensions
2. Search `godot-tools` → Install
3. Search `Git Graph` → Install

---

## Step 4 — Connect VS Code to Godot

1. Open **Godot 4** (Applications → Godot, or `open -a Godot`)
2. Click **Import** → navigate to `optcg/project.godot` → Open
3. The project loads (ignore missing scene warnings — stubs aren't complete yet)
4. In Godot: **Editor → Editor Settings → Network → Language Server**
   - Ensure **Remote Port** is `6005`
5. In VS Code the godot-tools extension connects automatically

---

## Step 5 — Start Claude Code

```bash
# Make sure you're in the project folder
cd ~/Desktop/optcg

# Start Claude Code
claude
```

On first run it opens your browser to authenticate with your Anthropic account.
Log in → confirm access → return to Terminal.

**You need a paid Anthropic account (Claude Pro $20/month minimum).**
Claude Code does not work on the free plan.

---

## Step 6 — Build Agent 1 (your first prompt)

Once Claude Code is running in Terminal, type:

```
Read CLAUDE.md. Then implement Agent 1 completely:
- Fill data/cards/OP01.json with all 121 OP01 Romance Dawn cards
- Implement _parse_card() in scripts/autoloads/CardDatabase.gd
- Verify all CardData enums in scripts/data/CardData.gd are correct
Check the Definition of Done checklist in AGENTS.md before finishing.
```

Claude Code will read all your project files, understand the architecture,
and write directly into your project without copy-pasting.

---

## Step 7 — Test in Godot after each agent

After each agent completes:
1. Switch to Godot
2. Press `F5` or click the Play button
3. Check the Output panel for errors
4. If errors appear — paste them back into Claude Code to fix

---

## Ongoing workflow

Every new Claude Code session:
```bash
cd ~/Desktop/optcg
claude
```

First message every session:
```
Read CLAUDE.md. [Then give your instruction for the current agent]
```

CLAUDE.md gives Claude Code full project context in seconds.
Without it, Claude Code doesn't know your architecture, rules, or conventions.

---

## Agent build order

```
Wave 1 (start all at once — no dependencies):
  Agent 1  — Card Database (OP01.json + CardData.gd)
  Agent 2  — GameState singleton
  Agent 6  — Cloud Run API + PostgreSQL schema

Wave 2 (after Wave 1):
  Agent 3  — TurnManager
  Agent 5  — Card rendering + CardView
  Agent 7  — Firebase Auth

Wave 3 (after Wave 2):
  Agent 4  — BattleResolver + EffectQueue + DamageHandler
  Agent 8  — Board UI + Zones
  Agent 9  — Deck Builder UI

Wave 4 (after Wave 3):
  Agent 10 — AI Opponent
  Agent 11 — KeywordHandler + WinConditionChecker
  Agent 12 — Online Multiplayer

Wave 5 (after Wave 4):
  Agent 13 — Integration + Full game loop
```

In practice, run one agent per Claude Code session.
Each session: `claude` → read CLAUDE.md → implement one agent → test in Godot.

---

## Troubleshooting

**`claude: command not found`**
```bash
source ~/.zshrc
# If still not found:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Godot shows errors about missing scenes**
Normal at this stage — scene files are stubs. Ignore until Agent 8.

**godot-tools can't connect to Godot**
Make sure Godot is open and the project is loaded.
Check Editor Settings → Network → Language Server Port = 6005.

**Claude Code authentication fails**
```bash
claude logout
claude
# Follow the browser prompt again
```

---

*OPTCG v1.0 — VaultAutomation (Pty) Ltd*
