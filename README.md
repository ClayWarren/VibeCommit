# VibeCommit 🚀

Offline AI agent for Git workflows—voice-dictated commits, smart summaries, and agentic checks. Built in Swift for macOS devs who vibe code without cloud BS.

Inspired by agentic engineering: No more stalled prompts or manual loops. Just dictate "Commit vibe: fixed auth bug," and it generates summaries with local gpt-oss-20b, verifies diffs, and pushes if ready.

## ✨ Features
- 📝 Auto-generate commit messages from recent commits (last 10) using local AI (gpt-oss-20b).
- 🔍 Vibe checks: Validates summary length and optionally auto-commits.
- 🎤 Voice dictation integration with macOS native Speech framework (transcribe vibes hands-free).
- ⚙️ Extensible CLI with flags for mock mode (testing without AI) and auto-commit.
- Zero config: Runs in any Git repo.

## 🚀 Quick Start
1. Clone: `git clone https://github.com/ClayWarren/VibeCommit.git`
2. Build: `swift build`
3. Run examples (in a Git repo):
   - Basic summary: `swift run VibeCommit --summarize`
   - With voice input: `swift run VibeCommit --summarize --voice`
   - Mock mode for testing: `swift run VibeCommit --summarize --voice --mock`
   - Auto-commit: `swift run VibeCommit --summarize --autoCommit` (prompts for confirmation)

### Setup Notes
- **AI Features**: Install gpt-oss-20b via Hugging Face for real summaries (skip with `--mock`). Requires Python 3+ with `transformers` library: `pip install transformers`. The model will auto-download on first use.
- **Voice Permissions (macOS)**: On first run with `--voice`, grant microphone and speech recognition access via System Settings > Privacy & Security. If no prompt appears, reset with `tccutil reset Microphone` and `tccutil reset SpeechRecognition` in Terminal.
- **Dependencies**: Swift 6.2+, Git, Python for AI bridge.

## 📅 Roadmap
- Phase 1: Core CLI with Git hooks and basic AI summaries. ✅
- Phase 2: Voice input and agent completions. ✅
- Future: Integrations (visual diffs, MCP for Claude fallback if local fails), full Git push automation.

Contributions welcome! See Issues for "good first issue" tags.

MIT © 2025 Clay Warren
