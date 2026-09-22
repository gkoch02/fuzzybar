import SwiftUI
import UniformTypeIdentifiers

/// A personality in the picker: one of ours, or one imported from a file.
enum PersonalityChoice: Hashable {
    case builtIn(Personality)
    case custom(UUID)
}

/// What the last import or save said, shown under the personality example.
struct PersonalityMessage: Equatable {
    var text: String
    var isError = false
}

/// Preferences' personality picker, with importing and saving templates.
struct PersonalitySection: View {
    @EnvironmentObject private var clock: Clock
    @Binding var message: PersonalityMessage?
    @State private var importing = false
    @State private var exporting = false

    private var choice: Binding<PersonalityChoice> {
        Binding(
            get: { clock.customPersonalityID.map(PersonalityChoice.custom) ?? .builtIn(clock.personality) },
            set: { new in
                message = nil
                switch new {
                case let .builtIn(personality):
                    clock.customPersonalityID = nil
                    clock.personality = personality
                case let .custom(id):
                    clock.customPersonalityID = id
                }
            }
        )
    }

    /// The active personality as a file to start from. Spoken and Vague have
    /// no slot table, so they hand out Classic's instead.
    private var template: CustomPersonality {
        clock.activeCustom ?? clock.personality.template ?? Personality.classic.template!
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("Personality", selection: choice) {
                ForEach(Personality.allCases) { Text($0.title).tag(PersonalityChoice.builtIn($0)) }
                if !clock.customPersonalities.isEmpty {
                    Divider()
                    ForEach(clock.customPersonalities) { Text($0.name).tag(PersonalityChoice.custom($0.id)) }
                }
            }
            Text(clock.activeCustom == nil ? clock.personality.note : "Your own, imported from a file.")
                .font(.caption).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(clock.phrase(hour: 20, minute: 40))
                .font(.callout.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                .accessibilityLabel("Example at 8:40 pm")
            HStack {
                Button("Import…") { importing = true }
                Button("Save as Template…") { exporting = true }
                Spacer(minLength: 0)
                if let custom = clock.activeCustom {
                    Button("Remove") {
                        clock.removePersonality(id: custom.id)
                        message = PersonalityMessage(text: "Removed \(custom.name).")
                    }
                }
            }
            .controlSize(.small)
            if let message {
                Text(message.text)
                    .font(.caption).foregroundStyle(message.isError ? AnyShapeStyle(.red) : AnyShapeStyle(.secondary))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fileImporter(isPresented: $importing, allowedContentTypes: [CustomPersonality.contentType, .json]) { result in
            switch result {
            case let .success(url): message = clock.importPersonality(from: url)
            case let .failure(error): message = PersonalityMessage(text: error.localizedDescription, isError: true)
            }
        }
        .fileExporter(isPresented: $exporting, document: PersonalityFile(data: template.encoded()),
                      contentType: CustomPersonality.contentType, defaultFilename: template.name) { result in
            if case let .failure(error) = result {
                message = PersonalityMessage(text: error.localizedDescription, isError: true)
            } else {
                message = PersonalityMessage(text: "Saved. Edit it in any text editor, then import it.")
            }
        }
    }
}

/// A .fuzzybar file for the save panel.
struct PersonalityFile: FileDocument {
    static let readableContentTypes = [CustomPersonality.contentType]
    var data: Data

    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

extension Clock {
    /// Reads, checks and imports a personality file, and says how it went
    /// in words for Preferences. Import and drag-and-drop both land here.
    func importPersonality(from url: URL) -> PersonalityMessage {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let personality = try CustomPersonality.decode(try Data(contentsOf: url))
            let replaced = importPersonality(personality)
            var text = replaced ? "Updated \(personality.name)." : "Imported \(personality.name)."
            let longest = personality.longestReading
            if longest.count > SpecialTime.maxLength {
                text += " Its longest reading, \"\(longest)\", is \(longest.count) characters; past \(SpecialTime.maxLength) it can end up behind the notch."
            }
            return PersonalityMessage(text: text)
        } catch let error as CustomPersonality.ImportError {
            return PersonalityMessage(text: error.errorDescription ?? "That file couldn't be imported.", isError: true)
        } catch {
            return PersonalityMessage(text: "Couldn't read \(url.lastPathComponent).", isError: true)
        }
    }
}
