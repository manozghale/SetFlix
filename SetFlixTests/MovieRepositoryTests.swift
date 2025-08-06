//
//  MovieRepositoryTests.swift
//  SetFlixTests
//
//  Created by Manoj on 06/08/2025.
//

import XCTest

@testable import SetFlix

class MovieRepositoryTests: XCTestCase {

  var repository: MovieRepository!
  var mockAPIService: MockMovieAPIService!
  var mockCoreDataManager: MockCoreDataManager!
  var mockNetworkReachability: MockNetworkReachabilityService!

  override func setUpWithError() throws {
    super.setUp()

    mockAPIService = MockMovieAPIService()
    mockCoreDataManager = MockCoreDataManager()
    mockNetworkReachability = MockNetworkReachabilityService()

    repository = MovieRepositoryImpl(
      apiService: mockAPIService,
      coreDataManager: mockCoreDataManager,
      networkReachability: mockNetworkReachability
    )
  }

  override func tearDownWithError() throws {
    repository = nil
    mockAPIService = nil
    mockCoreDataManager = nil
    mockNetworkReachability = nil
    super.tearDown()
  }

  // MARK: - Search Movies Tests

  func testSearchMoviesWithCache() async throws {
    // Given
    let cachedMovies = [
      Movie(
        id: 1, title: "Cached Movie", releaseDate: "2023-01-01", overview: "Overview",
        posterPath: "/cached.jpg")
    ]
    mockCoreDataManager.cachedMovies = cachedMovies
    mockNetworkReachability.isConnected = false

    // When
    let result = try await repository.searchMovies(query: "test", page: 1)

    // Then
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.title, "Cached Movie")
    XCTAssertFalse(mockAPIService.searchMoviesCalled)
  }

  func testSearchMoviesWithAPI() async throws {
    // Given
    let apiMovies = [
      Movie(
        id: 2, title: "API Movie", releaseDate: "2023-01-02", overview: "API Overview",
        posterPath: "/api.jpg")
    ]
    mockAPIService.searchResponse = MovieSearchResponse(
      page: 1,
      results: apiMovies,
      totalPages: 1,
      totalResults: 1
    )
    mockNetworkReachability.isConnected = true

    // When
    let result = try await repository.searchMovies(query: "test", page: 1)

    // Then
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.title, "API Movie")
    XCTAssertTrue(mockAPIService.searchMoviesCalled)
    XCTAssertTrue(mockCoreDataManager.savePageCalled)
  }

  func testSearchMoviesNoNetwork() async {
    // Given
    mockNetworkReachability.isConnected = false
    mockCoreDataManager.cachedMovies = nil

    // When & Then
    do {
      _ = try await repository.searchMovies(query: "test", page: 1)
      XCTFail("Expected network error")
    } catch let error as NetworkError {
      XCTAssertEqual(error, .noInternetConnection)
    } catch {
      XCTFail("Expected NetworkError.noInternetConnection")
    }
  }

  // MARK: - Get Movie Details Tests

  func testGetMovieDetailsSuccess() async throws {
    // Given
    let movieDetail = MovieDetail(
      id: 1,
      title: "Test Movie",
      releaseDate: "2023-01-01",
      overview: "Test overview",
      posterPath: "/test.jpg"
    )
    mockAPIService.movieDetail = movieDetail
    mockNetworkReachability.isConnected = true

    // When
    let result = try await repository.getMovieDetails(id: 1)

    // Then
    XCTAssertEqual(result.id, 1)
    XCTAssertEqual(result.title, "Test Movie")
    XCTAssertTrue(mockAPIService.getMovieDetailsCalled)
    XCTAssertTrue(mockCoreDataManager.saveMovieCalled)
  }

  func testGetMovieDetailsNoNetwork() async {
    // Given
    mockNetworkReachability.isConnected = false

    // When & Then
    do {
      _ = try await repository.getMovieDetails(id: 1)
      XCTFail("Expected network error")
    } catch let error as NetworkError {
      XCTAssertEqual(error, .noInternetConnection)
    } catch {
      XCTFail("Expected NetworkError.noInternetConnection")
    }
  }

  // MARK: - Favorites Tests

  func testSaveToFavorites() async throws {
    // Given
    let movie = Movie(
      id: 1, title: "Favorite Movie", releaseDate: "2023-01-01", overview: "Overview",
      posterPath: "/favorite.jpg")

    // When
    try await repository.saveToFavorites(movie)

    // Then
    XCTAssertTrue(mockCoreDataManager.saveMovieCalled)
    XCTAssertEqual(mockCoreDataManager.lastSavedMovie?.id, 1)
    XCTAssertEqual(mockCoreDataManager.lastIsFavorite, true)
  }

  func testGetFavorites() async throws {
    // Given
    let favoriteMovies = [
      Movie(
        id: 1, title: "Favorite 1", releaseDate: "2023-01-01", overview: "Overview 1",
        posterPath: "/1.jpg"),
      Movie(
        id: 2, title: "Favorite 2", releaseDate: "2023-01-02", overview: "Overview 2",
        posterPath: "/2.jpg"),
    ]
    mockCoreDataManager.favoriteMovies = favoriteMovies

    // When
    let result = try await repository.getFavorites()

    // Then
    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(result.first?.title, "Favorite 1")
    XCTAssertEqual(result.last?.title, "Favorite 2")
  }

  func testToggleFavorite() async throws {
    // Given
    mockCoreDataManager.toggleFavoriteResult = true

    // When
    let result = try await repository.toggleFavorite(1)

    // Then
    XCTAssertTrue(result)
    XCTAssertEqual(mockCoreDataManager.lastToggledMovieId, 1)
  }

  func testIsFavorite() async throws {
    // Given
    mockCoreDataManager.isFavoriteResult = true

    // When
    let result = try await repository.isFavorite(1)

    // Then
    XCTAssertTrue(result)
    XCTAssertEqual(mockCoreDataManager.lastCheckedMovieId, 1)
  }
}

// MARK: - Mock Classes

class MockMovieAPIService: MovieAPIService {
  var searchMoviesCalled = false
  var getMovieDetailsCalled = false
  var searchResponse: MovieSearchResponse?
  var movieDetail: MovieDetail?

  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    searchMoviesCalled = true
    guard let response = searchResponse else {
      throw NetworkError.unknown
    }
    return response
  }

  func getMovieDetails(id: Int) async throws -> MovieDetail {
    getMovieDetailsCalled = true
    guard let detail = movieDetail else {
      throw NetworkError.unknown
    }
    return detail
  }

}

class MockCoreDataManager: CoreDataManager {
  var cachedMovies: [Movie]?
  var favoriteMovies: [Movie] = []
  var savePageCalled = false
  var saveMovieCalled = false
  var toggleFavoriteCalled = false
  var lastSavedMovie: Movie?
  var lastIsFavorite: Bool = false
  var lastToggledMovieId: Int = 0
  var lastCheckedMovieId: Int = 0
  var toggleFavoriteResult: Bool = false
  var isFavoriteResult: Bool = false

  override func getCachedMovies(for query: String, pageNumber: Int) -> [MovieEntity]? {
    return cachedMovies?.compactMap { movie in
      let entity = MovieEntity(context: context)
      entity.id = Int64(movie.id)
      entity.title = movie.title
      entity.overview = movie.overview
      entity.posterURL = movie.posterURL
      entity.releaseDate = Date()
      return entity
    }
  }

  override func savePage(query: String, pageNumber: Int, movies: [Movie]) {
    savePageCalled = true
  }

  override func saveMovie(_ movie: Movie, isFavorite: Bool = false) {
    saveMovieCalled = true
    lastSavedMovie = movie
    lastIsFavorite = isFavorite
  }

  override func getFavoriteMovies() -> [MovieEntity] {
    return favoriteMovies.compactMap { movie in
      let entity = MovieEntity(context: context)
      entity.id = Int64(movie.id)
      entity.title = movie.title
      entity.overview = movie.overview
      entity.posterURL = movie.posterURL
      entity.releaseDate = Date()
      entity.isFavorite = true
      return entity
    }
  }

  override func toggleFavorite(for movieId: Int) -> Bool {
    toggleFavoriteCalled = true
    lastToggledMovieId = movieId
    return toggleFavoriteResult
  }

  override func getMovie(by id: Int) -> MovieEntity? {
    lastCheckedMovieId = id
    let entity = MovieEntity(context: context)
    entity.id = Int64(id)
    entity.isFavorite = isFavoriteResult
    return entity
  }
}

class MockNetworkReachabilityService: NetworkReachabilityService {
  var isConnected: Bool = true

  override func isNetworkAvailable() -> Bool {
    return isConnected
  }
}
