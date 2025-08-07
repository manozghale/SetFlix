//
//  MovieAPIService.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

// MARK: - API Service Protocol
protocol MovieAPIService {
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse
  func getMovieDetails(id: Int) async throws -> MovieDetail
  func getPopularMovies(page: Int) async throws -> MovieSearchResponse
  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse
  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse
}

// MARK: - TMDB API Implementation
class TMDBAPIService: MovieAPIService {
  private let baseURL = "https://api.themoviedb.org/3"
  private let apiKey: String
  private let session: URLSession
  private let decoder: JSONDecoder

  init(apiKey: String, session: URLSession = .shared) {
    self.apiKey = apiKey
    self.session = session
    self.decoder = JSONDecoder()
    self.decoder.keyDecodingStrategy = .convertFromSnakeCase
  }

  // MARK: - Search Movies
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    let url = buildSearchURL(query: query, page: page)
    return try await performRequest(url: url)
  }

  // MARK: - Get Movie Details
  func getMovieDetails(id: Int) async throws -> MovieDetail {
    let url = buildMovieDetailsURL(id: id)
    return try await performRequest(url: url)
  }

  // MARK: - Get Popular Movies
  func getPopularMovies(page: Int) async throws -> MovieSearchResponse {
    let url = buildPopularMoviesURL(page: page)
    return try await performRequest(url: url)
  }

  // MARK: - Get Trending Movies
  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse {
    let url = buildTrendingMoviesURL(page: page)
    return try await performRequest(url: url)
  }

  // MARK: - Get Movie Changes
  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse
  {
    let url = buildMovieChangesURL(startDate: startDate, endDate: endDate, page: page)
    return try await performRequest(url: url)
  }

  // MARK: - Private Methods

  private func performRequest<T: Codable>(url: URL) async throws -> T {
    do {
      let (data, response) = try await session.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
      }

      // Check for HTTP status code errors
      guard 200...299 ~= httpResponse.statusCode else {
        throw NetworkError.from(statusCode: httpResponse.statusCode)
      }

      // Debug: Print the actual JSON response
      if let jsonString = String(data: data, encoding: .utf8) {
        print("🔍 API Response for \(url):")
        // Print only first 1000 characters to avoid overwhelming logs
        let truncated = String(jsonString.prefix(1000))
        print(truncated)
        if jsonString.count > 1000 {
          print("... (truncated)")
        }
      }

      do {
        return try decoder.decode(T.self, from: data)
      } catch {
        print("❌ Decoding error: \(error)")
        throw NetworkError.decodingError
      }
    } catch let error as NetworkError {
      throw error
    } catch {
      // Handle network-specific errors
      if let urlError = error as? URLError {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost:
          throw NetworkError.noInternetConnection
        case .timedOut:
          throw NetworkError.timeout
        default:
          throw NetworkError.unknown
        }
      } else {
        throw NetworkError.unknown
      }
    }
  }

  // MARK: - URL Builders

  private func buildSearchURL(query: String, page: Int) -> URL {
    var components = URLComponents(string: "\(baseURL)/search/movie")!
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "query", value: query),
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "include_adult", value: "false"),
      URLQueryItem(name: "language", value: "en-US"),
    ]
    return components.url!
  }

  private func buildMovieDetailsURL(id: Int) -> URL {
    var components = URLComponents(string: "\(baseURL)/movie/\(id)")!
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "language", value: "en-US"),
      URLQueryItem(name: "append_to_response", value: "credits,videos,images"),
    ]
    return components.url!
  }

  private func buildPopularMoviesURL(page: Int) -> URL {
    var components = URLComponents(string: "\(baseURL)/movie/popular")!
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "language", value: "en-US"),
    ]
    return components.url!
  }

  private func buildTrendingMoviesURL(page: Int) -> URL {
    var components = URLComponents(string: "\(baseURL)/trending/movie/week")!
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "page", value: "\(page)"),
      URLQueryItem(name: "language", value: "en-US"),
    ]
    return components.url!
  }

  private func buildMovieChangesURL(startDate: String, endDate: String, page: Int) -> URL {
    var components = URLComponents(string: "\(baseURL)/movie/changes")!
    components.queryItems = [
      URLQueryItem(name: "api_key", value: apiKey),
      URLQueryItem(name: "start_date", value: startDate),
      URLQueryItem(name: "end_date", value: endDate),
      URLQueryItem(name: "page", value: "\(page)"),
    ]
    return components.url!
  }
}

// MARK: - API Configuration
struct APIConfig {
  static let baseURL = "https://api.themoviedb.org/3"
  static let imageBaseURL = "https://image.tmdb.org/t/p/"
  static let posterSizes = ["w92", "w154", "w185", "w342", "w500", "w780", "original"]
  static let backdropSizes = ["w300", "w780", "w1280", "original"]

  static func posterURL(path: String, size: String = "w500") -> URL? {
    return URL(string: "\(imageBaseURL)\(size)\(path)")
  }

  static func backdropURL(path: String, size: String = "w1280") -> URL? {
    return URL(string: "\(imageBaseURL)\(size)\(path)")
  }
}
