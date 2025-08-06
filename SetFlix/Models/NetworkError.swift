//
//  NetworkError.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

enum NetworkError: Error, LocalizedError {
  case invalidURL
  case invalidResponse
  case decodingError
  case noInternetConnection
  case serverError(Int)
  case timeout
  case unauthorized
  case rateLimitExceeded
  case unknown

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid response from server"
    case .decodingError:
      return "Failed to decode response"
    case .noInternetConnection:
      return "No internet connection. Please check your network settings."
    case .serverError(let code):
      return "Server error: \(code)"
    case .timeout:
      return "Request timed out. Please try again."
    case .unauthorized:
      return "Unauthorized access. Please check your API key."
    case .rateLimitExceeded:
      return "Too many requests. Please try again later."
    case .unknown:
      return "An unknown error occurred. Please try again."
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .noInternetConnection:
      return "Please check your internet connection and try again."
    case .timeout:
      return "The request took too long. Please try again."
    case .unauthorized:
      return "Please check your API configuration."
    case .rateLimitExceeded:
      return "Please wait a moment before trying again."
    default:
      return "Please try again later."
    }
  }

  // Helper method to create NetworkError from HTTP status code
  static func from(statusCode: Int) -> NetworkError {
    switch statusCode {
    case 200...299:
      return .unknown  // Shouldn't happen for successful responses
    case 401:
      return .unauthorized
    case 429:
      return .rateLimitExceeded
    case 500...599:
      return .serverError(statusCode)
    default:
      return .invalidResponse
    }
  }
}

// MARK: - Network Result Type
enum NetworkResult<T> {
  case success(T)
  case failure(NetworkError)
}
