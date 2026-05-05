//
//  OpenAIResponsesClient.swift
//  RunInsight
//
//  Created by Codex on 2026-05-05.
//

import Foundation

enum OpenAIClientError: LocalizedError {
    case invalidResponse
    case requestFailed(String)
    case missingOutput
    case networkUnavailable(String)
    case decodingFailed(String)
    case incomplete(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "OpenAI 返回了无效响应。"
        case .requestFailed(let message):
            message
        case .missingOutput:
            "OpenAI 没有返回文本内容。"
        case .networkUnavailable(let message):
            "网络请求失败：\(message)"
        case .decodingFailed(let message):
            "OpenAI 响应解析失败：\(message)"
        case .incomplete(let reason):
            "OpenAI 这次没有生成完整回复：\(reason)"
        }
    }
}

struct OpenAIResponsesClient {
    var model = "gpt-5-mini"

    func response(apiKey: String, instructions: String, input: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.timeoutInterval = 60
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            OpenAIResponseRequest(
                model: model,
                instructions: instructions,
                input: input,
                maxOutputTokens: 2_000,
                reasoning: OpenAIReasoning(effort: "minimal")
            )
        )

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            throw OpenAIClientError.networkUnavailable(error.localizedDescription)
        } catch {
            throw OpenAIClientError.networkUnavailable(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIClientError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIClientError.requestFailed(errorResponse.error.message)
            }

            throw OpenAIClientError.requestFailed("OpenAI request failed with status \(httpResponse.statusCode).")
        }

        let openAIResponse: OpenAIResponse
        do {
            openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        } catch {
            throw OpenAIClientError.decodingFailed(error.localizedDescription)
        }

        if openAIResponse.status == "incomplete" {
            throw OpenAIClientError.incomplete(openAIResponse.incompleteDetails?.reason ?? "unknown")
        }

        if let responseError = openAIResponse.error {
            throw OpenAIClientError.requestFailed(responseError.message)
        }

        if let outputText = openAIResponse.outputText, !outputText.isEmpty {
            return outputText
        }

        let fallbackText = openAIResponse.output
            .flatMap { $0.content ?? [] }
            .compactMap { content in
                content.text ?? content.refusal
            }
            .joined(separator: "\n")

        guard !fallbackText.isEmpty else {
            throw OpenAIClientError.missingOutput
        }

        return fallbackText
    }
}

private struct OpenAIResponseRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
    let maxOutputTokens: Int
    let reasoning: OpenAIReasoning

    enum CodingKeys: String, CodingKey {
        case model
        case instructions
        case input
        case maxOutputTokens = "max_output_tokens"
        case reasoning
    }
}

private struct OpenAIReasoning: Encodable {
    let effort: String
}

private struct OpenAIResponse: Decodable {
    let status: String?
    let error: OpenAIError?
    let incompleteDetails: OpenAIIncompleteDetails?
    let outputText: String?
    let output: [OpenAIOutputItem]

    enum CodingKeys: String, CodingKey {
        case status
        case error
        case incompleteDetails = "incomplete_details"
        case outputText = "output_text"
        case output
    }
}

private struct OpenAIOutputItem: Decodable {
    let content: [OpenAIContentItem]?
}

private struct OpenAIContentItem: Decodable {
    let text: String?
    let refusal: String?
}

private struct OpenAIErrorResponse: Decodable {
    let error: OpenAIError
}

private struct OpenAIError: Decodable {
    let message: String
}

private struct OpenAIIncompleteDetails: Decodable {
    let reason: String?
}
