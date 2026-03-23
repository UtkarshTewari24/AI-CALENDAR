import Foundation
#if canImport(UIKit)
import UIKit
#endif

struct VerificationResult: Codable {
    let verified: Bool
    let confidence: Double
    let reason: String
}

enum VerificationService {

    private static let systemPrompt = """
    You are a strict but fair task completion verifier. You will be given a task description, \
    a user-defined definition of what counts as done, and proof submitted by the user. \
    Determine whether the proof genuinely demonstrates task completion. Be strict — \
    partial or ambiguous proof should be marked as UNVERIFIED. Respond with ONLY a JSON object:
    {
      "verified": true | false,
      "confidence": 0.0-1.0,
      "reason": "brief explanation"
    }
    """

    static func verify(
        task: AxiomTask,
        proofText: String?,
        proofImage: Data?
    ) async throws -> VerificationResult {
        var userContent = """
        Task: \(task.title)
        Description: \(task.taskDescription)
        What counts as done: \(task.whatCountsAsDone)
        """

        if let text = proofText, !text.isEmpty {
            userContent += "\n\nUser's text proof: \(text)"
        }

        var messages: [OpenAIMessage] = [.system(systemPrompt)]

        if let imageData = proofImage {
            let base64 = imageData.base64EncodedString()
            messages.append(.userWithImage(text: userContent, imageBase64: base64))
        } else {
            messages.append(.user(userContent))
        }

        let response = try await OpenAIService.sendChatCompletion(
            messages: messages,
            temperature: 0.3,
            responseFormat: ["type": "json_object"]
        )

        guard let content = response.firstMessageContent,
              let data = content.data(using: .utf8) else {
            throw OpenAIServiceError.emptyResponse
        }

        return try JSONDecoder().decode(VerificationResult.self, from: data)
    }

    #if canImport(UIKit)
    static func compressImage(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1.0)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized?.jpegData(compressionQuality: 0.8)
    }
    #endif
}
