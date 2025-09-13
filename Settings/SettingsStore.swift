import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var baseURLString: String {
        didSet { UserDefaults.standard.set(baseURLString, forKey: Self.baseURLKey) }
    }
    @Published var token: String {
        didSet { UserDefaults.standard.set(token, forKey: Self.tokenKey) }
    }

    static let baseURLKey = "cognitive_base_url"
    static let tokenKey = "cognitive_token"

    init() {
        self.baseURLString = UserDefaults.standard.string(forKey: Self.baseURLKey) ?? "http://localhost:8080"
        self.token = UserDefaults.standard.string(forKey: Self.tokenKey) ?? ""
    }

    func apply(to client: CognitiveClient) {
        if let url = URL(string: baseURLString) {
            client.baseURL = url
        }
        client.bearerToken = token.isEmpty ? nil : token
    }
}
