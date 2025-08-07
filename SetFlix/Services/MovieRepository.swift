//
//  MovieRepository.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

// MARK: - Repository Protocol
protocol MovieRepository {
  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse
  func getMovieDetails(id: Int) async throws -> MovieDetail
  func saveToFavorites(_ movie: Movie) async throws
  func getFavorites() async throws -> [Movie]
  func removeFromFavorites(_ movieId: Int) async throws
  func toggleFavorite(_ movieId: Int) async throws -> Bool
  func isFavorite(_ movieId: Int) async throws -> Bool
}

// MARK: - Repository Implementation
class MovieRepositoryImpl: MovieRepository {
  private let apiService: MovieAPIService
  private let coreDataManager: CoreDataManager
  private let networkReachability: NetworkReachabilityService

  init(
    apiService: MovieAPIService,
    coreDataManager: CoreDataManager = CoreDataManager.shared,
    networkReachability: NetworkReachabilityService = NetworkReachabilityService.shared
  ) {
    self.apiService = apiService
    self.coreDataManager = coreDataManager
    self.networkReachability = networkReachability
  }

  // MARK: - Search Movies

  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    // Check cache first if offline or for better performance
    if let cachedMovies = coreDataManager.getCachedMovies(for: query, pageNumber: page) {
      let movies = cachedMovies.compactMap { $0.toMovie() }
      return MovieSearchResponse(
        page: page,
        results: movies,
        totalPages: 1,  // We don't cache total pages, so default to 1
        totalResults: movies.count
      )
    }

    // Check network connectivity
    guard networkReachability.isNetworkAvailable() else {
      throw NetworkError.noInternetConnection
    }

    // Fetch from API
    let response = try await apiService.searchMovies(query: query, page: page)

    // Cache the results
    coreDataManager.savePage(query: query, pageNumber: page, movies: response.results)

    return response
  }

  // MARK: - Get Movie Details

  func getMovieDetails(id: Int) async throws -> MovieDetail {
    // Check network connectivity
    guard networkReachability.isNetworkAvailable() else {
      throw NetworkError.noInternetConnection
    }

    // Fetch from API
    let movieDetail = try await apiService.getMovieDetails(id: id)

    // Save to Core Data for offline access
    let movie = Movie(
      id: movieDetail.id,
      title: movieDetail.title,
      releaseDate: movieDetail.releaseDate,
      posterPath: movieDetail.posterPath
    )
    coreDataManager.saveMovie(movie)

    return movieDetail
  }

  // MARK: - Favorites Management

  func saveToFavorites(_ movie: Movie) async throws {
    coreDataManager.saveMovie(movie, isFavorite: true)
  }

  func getFavorites() async throws -> [Movie] {
    let favoriteEntities = coreDataManager.getFavoriteMovies()
    return favoriteEntities.compactMap { $0.toMovie() }
  }

  func removeFromFavorites(_ movieId: Int) async throws {
    // Instead of deleting, we'll just mark as not favorite
    _ = coreDataManager.toggleFavorite(for: movieId)
  }

  func toggleFavorite(_ movieId: Int) async throws -> Bool {
    return coreDataManager.toggleFavorite(for: movieId)
  }

  func isFavorite(_ movieId: Int) async throws -> Bool {
    guard let movieEntity = coreDataManager.getMovie(by: movieId) else {
      return false
    }
    return movieEntity.isFavorite
  }
}
