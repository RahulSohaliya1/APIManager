//
//  APIManager.swift
//  APIPractice
//
//  Created by DREAMWORLD on 30/10/25.
//
//
import Foundation

final class APIManager {
    // MARK: - Properties
    
    static let shared = APIManager()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    // Configuration
    var baseURL: URL
    var defaultHeaders: [String: String]
    var timeoutInterval: TimeInterval
    var retryLimit: Int
    
    // MARK: - Initialization
    
    init(
        baseURL: URL = URL(string: "https://api.restful-api.dev/")!,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        defaultHeaders: [String: String] = [:],
        timeoutInterval: TimeInterval = 60,
        retryLimit: Int = 3
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
        self.defaultHeaders = defaultHeaders
        self.timeoutInterval = timeoutInterval
        self.retryLimit = retryLimit
    }
    
    // MARK: - HTTP Methods
    
    /// Performs a GET request
    func get<T: Decodable>(
        endpoint: String,
        queryParams: [String: Any]? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask? {
        let queryItems = queryParams?.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        return request(
            endpoint: endpoint,
            method: .get,
            queryItems: queryItems,
            headers: headers,
            completion: completion
        )
    }
    
    /// Performs a POST request with JSON body
    func post<T: Decodable>(
        endpoint: String,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask? {
        return request(
            endpoint: endpoint,
            method: .post,
            body: body,
            headers: headers,
            completion: completion
        )
    }
    
    /// Performs a PUT request with JSON body
    func put<T: Decodable>(
        endpoint: String,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask? {
        return request(
            endpoint: endpoint,
            method: .put,
            body: body,
            headers: headers,
            completion: completion
        )
    }
    
    /// Performs a DELETE request
    func delete<T: Decodable>(
        endpoint: String,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask? {
        return request(
            endpoint: endpoint,
            method: .delete,
            headers: headers,
            completion: completion
        )
    }
    
    // MARK: - Upload Methods
    
    /// Uploads a file with multipart/form-data
    func upload<T: Decodable>(
        endpoint: String,
        fileData: Data,
        fileName: String,
        fieldName: String = "file",
        mimeType: String = "application/octet-stream",
        parameters: [String: String] = [:],
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask? {
        // Create boundary string
        let boundary = "Boundary-\(UUID().uuidString)"
        var customHeaders = headers ?? [:]
        customHeaders["Content-Type"] = "multipart/form-data; boundary=\(boundary)"
        
        // Build URL
        let url = baseURL.appendingPathComponent(endpoint)
        
        // Create request
        var request = URLRequest(
            url: url,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: timeoutInterval
        )
        request.httpMethod = "POST"
        
        // Set headers
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        customHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Build multipart form data
        var body = Data()
        
        // Add parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }
        
        // Add file data
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n")
        
        request.httpBody = body
        
        return executeRequest(request, retryCount: 0, completion: completion)
    }
    
    // MARK: - Core Request Methods
    
    /// Generic request method that handles all HTTP methods
    private func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask? {
        // Build URL with components
        let url = baseURL.appendingPathComponent(endpoint)
        
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            completion(.failure(.invalidURL))
            return nil
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let finalURL = components.url else {
            completion(.failure(.invalidURL))
            return nil
        }
        
        // Create request
        var request = URLRequest(
            url: finalURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: timeoutInterval
        )
        request.httpMethod = method.rawValue
        
        // Set headers
        defaultHeaders.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // Set body if exists
        if let body = body {
            do {
                request.httpBody = try encoder.encode(body)
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                completion(.failure(.encodingError(error)))
                return nil
            }
        }
        
        return executeRequest(request, retryCount: 0, completion: completion)
    }
    
    /// Executes the request with retry capability
    private func executeRequest<T: Decodable>(
        _ request: URLRequest,
        retryCount: Int,
        completion: @escaping (Result<T, APIError>) -> Void
    ) -> URLSessionTask {
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                // Retry logic for network errors
                if retryCount < self.retryLimit {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.calculateRetryDelay(retryCount)) {
                        _ = self.executeRequest(request, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    completion(.failure(.invalidResponse))
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let message = self.extractErrorMessage(from: data, response: httpResponse)
                
                // Retry logic for server errors (5xx)
                if (500...599).contains(httpResponse.statusCode) && retryCount < self.retryLimit {
                    DispatchQueue.global().asyncAfter(deadline: .now() + self.calculateRetryDelay(retryCount)) {
                        _ = self.executeRequest(request, retryCount: retryCount + 1, completion: completion)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(.failure(.serverError(statusCode: httpResponse.statusCode, message: message)))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }
            
            do {
                let decoded = try self.decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(decoded))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Helper Methods
    
    private func calculateRetryDelay(_ retryCount: Int) -> TimeInterval {
        // Exponential backoff: 0.5s, 1s, 2s, etc.
        return pow(2.0, Double(retryCount)) * 0.5
    }
    
    private func extractErrorMessage(from data: Data?, response: HTTPURLResponse) -> String {
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        
        if let data = data,
           let message = String(data: data, encoding: .utf8) {
            return message
        }
        
        return HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum APIError: Error {
    case invalidURL
    case encodingError(Error)
    case networkError(Error)
    case invalidResponse
    case serverError(statusCode: Int, message: String)
    case noData
    case decodingError(Error)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Data Extensions

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
