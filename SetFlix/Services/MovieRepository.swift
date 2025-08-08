//
//  MovieRepository.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Combine
import Foundation

protocol MovieRepository {
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse
  func getMovieDetails(id: Int) async throws -> MovieDetail
  func getPopularMovies(page: Int) async throws -> MovieSearchResponse
  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse
  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse

  // Favorites methods
  func getFavorites() async throws -> [Movie]
  func saveToFavorites(_ movie: Movie) async throws
  func removeFromFavorites(_ movieId: Int) async throws
  func toggleFavorite(_ movieId: Int) async throws -> Bool
  func isFavorite(_ movieId: Int) async throws -> Bool

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

  // Network state publisher
  var networkStatePublisher: AnyPublisher<Bool, Never> { get }
}

// MARK: - Repository Implementation
class MovieRepositoryImpl: MovieRepository {
  private let apiService: MovieAPIService
  private let networkReachability: NetworkReachabilityProtocol
  private let cacheManager = CacheManager.shared
  private var cancellables = Set<AnyCancellable>()

  init(apiService: MovieAPIService, networkReachability: NetworkReachabilityProtocol) {
    self.apiService = apiService
    self.networkReachability = networkReachability
    setupNetworkMonitoring()
  }

  private func setupNetworkMonitoring() {
    networkReachability.isConnectedPublisher
      .sink { [weak self] isConnected in
        print("📱 Repository detected network change: \(isConnected ? "Online" : "Offline")")
        // Repository can react to network changes here if needed
      }
      .store(in: &cancellables)
  }

  // MARK: - Search Movies (Online-first with offline fallback)
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    print("🔍 Searching movies for query: '\(query)' page: \(page)")

    // When online: Try API first, then cache the results
    if isNetworkAvailable() {
      do {
        let response = try await apiService.searchMovies(query: query, page: page)

        // Cache the fresh results
        cacheManager.saveSearchResults(response, for: query)
        print("💾 Cached fresh search results for '\(query)'")

        return response
      } catch {
        print("❌ API search failed: \(error)")

        // If API fails, try to get cached data as fallback
        if let cachedResponse = cacheManager.getCachedSearchResults(for: query, page: page) {
          print("📱 API failed, returning cached search results for '\(query)'")
          return cachedResponse
        }

        // No cache available, throw the original error
        throw error
      }
    } else {
      // When offline: Use cached data only
      print("📱 Offline mode - checking cache for '\(query)'")
      if let cachedResponse = cacheManager.getCachedSearchResults(for: query, page: page) {
        print("📱 Returning cached search results for '\(query)'")
        return cachedResponse
      } else {
        // No cache available offline
        throw NetworkError.noInternetConnection
      }
    }
  }

  // MARK: - Get Movie Details (Online-first with offline fallback)
  func getMovieDetails(id: Int) async throws -> MovieDetail {
    print("🔍 Getting movie details for ID: \(id)")

    // When online: Try API first, then cache the results
    if isNetworkAvailable() {
      do {
        let detail = try await apiService.getMovieDetails(id: id)

        // Cache the fresh details
        cacheManager.saveMovieDetails(detail)
        print("💾 Cached fresh movie details for ID: \(id)")

        return detail
      } catch {
        print("❌ API movie details failed: \(error)")

        // If API fails, try to get cached data as fallback
        if let cachedDetail = cacheManager.getCachedMovieDetails(id: id) {
          print("📱 API failed, returning cached movie details for ID: \(id)")
          return cachedDetail
        }

        // No cache available, throw the original error
        throw error
      }
    } else {
      // When offline: Use cached data only
      print("📱 Offline mode - checking cache for movie ID: \(id)")
      if let cachedDetail = cacheManager.getCachedMovieDetails(id: id) {
        print("📱 Returning cached movie details for ID: \(id)")
        return cachedDetail
      } else {
        // No cache available offline
        throw NetworkError.noInternetConnection
      }
    }
  }

  // MARK: - Get Popular Movies (Online-first with offline fallback)
  func getPopularMovies(page: Int) async throws -> MovieSearchResponse {
    print("🔍 Getting popular movies page: \(page)")

    // When online: Try API first, then cache the results
    if isNetworkAvailable() {
      do {
        let response = try await apiService.getPopularMovies(page: page)

        // Cache only page 1
        if page == 1 {
          cacheManager.savePopularMovies(response)
          print("💾 Cached fresh popular movies")
        }

        return response
      } catch {
        print("❌ API popular movies failed: \(error)")

        // If API fails, try to get cached data as fallback (only for page 1)
        if page == 1, let cachedResponse = cacheManager.getCachedPopularMovies() {
          print("📱 API failed, returning cached popular movies")
          return cachedResponse
        }

        // No cache available, throw the original error
        throw error
      }
    } else {
      // When offline: Use cached data only (only for page 1)
      if page == 1 {
        print("📱 Offline mode - checking cache for popular movies")
        if let cachedResponse = cacheManager.getCachedPopularMovies() {
          print("📱 Returning cached popular movies")
          return cachedResponse
        }
      }

      // No cache available offline
      throw NetworkError.noInternetConnection
    }
  }

  // MARK: - Other API Methods (Online-only)
  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse {
    print("🔍 Getting trending movies page: \(page)")

    if isNetworkAvailable() {
      return try await apiService.getTrendingMovies(page: page)
    } else {
      throw NetworkError.noInternetConnection
    }
  }

  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse
  {
    print("🔍 Getting movie changes page: \(page)")

    if isNetworkAvailable() {
      return try await apiService.getMovieChanges(
        startDate: startDate, endDate: endDate, page: page)
    } else {
      throw NetworkError.noInternetConnection
    }
  }

  // MARK: - Favorites Methods
  func getFavorites() async throws -> [Movie] {
    return try await cacheManager.getFavorites()
  }

  func saveToFavorites(_ movie: Movie) async throws {
    try await cacheManager.saveToFavorites(movie)
  }

  func removeFromFavorites(_ movieId: Int) async throws {
    try await cacheManager.removeFromFavorites(movieId)
  }

  func toggleFavorite(_ movieId: Int) async throws -> Bool {
    return try await cacheManager.toggleFavorite(movieId)
  }

  func isFavorite(_ movieId: Int) async throws -> Bool {
    return try await cacheManager.isFavorite(movieId)
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

  var networkStatePublisher: AnyPublisher<Bool, Never> {
    return networkReachability.isConnectedPublisher
  }
}
