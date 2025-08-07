//
//  MovieRepository.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

protocol MovieRepository {
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse
  func getMovieDetails(id: Int) async throws -> MovieDetail
  func getPopularMovies(page: Int) async throws -> MovieSearchResponse
  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse
  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse

  // Caching methods
  func getCachedMovies() -> MovieSearchResponse
  func getCachedMovies(for query: String) -> MovieSearchResponse
  func getCachedPopularMovies() -> MovieSearchResponse
  func getCachedMovieDetails(id: Int) -> MovieDetail?
  func saveSearchResults(_ response: MovieSearchResponse, for query: String)
  func savePopularMovies(_ response: MovieSearchResponse)
  func saveMovieDetails(_ movieDetail: MovieDetail)
  func clearOldCache(olderThan days: Int)
  func isNetworkAvailable() -> Bool
}

// MARK: - Repository Implementation
class MovieRepositoryImpl: MovieRepository {
  private let apiService: MovieAPIService
  private let networkReachability: NetworkReachabilityService
  private let cacheManager = CacheManager.shared

  init(apiService: MovieAPIService, networkReachability: NetworkReachabilityService) {
    self.apiService = apiService
    self.networkReachability = networkReachability
  }

  // MARK: - Search Movies (with caching)
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    print("🔍 Searching movies for query: '\(query)' page: \(page)")

    // Try to get cached results first
    if let cachedResponse = cacheManager.getCachedSearchResults(for: query, page: page) {
      print("📱 Returning cached search results for '\(query)'")
      return cachedResponse
    }

    // If no cache or network available, try API
    if isNetworkAvailable() {
      do {
        let response = try await apiService.searchMovies(query: query, page: page)

        // Cache the results
        cacheManager.saveSearchResults(response, for: query)
        print("💾 Cached search results for '\(query)'")

        return response
      } catch {
        print("❌ API search failed: \(error)")
        throw error
      }
    } else {
      // No network and no cache
      throw NetworkError.noInternetConnection
    }
  }

  // MARK: - Get Movie Details (with caching)
  func getMovieDetails(id: Int) async throws -> MovieDetail {
    print("🔍 Getting movie details for ID: \(id)")

    // Try to get cached details first
    if let cachedDetail = cacheManager.getCachedMovieDetails(id: id) {
      print("📱 Returning cached movie details for ID: \(id)")
      return cachedDetail
    }

    // If no cache or network available, try API
    if isNetworkAvailable() {
      do {
        let detail = try await apiService.getMovieDetails(id: id)

        // Cache the details
        cacheManager.saveMovieDetails(detail)
        print("💾 Cached movie details for ID: \(id)")

        return detail
      } catch {
        print("❌ API movie details failed: \(error)")
        throw error
      }
    } else {
      // No network and no cache
      throw NetworkError.noInternetConnection
    }
  }

  // MARK: - Get Popular Movies (with caching)
  func getPopularMovies(page: Int) async throws -> MovieSearchResponse {
    print("🔍 Getting popular movies page: \(page)")

    // For page 1, try cache first
    if page == 1, let cachedResponse = cacheManager.getCachedPopularMovies() {
      print("📱 Returning cached popular movies")
      return cachedResponse
    }

    // If no cache or network available, try API
    if isNetworkAvailable() {
      do {
        let response = try await apiService.getPopularMovies(page: page)

        // Cache only page 1
        if page == 1 {
          cacheManager.savePopularMovies(response)
          print("💾 Cached popular movies")
        }

        return response
      } catch {
        print("❌ API popular movies failed: \(error)")
        throw error
      }
    } else {
      // No network and no cache
      throw NetworkError.noInternetConnection
    }
  }

  // MARK: - Other API Methods
  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse {
    print("🔍 Getting trending movies page: \(page)")
    return try await apiService.getTrendingMovies(page: page)
  }

  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse
  {
    print("🔍 Getting movie changes page: \(page)")
    return try await apiService.getMovieChanges(startDate: startDate, endDate: endDate, page: page)
  }

  // MARK: - Caching Methods
  func getCachedMovies() -> MovieSearchResponse {
    return cacheManager.getCachedPopularMovies()
      ?? MovieSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
  }

  func getCachedMovies(for query: String) -> MovieSearchResponse {
    return cacheManager.getCachedSearchResults(for: query, page: 1)
      ?? MovieSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
  }

  func getCachedPopularMovies() -> MovieSearchResponse {
    return cacheManager.getCachedPopularMovies()
      ?? MovieSearchResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
  }

  func getCachedMovieDetails(id: Int) -> MovieDetail? {
    return cacheManager.getCachedMovieDetails(id: id)
  }

  func saveSearchResults(_ response: MovieSearchResponse, for query: String) {
    cacheManager.saveSearchResults(response, for: query)
  }

  func savePopularMovies(_ response: MovieSearchResponse) {
    cacheManager.savePopularMovies(response)
  }

  func saveMovieDetails(_ movieDetail: MovieDetail) {
    cacheManager.saveMovieDetails(movieDetail)
  }

  func clearOldCache(olderThan days: Int) {
    cacheManager.clearOldCache(olderThan: days)
  }

  func isNetworkAvailable() -> Bool {
    return networkReachability.isConnected
  }
}
