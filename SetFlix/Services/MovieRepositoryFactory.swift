//
//  MovieRepositoryFactory.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

class MovieRepositoryFactory {

  // MARK: - Singleton
  static let shared = MovieRepositoryFactory()

  private init() {}

  // MARK: - Repository Creation
  static func createRepository() -> MovieRepository {
    let configurationManager = ConfigurationManager.shared
    let apiService = TMDBAPIService(apiKey: configurationManager.tmdbAPIKey)
    let coreDataManager = CoreDataManager.shared
    let networkReachability = NetworkReachabilityService.shared

    return MovieRepositoryImpl(
      apiService: apiService,
      coreDataManager: coreDataManager,
      networkReachability: networkReachability
    )
  }

  // MARK: - Mock Repository (for testing)
  static func createMockRepository() -> MovieRepository {
    return MockMovieRepository()
  }
}

// MARK: - Mock Repository for Testing
class MockMovieRepository: MovieRepository {

  private var favorites: Set<Int> = []
  private var mockMovies: [Movie] = [
    Movie(
      id: 1, title: "The Enigma Code", releaseDate: "2022-01-15",
      posterPath: "/sample1.jpg"),
    Movie(
      id: 2, title: "Starlight Symphony", releaseDate: "2023-03-22",
      posterPath: "/sample2.jpg"),
    Movie(
      id: 3, title: "Echoes of the Past", releaseDate: "2021-11-08",
      posterPath: "/sample3.jpg"),
  ]

  private var mockMovieDetails: [Int: String] = [
    1: "A thrilling mystery about code breaking during World War II.",
    2: "A musical journey through space with stunning visuals and orchestral scores.",
    3: "A haunting tale of memories and the past that refuses to stay buried.",
  ]

  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    // Simulate network delay
    try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

    let filteredMovies = mockMovies.filter { movie in
      movie.title.localizedCaseInsensitiveContains(query)
    }

    return MovieSearchResponse(
      page: page,
      results: filteredMovies,
      totalPages: 1,
      totalResults: filteredMovies.count
    )
  }

  func getMovieDetails(id: Int) async throws -> MovieDetail {
    // Simulate network delay
    try await Task.sleep(nanoseconds: 300_000_000)  // 0.3 seconds

    guard let movie = mockMovies.first(where: { $0.id == id }) else {
      throw NetworkError.invalidResponse
    }

    let overview = mockMovieDetails[id] ?? "No overview available."

    return MovieDetail(
      id: movie.id,
      title: movie.title,
      releaseDate: movie.releaseDate,
      overview: overview,
      posterPath: movie.posterPath
    )
  }

  func saveToFavorites(_ movie: Movie) async throws {
    favorites.insert(movie.id)
  }

  func getFavorites() async throws -> [Movie] {
    return mockMovies.filter { favorites.contains($0.id) }
  }

  func removeFromFavorites(_ movieId: Int) async throws {
    favorites.remove(movieId)
  }

  func toggleFavorite(_ movieId: Int) async throws -> Bool {
    if favorites.contains(movieId) {
      favorites.remove(movieId)
      return false
    } else {
      favorites.insert(movieId)
      return true
    }
  }

  func isFavorite(_ movieId: Int) async throws -> Bool {
    return favorites.contains(movieId)
  }
}
