import SwiftUI
import Speech
import AVFoundation
import Combine

struct AddQuoteView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: QuoteStore
    @Environment(\.colorScheme) private var scheme

    @State private var text = ""
    @State private var author = ""
    @State private var source = ""
    @State private var selectedColor: PastelStyle = .mint
    @State private var selectedFontStyle: FontStyle = .rounded

    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var isListening = false
    @State private var permissionError: String?

    // UI toggles so Colors / Text / Speak It share one bar
    @State private var showColorOptions = false
    @State private var showFontOptions = false
    @State private var showDictationDetails = false

    var body: some View {
        let bg = scheme == .dark ? DesignSystem.darkPaper : DesignSystem.lightPaper

        NavigationView {
            ZStack {
                bg.ignoresSafeArea()

                Form {
                    Section(header: Text("Quote")) {
                        TextField("Quote text", text: $text, axis: .vertical)
                            .lineLimit(3...6)
                    }

                    Section(header: Text("Author")) {
                        TextField("Who said it?", text: $author)
                    }

                    Section(header: Text("Source")) {
                        TextField("Where did you hear it?", text: $source)
                    }

                    Section(header: Text("Options")) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 8) {

                                Button {
                                    withAnimation { showColorOptions.toggle() }
                                } label: {
                                    Text("Colors")
                                        .frame(minWidth: 70, minHeight: 32)
                                }
                                .buttonStyle(.bordered)
                                .tint(showColorOptions ? DesignSystem.monsterPurple : .gray.opacity(0.5))

                                Button {
                                    withAnimation { showFontOptions.toggle() }
                                } label: {
                                    Text("Text")
                                        .frame(minWidth: 70, minHeight: 32)
                                }
                                .buttonStyle(.bordered)
                                .tint(showFontOptions ? DesignSystem.monsterPurple : .gray.opacity(0.5))

                                Button {
                                    handleSpeakButtonTapped()
                                    withAnimation { showDictationDetails = true }
                                } label: {
                                    HStack {
                                        Image(systemName: isListening ? "stop.circle.fill" : "mic.circle.fill")
                                        Text(isListening ? "Stop Listening" : "Speak It")
                                            .fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity, minHeight: 32)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(DesignSystem.monsterPurple)
                            }

                            if showColorOptions {
                                HStack {
                                    ForEach(PastelStyle.allCases, id: \.self) { style in
                                        Circle()
                                            .fill(color(for: style))
                                            .frame(
                                                width: style == selectedColor ? 34 : 28,
                                                height: style == selectedColor ? 34 : 28
                                            )
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        style == selectedColor ? Color.primary : .clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                            .onTapGesture { selectedColor = style }
                                    }
                                }
                                .padding(.top, 4)
                            }

                            if showFontOptions {
                                Picker("Font", selection: $selectedFontStyle) {
                                    Text("Modern").tag(FontStyle.standard)
                                    Text("Poetic").tag(FontStyle.serif)
                                    Text("Personal").tag(FontStyle.rounded)
                                }
                                .pickerStyle(.segmented)
                                .padding(.top, 4)
                            }

                            if showDictationDetails {
                                Text("Tip: Say: \"Quote. Author. Where you heard it.\"")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)

                                if !speechRecognizer.transcript.isEmpty {
                                    Text("Heard: \"\(speechRecognizer.transcript)\"")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                        .lineLimit(3)
                                }

                                if let permissionError {
                                    Text(permissionError)
                                        .font(.footnote)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Quote")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopListeningIfNeeded()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        stopListeningIfNeeded()
                        store.addQuote(
                            text: text,
                            author: author,
                            source: source,
                            colorStyle: selectedColor,
                            fontStyle: selectedFontStyle
                        )
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .tint(DesignSystem.monsterPurple)
    }

    // MARK: - Actions

    private func handleSpeakButtonTapped() {
        if isListening {
            // Stop listening and apply the transcript to fields
            speechRecognizer.stopTranscribing()
            isListening = false
            applyTranscriptToFields()
        } else {
            // Start listening (request permission if needed)
            permissionError = nil
            speechRecognizer.requestAuthorizationIfNeeded { granted in
                if granted {
                    speechRecognizer.reset()
                    speechRecognizer.startTranscribing()
                    DispatchQueue.main.async {
                        isListening = true
                    }
                } else {
                    DispatchQueue.main.async {
                        permissionError = "Speech permission is not granted. You can enable it in Settings."
                    }
                }
            }
        }
    }

    private func stopListeningIfNeeded() {
        if isListening {
            speechRecognizer.stopTranscribing()
            isListening = false
        }
    }

    // Current simple parser
    private func applyTranscriptToFields() {
        var raw = speechRecognizer.transcript

        raw = raw
            .replacingOccurrences(of: "“", with: "")
            .replacingOccurrences(of: "”", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !raw.isEmpty else { return }

        var parts = raw
            .split(separator: ".")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if parts.indices.contains(1) {
            let lower = parts[1].lowercased()
            if lower.hasPrefix("by ") {
                parts[1] = String(parts[1].dropFirst(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if parts.indices.contains(0) {
            text = parts[0]
        }
        if parts.indices.contains(1) {
            author = parts[1]
        }
        if parts.indices.contains(2) {
            source = parts[2]
        }
    }

    // MARK: - Helpers

    private func color(for style: PastelStyle) -> Color {
        switch style {
        case .mint:   return Color.mint.opacity(0.7)
        case .blush:  return Color.pink.opacity(0.7)
        case .lilac:  return Color.purple.opacity(0.6)
        case .sky:    return Color.blue.opacity(0.5)
        case .peach:  return Color.orange.opacity(0.6)
        case .butter: return Color.yellow.opacity(0.6)
        }
    }
}

// MARK: - Speech Recognizer Helper

final class SpeechRecognizer: NSObject, ObservableObject {
    @Published var transcript: String = ""

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAuthorizationIfNeeded(completion: @escaping (Bool) -> Void) {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized)
                }
            }
        default:
            completion(false)
        }
    }

    func startTranscribing() {
        guard let recognizer, recognizer.isAvailable else {
            print("Speech recognizer not available")
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure audio session:", error)
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine couldn't start:", error)
            return
        }

        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if let error {
                print("Recognition error:", error)
                self.stopTranscribing()
            } else if result?.isFinal == true {
                self.stopTranscribing()
            }
        }
    }

    func stopTranscribing() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()

        request = nil
        task = nil
    }

    func reset() {
        transcript = ""
    }
}
