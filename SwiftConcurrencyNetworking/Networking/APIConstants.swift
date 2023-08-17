//
//  APIConstants.swift
//  SwiftConcurrencyNetworking
//
//  Created by Sajjad Sarkoobi on 16.08.2023.
//

import Foundation

class APIConstants {
    static var basedURL: String = "https://dummyjson.com"
    
    enum ServerBaseURL: String {
        case baseURL = "https://dummyjson.com"
//        case uploadURL = "https://dummyjson.com"
//        case authURL = "https://dummyjson.com"
    }
}

enum HTTPHeaderField: String {
    case authentication = "Authentication"
    case contentType = "Content-Type"
    case acceptType = "Accept"
    case acceptEncoding = "Accept-Encoding"
    case authorization = "Authorization"
    case acceptLanguage = "Accept-Language"
    case userAgent = "User-Agent"
}

enum ContentType: String {
    case json = "application/json"
    case xwwwformurlencoded = "application/x-www-form-urlencoded"
}

