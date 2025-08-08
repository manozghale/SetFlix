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
  var mockCacheManager: MockCacheManager!
  var mockNetworkService: MockNetworkReachabilityService!

  override func setUp() {
    super.setUp()
    mockAPIService = MockMovieAPIService()
    mockCacheManager = MockCacheManager()
    mockNetworkService = MockNetworkReachabilityService()
    repository = MovieRepositoryImpl(
      apiService: mockAPIService,
      networkReachability: mockNetworkService
    )
  }

  override func tearDown() {
    repository = nil
    mockAPIService = nil
    mockCacheManager = nil
    mockNetworkService = nil
    super.tearDown()
  }

  // MARK: - Search Movies Tests

  func testSearchMoviesSuccess() async throws {
    // Given
    let expectedMovies = [
      Movie(id: 1, title: "Test Movie 1", releaseDate: "2025-01-01", posterPath: "/test1.jpg"),
      Movie(id: 2, title: "Test Movie 2", releaseDate: "2025-01-02", posterPath: "/test2.jpg"),
    ]
    let expectedResponse = MovieSearchResponse(
      page: 1,
      results: expectedMovies,
      totalPages: 1,
      totalResults: 2
    )
    mockAPIService.mockSearchResponse = expectedResponse
    mockNetworkService.isConnected = true

    // When
    let result = try await repository.searchMovies(query: "test", page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 2)
    XCTAssertEqual(result.results[0].title, "Test Movie 1")
    XCTAssertEqual(result.results[1].title, "Test Movie 2")
  }

  func testSearchMoviesOffline() async throws {
    // Given
    mockNetworkService.isConnected = false
    let cachedMovies = [
      Movie(id: 3, title: "Cached Movie", releaseDate: "2025-01-03", posterPath: "/cached.jpg")
    ]
    let cachedResponse = MovieSearchResponse(
      page: 1,
      results: cachedMovies,
      totalPages: 1,
      totalResults: 1
    )
    mockCacheManager.mockCachedSearchResults = cachedResponse

    // When
    let result = try await repository.searchMovies(query: "test", page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results[0].title, "Cached Movie")
  }

  func testSearchMoviesError() async {
    // Given
    mockAPIService.shouldThrowError = true
    mockAPIService.mockError = NetworkError.invalidResponse
    mockNetworkService.isConnected = true

    // When & Then
    do {
      _ = try await repository.searchMovies(query: "test", page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  // MARK: - Get Movie Details Tests

  func testGetMovieDetailsSuccess() async throws {
    // Given
    let expectedDetail = MovieDetail(
      id: 1,
      title: "Test Movie",
      releaseDate: "2025-01-01",
      overview: "Test overview",
      posterPath: "/test.jpg"
    )
    mockAPIService.mockMovieDetail = expectedDetail
    mockNetworkService.isConnected = true

    // When
    let result = try await repository.getMovieDetails(id: 1)

    // Then
    XCTAssertEqual(result.id, 1)
    XCTAssertEqual(result.title, "Test Movie")
    XCTAssertEqual(result.overview, "Test overview")
  }

  func testGetMovieDetailsOffline() async throws {
    // Given
    mockNetworkService.isConnected = false
    let cachedDetail = MovieDetail(
      id: 1,
      title: "Cached Movie",
      releaseDate: "2025-01-01",
      overview: "Cached overview",
      posterPath: "/cached.jpg"
    )
    mockCacheManager.mockCachedMovieDetail = cachedDetail

    // When
    let result = try await repository.getMovieDetails(id: 1)

    // Then
    XCTAssertEqual(result.id, 1)
    XCTAssertEqual(result.title, "Cached Movie")
    XCTAssertEqual(result.overview, "Cached overview")
  }

  // MARK: - Get Popular Movies Tests

  func testGetPopularMoviesSuccess() async throws {
    // Given
    let expectedMovies = [
      Movie(id: 1, title: "Popular Movie 1", releaseDate: "2025-01-01", posterPath: "/pop1.jpg"),
      Movie(id: 2, title: "Popular Movie 2", releaseDate: "2025-01-02", posterPath: "/pop2.jpg"),
    ]
    let expectedResponse = MovieSearchResponse(
      page: 1,
      results: expectedMovies,
      totalPages: 1,
      totalResults: 2
    )
    mockAPIService.mockPopularResponse = expectedResponse
    mockNetworkService.isConnected = true

    // When
    let result = try await repository.getPopularMovies(page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 2)
    XCTAssertEqual(result.results[0].title, "Popular Movie 1")
    XCTAssertEqual(result.results[1].title, "Popular Movie 2")
  }

  func testGetPopularMoviesOffline() async throws {
    // Given
    mockNetworkService.isConnected = false
    let cachedMovies = [
      Movie(id: 3, title: "Cached Popular", releaseDate: "2025-01-03", posterPath: "/cached.jpg")
    ]
    let cachedResponse = MovieSearchResponse(
      page: 1,
      results: cachedMovies,
      totalPages: 1,
      totalResults: 1
    )
    mockCacheManager.mockCachedPopularMovies = cachedResponse

    // When
    let result = try await repository.getPopularMovies(page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results[0].title, "Cached Popular")
  }

  // MARK: - Get Trending Movies Tests

  func testGetTrendingMoviesSuccess() async throws {
    // Given
    let expectedMovies = [
      Movie(id: 1, title: "Trending Movie 1", releaseDate: "2025-01-01", posterPath: "/trend1.jpg"),
      Movie(id: 2, title: "Trending Movie 2", releaseDate: "2025-01-02", posterPath: "/trend2.jpg"),
    ]
    let expectedResponse = MovieSearchResponse(
      page: 1,
      results: expectedMovies,
      totalPages: 1,
      totalResults: 2
    )
    mockAPIService.mockTrendingResponse = expectedResponse
    mockNetworkService.isConnected = true

    // When
    let result = try await repository.getTrendingMovies(page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 2)
    XCTAssertEqual(result.results[0].title, "Trending Movie 1")
    XCTAssertEqual(result.results[1].title, "Trending Movie 2")
  }

  // MARK: - Get Movie Changes Tests

  func testGetMovieChangesSuccess() async throws {
    // Given
    let expectedChanges = [
      MovieChange(id: 1, adult: false),
      MovieChange(id: 2, adult: true),
    ]
    let expectedResponse = MovieChangesResponse(
      page: 1,
      results: expectedChanges,
      totalPages: 1,
      totalResults: 2
    )
    mockAPIService.mockChangesResponse = expectedResponse
    mockNetworkService.isConnected = true

    // When
    let result = try await repository.getMovieChanges(
      startDate: "2025-01-01", endDate: "2025-01-31", page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 2)
    XCTAssertEqual(result.results[0].id, 1)
    XCTAssertEqual(result.results[1].id, 2)
  }

  // MARK: - Favorites Tests

  func testGetFavorites() async throws {
    // Given
    let expectedFavorites = [
      Movie(
        id: 1, title: "Favorite 1", releaseDate: "2025-01-01", posterPath: "/fav1.jpg",
        isFavorite: true),
      Movie(
        id: 2, title: "Favorite 2", releaseDate: "2025-01-02", posterPath: "/fav2.jpg",
        isFavorite: true),
    ]
    mockCacheManager.mockFavorites = expectedFavorites

    // When
    let result = try await repository.getFavorites()

    // Then
    XCTAssertEqual(result.count, 2)
    XCTAssertEqual(result[0].title, "Favorite 1")
    XCTAssertEqual(result[1].title, "Favorite 2")
  }

  func testToggleFavorite() async throws {
    // Given
    mockCacheManager.mockToggleResult = true

    // When
    let result = try await repository.toggleFavorite(1)

    // Then
    XCTAssertTrue(result)
  }

  func testIsFavorite() async throws {
    // Given
    mockCacheManager.mockIsFavorite = true

    // When
    let result = try await repository.isFavorite(1)

    // Then
    XCTAssertTrue(result)
  }

  // MARK: - Network Availability Tests

  func testIsNetworkAvailable() {
    // Given
    mockNetworkService.isConnected = true

    // When
    let result = repository.isNetworkAvailable()

    // Then
    XCTAssertTrue(result)
  }

  func testIsNetworkUnavailable() {
    // Given
    mockNetworkService.isConnected = false

    // When
    let result = repository.isNetworkAvailable()

    // Then
    XCTAssertFalse(result)
  }
}

// MARK: - Mock Objects

class MockMovieAPIService: MovieAPIService {
  var mockSearchResponse: MovieSearchResponse?
  var mockMovieDetail: MovieDetail?
  var mockPopularResponse: MovieSearchResponse?
  var mockTrendingResponse: MovieSearchResponse?
  var mockChangesResponse: MovieChangesResponse?
  var shouldThrowError = false
  var mockError: Error = NetworkError.invalidResponse

  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    if shouldThrowError {
      throw mockError
    }
    return mockSearchResponse
      ?? MovieSearchResponse(
        page: page,
        results: [],
        totalPages: 1,
        totalResults: 0
      )
  }

  func getMovieDetails(id: Int) async throws -> MovieDetail {
    if shouldThrowError {
      throw mockError
    }
    return mockMovieDetail
      ?? MovieDetail(
        id: id,
        title: "Mock Movie",
        releaseDate: "2025-01-01",
        overview: "Mock overview",
        posterPath: "/mock.jpg"
      )
  }

  func getPopularMovies(page: Int) async throws -> MovieSearchResponse {
    if shouldThrowError {
      throw mockError
    }
    return mockPopularResponse
      ?? MovieSearchResponse(
        page: page,
        results: [],
        totalPages: 1,
        totalResults: 0
      )
  }

  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse {
    if shouldThrowError {
      throw mockError
    }
    return mockTrendingResponse
      ?? MovieSearchResponse(
        page: page,
        results: [],
        totalPages: 1,
        totalResults: 0
      )
  }

  func getMovieChanges(startDate: String, endDate: String, page: Int) async throws
    -> MovieChangesResponse
  {
    if shouldThrowError {
      throw mockError
    }
    return mockChangesResponse
      ?? MovieChangesResponse(
        page: page,
        results: [],
        totalPages: 1,
        totalResults: 0
      )
  }
}

class MockCacheManager {
  var mockCachedSearchResults: MovieSearchResponse?
  var mockCachedMovieDetail: MovieDetail?
  var mockCachedPopularMovies: MovieSearchResponse?
  var mockFavorites: [Movie] = []
  var mockToggleResult = false
  var mockIsFavorite = false

  func getCachedMovies() -> MovieSearchResponse {
    return MovieSearchResponse(
      page: 1,
      results: [],
      totalPages: 1,
      totalResults: 0
    )
  }

  func getCachedMovies(for query: String) -> MovieSearchResponse {
    return mockCachedSearchResults
      ?? MovieSearchResponse(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0
      )
  }

  func saveSearchResults(_ response: MovieSearchResponse, for query: String) {
    // Mock implementation
  }

  func savePopularMovies(_ response: MovieSearchResponse) {
    // Mock implementation
  }

  func getCachedPopularMovies() -> MovieSearchResponse? {
    return mockCachedPopularMovies
      ?? MovieSearchResponse(
        page: 1,
        results: [],
        totalPages: 1,
        totalResults: 0
      )
  }

  func saveMovieDetails(_ movieDetail: MovieDetail) {
    // Mock implementation
  }

  func getCachedMovieDetails(id: Int) -> MovieDetail? {
    return mockCachedMovieDetail
  }

  func clearOldCache(olderThan days: Int) {
    // Mock implementation
  }

  func isNetworkAvailable() -> Bool {
    return true
  }

  // MARK: - Favorites Methods
  func getFavorites() async throws -> [Movie] {
    return mockFavorites
  }

  func saveToFavorites(_ movie: Movie) async throws {
    // Mock implementation
  }

  func removeFromFavorites(_ movieId: Int) async throws {
    // Mock implementation
  }

  func toggleFavorite(_ movieId: Int) async throws -> Bool {
    return mockToggleResult
  }

  func isFavorite(_ movieId: Int) async throws -> Bool {
    return mockIsFavorite
  }
}

class MockNetworkReachabilityService: NetworkReachabilityProtocol {
  var isConnected: Bool = true

  func isNetworkAvailable() -> Bool {
    return isConnected
  }

  func getConnectionTypeString() -> String {
    return "WiFi"
  }

  func addConnectionObserver(_ observer: @escaping (Bool) -> Void) {
    // Mock implementation
  }
}
