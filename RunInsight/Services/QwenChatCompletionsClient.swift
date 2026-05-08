//
//  QwenChatCompletionsClient.swift
//  RunInsight
//
//  Created by Codex on 2026-05-08.
//

import Foundation

enum QwenClientError: LocalizedError {
    case invalidResponse
    case requestFailed(String)
    case missingOutput
    case networkUnavailable(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "通义千问返回了无效响应。".localized
        case .requestFailed(let message):
            message
        case .missingOutput:
            "通义千问没有返回文本内容。".localized
        case .networkUnavailable(let message):
            String(format: NSLocalizedString("网络请求失败：%@", comment: ""), message)
        case .decodingFailed(let message):
            String(format: NSLocalizedString("通义千问响应解析失败：%@", comment: ""), message)
        }
    }
}

struct QwenChatCompletionsClient {
    var model = "qwen-plus"
    var endpoint = URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!

    func response(apiKey: String, instructions: String, input: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 60
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            QwenChatCompletionRequest(
                model: model,
                messages: [
                    QwenChatMessage(role: "system", content: instructions),
                    QwenChatMessage(role: "user", content: input)
                ],
                maxTokens: 2_000,
                temperature: 0.4
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw QwenClientError.networkUnavailable(error.localizedDescription)
        } catch {
            throw QwenClientError.networkUnavailable(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw QwenClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(QwenErrorResponse.self, from: data) {
                throw QwenClientError.requestFailed(errorResponse.error.message)
            }

            throw QwenClientError.requestFailed(String(format: NSLocalizedString("通义千问请求失败，状态码 %d。", comment: ""), httpResponse.statusCode))
        }

        let qwenResponse: QwenChatCompletionResponse
        do {
            qwenResponse = try JSONDecoder().decode(QwenChatCompletionResponse.self, from: data)
        } catch {
            throw QwenClientError.decodingFailed(error.localizedDescription)
        }

        guard let outputText = qwenResponse.choices.first?.message.content,
              !outputText.isEmpty else {
            throw QwenClientError.missingOutput
        }

        return outputText
    }
}

private struct QwenChatCompletionRequest: Encodable {
    let model: String
    let messages: [QwenChatMessage]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

private struct QwenChatMessage: Encodable {
    let role: String
    let content: String
}

private struct QwenChatCompletionResponse: Decodable {
    let choices: [QwenChoice]
}

private struct QwenChoice: Decodable {
    let message: QwenMessage
}

private struct QwenMessage: Decodable {
    let content: String
}

private struct QwenErrorResponse: Decodable {
    let error: QwenError
}

private struct QwenError: Decodable {
    let message: String
}
