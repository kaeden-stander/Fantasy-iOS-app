import SwiftUI

/// A fallback for when the in-app web login doesn't work. ESPN's real sign-in is a
/// Disney-hosted widget that doesn't behave predictably inside an embedded web view (it
/// often just shows the regular homepage instead of a login form), so this lets people get
/// in the reliable way third-party ESPN fantasy tools have always used: copy the two
/// session cookies out of a real logged-in browser and paste them in directly.
struct ManualCookieEntryView: View {
    @EnvironmentObject private var authManager: ESPNAuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var swidText = ""
    @State private var espnS2Text = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("""
                    On a computer, log into fantasy.espn.com in a normal browser tab. Then open \
                    developer tools (F12, or right-click → Inspect) and go to the \
                    Application/Storage tab → Cookies → espn.com. Copy the values for two \
                    cookies named SWID and espn_s2 and paste them below.
                    """)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Section("SWID") {
                    TextField("{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}", text: $swidText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section("espn_s2") {
                    TextField("Paste the espn_s2 value", text: $espnS2Text, axis: .vertical)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button("Save") {
                        save()
                    }
                    .disabled(swidText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              espnS2Text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Enter ESPN Cookies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        var swid = swidText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !swid.hasPrefix("{") { swid = "{" + swid }
        if !swid.hasSuffix("}") { swid += "}" }
        let espnS2 = espnS2Text.trimmingCharacters(in: .whitespacesAndNewlines)

        authManager.save(ESPNCredentials(swid: swid, espnS2: espnS2))
        dismiss()
    }
}
