//
//  MovieRepositoryFactory.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

class MovieRepositoryFactory {
  static func createRepository() -> MovieRepository {
    let apiKey = ConfigurationManager.shared.tmdbAPIKey
    let apiService = TMDBAPIService(apiKey: apiKey)
    let networkReachability = NetworkReachabilityService.shared

    return MovieRepositoryImpl(apiService: apiService, networkReachability: networkReachability)
  }

  static func createMockRepository() -> MovieRepository {
    return MockMovieRepository()
  }
}

// MARK: - Mock Repository for Testing
class MockMovieRepository: MovieRepository {
  private let mockMovies = [
    Movie(
      id: 1, title: "The Enigma Code", releaseDate: "2022-01-15",
      posterPath: "/mock-poster-1.jpg"
    ),
    Movie(
      id: 2, title: "Starlight Symphony", releaseDate: "2023-03-22",
      posterPath: "/mock-poster-2.jpg"
    ),
    Movie(
      id: 3, title: "Echoes of the Past", releaseDate: "2021-11-08",
      posterPath: "/mock-poster-3.jpg"
    ),
  ]

  private let mockMovieDetails = [
    1: MovieDetail(
      id: 1,
      title: "The Enigma Code",
      releaseDate: "2022-01-15",
      overview: "A thrilling mystery about a code that could change the world.",
      posterPath: "/mock-poster-1.jpg"
    ),
    2: MovieDetail(
      id: 2,
      title: "Starlight Symphony",
      releaseDate: "2023-03-22",
      overview: "A musical journey through the cosmos.",
      posterPath: "/mock-poster-2.jpg"
    ),
    3: MovieDetail(
      id: 3,
      title: "Echoes of the Past",
      releaseDate: "2021-11-08",
      overview: "A haunting tale of memories and redemption.",
      posterPath: "/mock-poster-3.jpg"
    ),
  ]

  // MARK: - API Methods
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    // Simulate API delay
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

    let filteredMovies = mockMovies.filter { movie in
      query.isEmpty || movie.title.localizedCaseInsensitiveContains(query)
    }

    return MovieSearchResponse(
      page: page,
      results: filteredMovies,
      totalPages: 1,
      totalResults: filteredMovies.count
    )
  }

  func getMovieDetails(id: Int) async throws -> MovieDetail {
    // Simulate API delay
    try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

    guard let movieDetail = mockMovieDetails[id] else {
      throw NetworkError.invalidResponse
    }

    return movieDetail
  }

  func getPopularMovies(page: Int) async throws -> MovieSearchResponse {
    // Simulate API delay
    try await Task.sleep(nanoseconds: 400_000_000)  // 0.4 seconds

    return MovieSearchResponse(
      page: page,
      results: mockMovies,
      totalPages: 1,
      totalResults: mockMovies.count
    )
  }

  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse {
    // Simulate API delay
    try await Task.sleep(nanoseconds: 400_000_000)  // 0.4 seconds

    return MovieSearchResponse(
      page: page,
      results: mockMovies,
      totalPages: 1,
      totalResults: mockMovies.count
    )
  }

  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse
  {
    // Simulate API delay
    try await Task.sleep(nanoseconds: 400_000_000)  // 0.4 seconds

    return MovieChangesResponse(
      page: page,
      results: [],
      totalPages: 1,
      totalResults: 0
    )
  }

  // MARK: - Caching Methods
  func getCachedMovies() -> MovieSearchResponse {
    return MovieSearchResponse(
      page: 1,
      results: mockMovies,
      totalPages: 1,
      totalResults: mockMovies.count
    )
  }

  func getCachedMovies(for query: String) -> MovieSearchResponse {
    let filteredMovies = mockMovies.filter { movie in
      query.isEmpty || movie.title.localizedCaseInsensitiveContains(query)
    }

    return MovieSearchResponse(
      page: 1,
      results: filteredMovies,
      totalPages: 1,
      totalResults: filteredMovies.count
    )
  }

  func getCachedPopularMovies() -> MovieSearchResponse {
    return MovieSearchResponse(
      page: 1,
      results: mockMovies,
      totalPages: 1,
      totalResults: mockMovies.count
    )
  }

  func getCachedMovieDetails(id: Int) -> MovieDetail? {
    return mockMovieDetails[id]
  }

  func saveSearchResults(_ response: MovieSearchResponse, for query: String) {
    // Mock implementation - no actual caching in mock
    print("Mock: Would save search results for '\(query)'")
  }

  func savePopularMovies(_ response: MovieSearchResponse) {
    // Mock implementation - no actual caching in mock
    print("Mock: Would save popular movies")
  }

  func saveMovieDetails(_ movieDetail: MovieDetail) {
    // Mock implementation - no actual caching in mock
    print("Mock: Would save movie details for ID \(movieDetail.id)")
  }

  func clearOldCache(olderThan days: Int) {
    // Mock implementation - no actual cache clearing in mock
    print("Mock: Would clear cache older than \(days) days")
  }

  func isNetworkAvailable() -> Bool {
    // Mock implementation - always return true for testing
    return true
  }
}
