import Foundation

struct CognitiveRequest: Codable {
    struct UserState: Codable { let physical_fatigue: Double; let mental_focus: Double; let consecutive_form_errors: Int }
    struct MotionMetrics: Codable { let jitter_percent_increase: Double; let velocity_percent_decrease: Double }
    struct MotionData: Codable { let exercise_id: String; let rep_count_total: Int; let current_set_target_reps: Int; let form_error_detected: String; let metrics: MotionMetrics; let uncertainty_score: Double }
    struct UserUtterance: Codable { let transcribed_text: String; let intent: String }
    struct SessionState: Codable { let time_since_last_cue_ms: Int }

    let transaction_id: String
    let timestamp_ms: Int
    let user_state: UserState
    let motion_data: MotionData
    let user_utterance: UserUtterance
    let session_state: SessionState
}

struct CognitiveResponse: Codable {
    struct GeneratedResponse: Codable { let text_to_speak: String }
    struct InferenceLog: Codable { let log_transaction_id: String; let reasoning_chain: [String] }
    let log: InferenceLog
    let response: GeneratedResponse
}

final class CognitiveClient {
    var baseURL: URL
    var bearerToken: String?

    init(baseURL: URL = URL(string: "http://localhost:8080")!, bearerToken: String? = nil) {
        self.baseURL = baseURL
        self.bearerToken = bearerToken
    }

    func infer(_ req: CognitiveRequest, completion: @escaping (CognitiveResponse?) -> Void) {
        let url = baseURL.appendingPathComponent("/cognitive-core/infer")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = bearerToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        do {
            request.httpBody = try JSONEncoder().encode(req)
        } catch {
            print("Encoding error: \(error)")
            completion(nil)
            return
        }
        URLSession.shared.dataTask(with: request) { data, resp, err in
            guard err == nil, let data = data else { completion(nil); return }
            let response = try? JSONDecoder().decode(CognitiveResponse.self, from: data)
            completion(response)
        }.resume()
    }
}
