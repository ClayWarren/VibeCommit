import Foundation
import ArgumentParser

@main
struct VibeCommit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Offline AI Git agent for vibe coding."
    )

    @Flag(name: .shortAndLong, help: "Generate AI summary of recent commits.")
    var summarize: Bool = false

    @Flag(name: .shortAndLong, help: "Automatically commit using the generated summary.")
    var autoCommit: Bool = false

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

    // AI summary: Bridge to Python/HF for gpt-oss-20b
    func aiSummarize(commits: String) throws -> String {
        let scriptPath = "summarize.py"  // Assume in project root or adjust path
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python", scriptPath]

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()

        // Write commits to input
        if let data = commits.data(using: .utf8) {
            try inputPipe.fileHandleForWriting.write(contentsOf: data)
        }
        try inputPipe.fileHandleForWriting.close()

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AIError", code: Int(process.terminationStatus), userInfo: ["error": errorOutput])
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let summary = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw NSError(domain: "AIError", code: 1, userInfo: nil)
        }
        return summary
    }

    // Vibe check: Validate and optionally auto-commit
    func vibeCheck(summary: String) throws {
        if summary.count < 20 {
            print("Vibe check failed: Summary too short—try regenerating.")
            // TODO: Add retry logic if desired
            return
        }
        print("Vibe check passed: \(summary)")

        if autoCommit {
            let confirm = readLine(prompt: "Auto-commit with this summary? (y/n): ")
            if confirm?.lowercased() == "y" {
                try shell("git add .")
                try shell("git commit -m '\(summary)'")
                print("Committed successfully!")
            } else {
                print("Auto-commit canceled.")
            }
        } else {
            print("Ready to commit manually: git commit -m '\(summary)'")
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

// Extension for readLine with prompt (for confirmation)
extension String {
    static func readLine(prompt: String) -> String? {
        print(prompt, terminator: "")
        return Swift.readLine()
    }
}