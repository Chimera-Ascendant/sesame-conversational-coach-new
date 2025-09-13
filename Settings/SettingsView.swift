import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: SettingsStore

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Cognitive Core Endpoint")) {
                    TextField("Base URL", text: $store.baseURLString)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    SecureField("Bearer Token (optional)", text: $store.token)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(store: SettingsStore())
    }
}
