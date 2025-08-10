import Foundation
import ArgumentParser
import AVFoundation
import AVFAudio
import Speech

enum VibeCommitError: Error, LocalizedError {
    case fileNotFound(String)
    case aiExecutionFailed(Int, String)
    case invalidOutput
    case permissionDenied(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let details):
            return "File not found: \(details)"
        case .aiExecutionFailed(let code, let details):
            return "AI execution failed with code \(code): \(details)"
        case .invalidOutput:
            return "Invalid AI output"
        case .permissionDenied(let details):
            return "Permission denied: \(details)"
        }
    }
}

@main
struct VibeCommit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Offline AI Git agent for vibe coding."
    )

    @Flag(name: .shortAndLong, help: "Generate AI summary of recent commits.")
    var summarize: Bool = false

    @Flag(name: .shortAndLong, help: "Automatically commit using the generated summary.")
    var autoCommit: Bool = false

    @Flag(name: .shortAndLong, help: "Use mock summary instead of real AI (for testing).")
    var mock: Bool = false

    @Flag(name: .shortAndLong, help: "Use voice dictation to input a vibe for the summary.")
    var voice: Bool = false

    mutating func run() throws {
        guard isGitRepo() else {
            print("Error: Not a Git repository.")
            return
        }

        if summarize {
            do {
                let commits = try getGitLog()
                var vibe = ""
                if voice {
                    let analyzer = SpeechAnalyzer()
                    vibe = try analyzer.dictate()
                    print("Transcribed vibe: \(vibe)")
                }
                let summary = try aiSummarize(commits: commits, vibe: vibe)
                print("AI Summary:\n\(summary)")
                try vibeCheck(summary: summary)
            } catch let error as VibeCommitError {
                print("Error: \(error.localizedDescription)")
                switch error {
                case .fileNotFound(let details),
                     .permissionDenied(let details):
                    print("Details: \(details)")
                case .aiExecutionFailed(_, let details):
                    print("Details: \(details)")
                case .invalidOutput:
                    print("Details: Invalid AI output.")
                }
            } catch {
                print("Unexpected error: \(error.localizedDescription)")
            }
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

    // AI summary: Bridge to Python/HF for gpt-oss-20b, or mock, with optional vibe
    func aiSummarize(commits: String, vibe: String) throws -> String {
        if mock {
            return "Mock summary from commits with vibe '\(vibe)': Enhanced features and fixed bugs based on recent changes. (Commits: \(commits.prefix(50))...)"
        }

        guard let scriptURL = Bundle.main.url(forResource: "summarize", withExtension: "py") else {
            throw VibeCommitError.fileNotFound("summarize.py not found in bundle. Check if it's in Sources/VibeCommit/ and Package.swift has .copy(\"summarize.py\"). Run rm -rf .build && swift build to clean.")
        }
        let scriptPath = scriptURL.path
        print("Debug: Using script at \(scriptPath)")  // For debugging path

        let prompt = vibe.isEmpty ? commits : "\(commits)\nVibe: \(vibe)"

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["python3", scriptPath]  // Use python3 for macOS compatibility

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        try process.run()

        // Write prompt to input
        if let data = prompt.data(using: .utf8) {
            try inputPipe.fileHandleForWriting.write(contentsOf: data)
        }
        try inputPipe.fileHandleForWriting.close()

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw VibeCommitError.aiExecutionFailed(Int(process.terminationStatus), errorOutput)
        }

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard let summary = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw VibeCommitError.invalidOutput
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
            print("Auto-commit with this summary? (y/n): ", terminator: "")
            let confirm = Swift.readLine()?.lowercased()
            if confirm == "y" {
                _ = try shell("git add .")
                _ = try shell("git commit -m '\(summary)'")
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

// SpeechAnalyzer for voice dictation (adapted from Apple docs)
class SpeechAnalyzer: NSObject, SFSpeechRecognizerDelegate {
    private let audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) // Change locale as needed
    private var transcribedText = ""

    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    func dictate() throws -> String {
        try requestSpeechPermissions()
        try requestMicPermissions()
        startRecognition()
        print("Listening for voice... Press Enter to stop.")

        _ = readLine()
        stopRecognition()

        return transcribedText
    }

    private func requestSpeechPermissions() throws {
        var permissionGranted = false
        var done = false

        SFSpeechRecognizer.requestAuthorization { status in
            permissionGranted = status == .authorized
            done = true
        }

        let timeoutDate = Date(timeIntervalSinceNow: 10.0) // Prevent infinite loop
        while !done && Date() < timeoutDate {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        if !done {
            throw VibeCommitError.permissionDenied("Speech recognition permission request timed out.")
        }

        if !permissionGranted {
            throw VibeCommitError.permissionDenied("Speech recognition permission denied.")
        }
    }

    private func requestMicPermissions() throws {
        var permissionGranted = false
        var done = false

        AVAudioApplication.requestRecordPermission { granted in
            permissionGranted = granted
            done = true
        }

        let timeoutDate = Date(timeIntervalSinceNow: 10.0) // Prevent infinite loop
        while !done && Date() < timeoutDate {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        }

        if !done {
            throw VibeCommitError.permissionDenied("Microphone permission request timed out.")
        }

        if !permissionGranted {
            throw VibeCommitError.permissionDenied("Microphone permission denied.")
        }
    }

    private func startRecognition() {
        inputNode = audioEngine.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true // For live updates

        guard let recognitionRequest = recognitionRequest, let inputNode = inputNode else {
            print("Unable to start recognition.")
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcribedText = result.bestTranscription.formattedString
                print("Live: \(self.transcribedText)") // Print live updates
            }
            if error != nil || result?.isFinal == true {
                self.stopRecognition()
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, time in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            print("Couldn't start audio engine: \(error.localizedDescription)")
            print("If microphone access denied, grant permission in System Settings > Privacy & Security > Microphone for Terminal/Xcode.")
            stopRecognition()
        }
    }

    private func stopRecognition() {
        audioEngine.stop()
        inputNode?.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
    }

    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if !available {
            print("Speech recognition unavailable.")
            stopRecognition()
        }
    }
}