import Foundation
import ArgumentParser

@main
struct VibeCommit: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "Offline AI Git agent for vibe coding."
    )

    @Flag(name: .shortAndLong, help: "Generate AI summary of recent commits.")
    var summarize: Bool = false

    mutating func run() throws {
        guard isGitRepo() else {
            print("Error: Not a Git repository.")
            return
        }

        if summarize {
            let commits = try getGitLog()
            let summary = try aiSummarize(commits: commits)
            print("AI Summary:\n\(summary)")
            try vibeCheck(summary: summary)
        } else {
            print("Run with --summarize to get started.")
        }
    }

    // Check if current dir is a Git repo
    func isGitRepo() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["rev-parse", "--is-inside-work-tree"]
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // Get recent git log (last 10 commits)
    func getGitLog() throws -> String {
        let output = try shell("git log -n 10 --pretty=format:'%h %s'")
        return output
    }

    // Placeholder for AI summary: Bridge to Python/HF for gpt-oss-20b
    func aiSummarize(commits: String) throws -> String {
        // TODO: Implement real inference. For now, mock or exec Python.
        // Example: execSync(`python summarize.py "${commits}"`)
        // Where summarize.py loads model: from transformers import pipeline; summarizer = pipeline('summarization', model='openai/gpt-oss-20b')
        return "Mock AI Summary: Enhanced features with bug fixes. (Integrate gpt-oss-20b here!)"
    }

    // Vibe check: Simple validation (expand to full agent logic)
    func vibeCheck(summary: String) throws {
        // Example: Verify if summary is non-empty and could form a valid commit
        if summary.isEmpty {
            print("Vibe check failed: No summary generated.")
        } else {
            print("Vibe check passed: Ready to commit?")
            // TODO: Auto-commit option
        }
    }

    // Helper to run shell commands
    func shell(_ command: String) throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}