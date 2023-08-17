//
//  APIClient.swift
//  SwiftConcurrencyNetworking
//
//  Created by Sajjad Sarkoobi on 16.08.2023.
//

import Foundation

// The Request Method
enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case patch   = "PATCH"
    case put     = "PUT"
    case delete  = "DELETE"
}

enum NetworkRequestError: LocalizedError, Equatable {
    case invalidRequest
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case error4xx(_ code: Int)
    case serverError
    case error5xx(_ code: Int)
    case decodingError( _ description: String)
    case urlSessionFailed(_ error: URLError)
    case timeOut
    case unknownError
}

// Extending Encodable to Serialize a Type into a Dictionary
extension Encodable {
    var asDictionary: [String: Any] {
        guard let data = try? JSONEncoder().encode(self) else { return [:] }

        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [String: Any] else {
            return [:]
        }
        return dictionary
    }
}

// Our Request Protocol
protocol Request {
    var baseServer: APIConstants.ServerBaseURL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var contentType: String { get }
    var requestData: Data? { get }
    var body: [String: Any]? { get }
    var queryParams: [String: Any]? { get }
    var headers: [String: String]? { get }
    associatedtype ReturnType: Codable
}

// Defaults and Helper Methods
extension Request {
    
    // Defaults
    var method: HTTPMethod { return .get }
    var contentType: String { return "application/json" }
    var queryParams: [String: Any]? { return nil }
    var body: [String: Any]? { return nil }
    var headers: [String: String]? { return nil }
    var requestData: Data? { return nil }

    /// Serializes an HTTP dictionary to a JSON Data Object
    /// - Parameter params: HTTP Parameters dictionary
    /// - Returns: Encoded JSON
    private func requestBodyFrom(params: [String: Any]?) -> Data? {
        guard let params = params else { return nil }
        guard let httpBody = try? JSONSerialization.data(withJSONObject: params, options: []) else {
            return nil
        }
        return httpBody
    }
    
    func addQueryItems(queryParams: [String: Any]?) -> [URLQueryItem]? {
        guard let queryParams = queryParams else {
            return nil
        }
        return queryParams.map({URLQueryItem(name: $0.key, value: "\($0.value)")})
    }
    
    /// Transforms an Request into a standard URL request
    /// - Parameter baseURL: API Base URL to be used
    /// - Returns: A ready to use URLRequest
    func asURLRequest() -> URLRequest? {
        guard var urlComponents = URLComponents(string: baseServer.rawValue) else { return nil }
        urlComponents.path = "\(urlComponents.path)\(path)"
        urlComponents.queryItems = addQueryItems(queryParams: queryParams)
        urlComponents.percentEncodedQuery = urlComponents.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: CharacterSet.rfc3986Unreserved)
        guard let finalURL = urlComponents.url else { return nil }
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        
        if let data = requestData {
            request.httpBody = data
        } else {
            request.httpBody = requestBodyFrom(params: body)
        }
        
        request.allHTTPHeaderFields = headers
        
        // Common Headers
        ///Auth manager will call from here for token based on the based server sent from APIRouter
//        if baseServer == .baseURL {
//            request.setValue("Bearer \(AuthManager.shared.accessToken)", forHTTPHeaderField: HTTPHeaderField.authorization.rawValue)
//        }
        
        if method == .get {
            request.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.acceptType.rawValue)
        }
      
        if method == .post || method == .patch {
            request.setValue(ContentType.json.rawValue, forHTTPHeaderField: HTTPHeaderField.contentType.rawValue)
        }
                
        return request
    }
}

typealias ApiClientComplitionHandler = ((_ data: Data, _ httpResponse: HTTPURLResponse) -> Void)?

struct NetworkDispatcher {
    typealias NetworkResult<ReturnType: Codable> = ( _result: Result<ReturnType, NetworkRequestError>,
                                                     _httpStatusCode: Int ,
                                                     _resultString: String )

    func asyncDispatch<ReturnType: Codable>(request: URLRequest) async -> NetworkResult<ReturnType> {
        var responseData = Data()
        var statusCode: Int = 0
        requestLogger(request: request)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            responseData = data
            if let httpResponse = response as? HTTPURLResponse {
                statusCode = httpResponse.statusCode
            }
            requestLogger(request: request, response: response)
        } catch (let urlSessionError) {
            if (urlSessionError as? URLError)?.code == .timedOut {
                return (_result: .failure(.timeOut),
                        _httpStatusCode: statusCode,
                        _resultString: "")
            }
            if let error = urlSessionError as? URLError {
                return (_result: .failure(.urlSessionFailed(error)),
                        _httpStatusCode: statusCode,
                        _resultString: "")
            }
            return (_result: .failure(.invalidRequest),
                    _httpStatusCode: statusCode,
                    _resultString: "")
        }
        
        let resultString = String(data: responseData, encoding: .utf8) ?? "Error in String from Data"
        
        if statusCode == 401 {
            //AuthManager.shared.logout()
            return (_result: .failure(httpError(statusCode)),
                    _httpStatusCode: statusCode,
                    _resultString: resultString)
        }
        
        if !(200...299).contains(statusCode) {
            return (_result: .failure(httpError(statusCode)),
                    _httpStatusCode: statusCode,
                    _resultString: resultString)
        }
        
        do {
            let result = try JSONDecoder().decode(ReturnType.self, from: responseData)
            return (_result: .success(result), statusCode, resultString)
        } catch( let error) {
            Log.error("\(error)")
            return (.failure(.decodingError(error.localizedDescription)), statusCode, resultString)
        }
    }
    
    private func requestLogger(request: URLRequest, response: URLResponse? = nil) {
        #if DEBUG
        let requestURL = request.url?.absoluteString ?? "--"
        if let httpResponse = response as? HTTPURLResponse {
            print("[\(httpResponse.statusCode)] '\(requestURL)'")
        } else {
            print("[\(request.httpMethod ?? "--")] '\(requestURL)'")
        }
        #endif
    }
    
    
    /// Parses a HTTP StatusCode and returns a proper error
    /// - Parameter statusCode: HTTP status code
    /// - Returns: Mapped Error
    private func httpError(_ statusCode: Int) -> NetworkRequestError {
        switch statusCode {
        case 400: return .badRequest
        case 401: return .unauthorized
        case 403: return .forbidden
        case 404: return .notFound
        case 402, 405...499: return .error4xx(statusCode)
        case 500: return .serverError
        case 501...599: return .error5xx(statusCode)
        default: return .unknownError
        }
    }
    
    /// Parses URLSession Publisher errors and return proper ones
    /// - Parameter error: URLSession publisher error
    /// - Returns: Readable NetworkRequestError
    private func handleError(_ error: Error) -> NetworkRequestError {
        switch error {
        case is Swift.DecodingError:
            return .decodingError(error.localizedDescription)
        case let urlError as URLError:
            return .urlSessionFailed(urlError)
        case let error as NetworkRequestError:
            return error
        default:
            return .unknownError
        }
    }
}

struct APIClient {
    
    static private var networkDispatcher: NetworkDispatcher = NetworkDispatcher()
    
    static func dispatch<R: Request>(_ request: R) async -> NetworkDispatcher.NetworkResult<R.ReturnType> {
        
        ///If there is some Auth check for token validation it should be happening here.
        ///It means that you need to add some Queue for tasks and check for Token validation before calling endpoints
        ///So if any token refresh needed it should be happen before here and all the tasks should be in queue.
        ///You can achive that again easily with Swift concurrency
        typealias RequestResult = ( _result: Result<R.ReturnType, NetworkRequestError>,
                                    _httpStatusCode: Int ,
                                    _resultString: String )
        
        let urlRequest = request.asURLRequest()!
        let result: RequestResult = await networkDispatcher.asyncDispatch(request: urlRequest)
        return result
    }
}

