# VibeCommit 🚀

Offline AI agent for Git workflows—voice-dictated commits, smart summaries, and agentic checks. Built in Swift for macOS devs who vibe code without cloud BS.

Inspired by agentic engineering (shoutout to @steipete's threads): No more stalled prompts or manual loops. Just dictate "Commit vibe: fixed auth bug," and it generates summaries with local gpt-oss-20b, verifies diffs, and pushes if ready.

## ✨ Features (MVP)
- 📝 Auto-generate commit messages from diffs using local AI (gpt-oss-20b).
- 🔍 Vibe checks: Ensures tasks complete (e.g., "Did I write code? Verify output").
- 🎤 Voice dictation integration (coming soon: Wispr Flow or macOS native).
- ⚙️ Extensible 
- Zero config: Runs in any Git repo via CLI.

## 🚀 Quick Start
1. Clone: `git clone https://github.com/ClayWarren/VibeCommit.git`
2. Build: `swift build`
3. Run: `./.build/debug/VibeCommit --summarize` (in a Git repo)

Install gpt-oss-20b separately via Hugging Face for AI features.

## 📅 Roadmap
- Phase 1: Core CLI with Git hooks and basic AI summaries.
- Phase 2: Voice input and agent completions.
- Future: Integrations (visual diffs, MCP for Claude fallback if local fails).

Contributions welcome! See Issues for "good first issue" tags.

MIT © 2025 Clay Warren
