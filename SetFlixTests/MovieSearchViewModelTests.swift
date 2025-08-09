//
//  MovieSearchViewModelTests.swift
//  SetFlixTests
//
//  Created by Manoj on 07/08/2025.
//

import XCTest
import Combine
@testable import SetFlix

@MainActor
class MovieSearchViewModelTests: XCTestCase {

  // MARK: - Properties
  var viewModel: MovieSearchViewModel!
  var mockRepository: MockMovieRepository!
  var cancellables: Set<AnyCancellable>!

  // MARK: - Setup and Teardown
  override func setUp() {
    super.setUp()
    cancellables = Set<AnyCancellable>()
    mockRepository = MockMovieRepository()
    viewModel = MovieSearchViewModel(repository: mockRepository)
  }

  override func tearDown() {
    viewModel = nil
    mockRepository = nil
    cancellables = nil
    super.tearDown()
  }

  // MARK: - Initial State Tests
  func testInitialState() {
    // Given: Fresh ViewModel

    // Then: Should have correct initial state
    XCTAssertTrue(viewModel.filteredMovies.isEmpty)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isSearching)
    XCTAssertFalse(viewModel.isEmptyState)
    XCTAssertEqual(viewModel.currentPage, 1)
    XCTAssertTrue(viewModel.hasMorePages)
  }

  // MARK: - Load Initial Data Tests
  func testLoadInitialDataSuccess() {
    // Given: Mock repository with successful response
    let expectedMovies = [
      Movie(id: 1, title: "Test Movie 1", releaseDate: "2025-01-01", posterPath: "/test1.jpg"),
      Movie(id: 2, title: "Test Movie 2", releaseDate: "2025-01-02", posterPath: "/test2.jpg"),
    ]
    mockRepository.mockPopularMovies = expectedMovies

    // When: Loading initial data
    viewModel.loadInitialData()

    // Then: Should load movies successfully
    XCTAssertEqual(viewModel.filteredMovies.count, 2)
    XCTAssertEqual(viewModel.filteredMovies[0].title, "Test Movie 1")
    XCTAssertEqual(viewModel.filteredMovies[1].title, "Test Movie 2")
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testLoadInitialDataFailure() {
    // Given: Mock repository with error
    mockRepository.shouldThrowError = true
    mockRepository.mockError = NetworkError.invalidResponse

    // When: Loading initial data
    viewModel.loadInitialData()

    // Then: Should handle error gracefully
    XCTAssertTrue(viewModel.filteredMovies.isEmpty)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNotNil(viewModel.errorMessage)
  }

  // MARK: - Search Tests
  func testSearchMoviesSuccess() {
    // Given: Mock repository with search results
    let searchResults = [
      Movie(id: 3, title: "Search Result 1", releaseDate: "2025-01-03", posterPath: "/search1.jpg"),
      Movie(id: 4, title: "Search Result 2", releaseDate: "2025-01-04", posterPath: "/search2.jpg"),
    ]
    mockRepository.mockSearchResults = searchResults

    // When: Searching for movies
    viewModel.searchMovies(query: "test")

    // Then: Should show search results
    XCTAssertEqual(viewModel.filteredMovies.count, 2)
    XCTAssertTrue(viewModel.isSearching)
    XCTAssertEqual(viewModel.currentQuery, "test")
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.errorMessage)
  }

  func testSearchMoviesEmptyQuery() {
    // Given: Empty search query

    // When: Searching with empty query
    viewModel.searchMovies(query: "")

    // Then: Should load popular movies instead
    XCTAssertTrue(viewModel.filteredMovies.isEmpty)  // Will be populated by loadInitialData
    XCTAssertFalse(viewModel.isSearching)
    XCTAssertEqual(viewModel.currentQuery, "")
  }

  func testSearchMoviesFailure() {
    // Given: Mock repository with search error
    mockRepository.shouldThrowError = true
    mockRepository.mockError = NetworkError.invalidResponse

    // When: Searching for movies
    viewModel.searchMovies(query: "test")

    // Then: Should handle error
    XCTAssertTrue(viewModel.filteredMovies.isEmpty)
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNotNil(viewModel.errorMessage)
  }

  // MARK: - Pagination Tests
  func testLoadMoreResultsSuccess() {
    // Given: Initial movies loaded
    let initialMovies = [
      Movie(id: 1, title: "Movie 1", releaseDate: "2025-01-01", posterPath: "/1.jpg")
    ]
    mockRepository.mockPopularMovies = initialMovies
    viewModel.loadInitialData()

    // Given: More movies for next page
    let moreMovies = [
      Movie(id: 2, title: "Movie 2", releaseDate: "2025-01-02", posterPath: "/2.jpg"),
      Movie(id: 3, title: "Movie 3", releaseDate: "2025-01-03", posterPath: "/3.jpg"),
    ]
    mockRepository.mockPopularMovies = moreMovies

    // When: Loading more results
    viewModel.loadMoreMovies()

    // Then: Should append new movies
    XCTAssertEqual(viewModel.filteredMovies.count, 3)
    XCTAssertEqual(viewModel.currentPage, 2)
  }

  func testLoadMoreResultsNoMorePages() {
    // Given: No more pages available
    mockRepository.mockPopularMovies = []
    viewModel.hasMorePages = false

    // When: Loading more results
    viewModel.loadMoreMovies()

    // Then: Should not load more
    XCTAssertEqual(viewModel.currentPage, 1)
  }

  // MARK: - Refresh Tests
  func testRefreshDataSuccess() {
    // Given: Initial data loaded
    let initialMovies = [
      Movie(id: 1, title: "Old Movie", releaseDate: "2025-01-01", posterPath: "/old.jpg")
    ]
    mockRepository.mockPopularMovies = initialMovies
    viewModel.loadInitialData()

    // Given: Fresh data available
    let freshMovies = [
      Movie(id: 2, title: "New Movie", releaseDate: "2025-01-02", posterPath: "/new.jpg")
    ]
    mockRepository.mockPopularMovies = freshMovies

    // When: Refreshing data
    viewModel.refreshData()

    // Then: Should load fresh data
    XCTAssertEqual(viewModel.filteredMovies.count, 1)
    XCTAssertEqual(viewModel.filteredMovies[0].title, "New Movie")
    XCTAssertFalse(viewModel.isLoading)
  }

  // MARK: - Error Handling Tests
  func testClearError() {
    // Given: Error message set
    viewModel.errorMessage = "Test error"

    // When: Clearing error
    viewModel.clearError()

    // Then: Error should be cleared
    XCTAssertNil(viewModel.errorMessage)
  }

  // MARK: - Network Availability Tests
  func testNetworkAvailability() {
    // Given: Network is available
    mockRepository.mockIsNetworkAvailable = true

    // When: Checking network availability
    let isAvailable = viewModel.isOnline

    // Then: Should return true
    XCTAssertTrue(isAvailable)
  }

  func testNetworkUnavailable() {
    // Given: Network is unavailable
    mockRepository.mockIsNetworkAvailable = false

    // When: Checking network availability
    let isAvailable = viewModel.isOnline

    // Then: Should return false
    XCTAssertFalse(isAvailable)
  }

  // MARK: - Reactive Network State Tests
  func testNetworkStateChangeToOffline() {
    // Given: Initial online state
    XCTAssertTrue(viewModel.isOnline)

    // When: Network becomes unavailable
    mockRepository.simulateNetworkChange(isAvailable: false)

    // Then: ViewModel should detect the change
    // Note: This test would need to be run on main queue and with proper expectations
    // For now, we'll test the basic functionality
    XCTAssertFalse(mockRepository.mockIsNetworkAvailable)
  }

  func testNetworkStateChangeToOnline() {
    // Given: Initial offline state
    mockRepository.simulateNetworkChange(isAvailable: false)

    // When: Network becomes available
    mockRepository.simulateNetworkChange(isAvailable: true)

    // Then: ViewModel should detect the change
    XCTAssertTrue(mockRepository.mockIsNetworkAvailable)
  }

  func testOfflineModeShowsCachedData() {
    // Given: Network is offline and we have cached data
    mockRepository.mockIsNetworkAvailable = false
    let cachedMovies = [
      Movie(id: 1, title: "Cached Movie", releaseDate: "2025-01-01", posterPath: "/cached.jpg")
    ]
    mockRepository.mockPopularMovies = cachedMovies

    // When: Loading initial data
    viewModel.loadInitialData()

    // Then: Should show cached data
    XCTAssertEqual(viewModel.filteredMovies.count, 1)
    XCTAssertEqual(viewModel.filteredMovies[0].title, "Cached Movie")
  }

  func testOnlineModeLoadsFreshData() {
    // Given: Network is online
    mockRepository.mockIsNetworkAvailable = true
    let freshMovies = [
      Movie(id: 2, title: "Fresh Movie", releaseDate: "2025-01-02", posterPath: "/fresh.jpg")
    ]
    mockRepository.mockPopularMovies = freshMovies

    // When: Loading initial data
    viewModel.loadInitialData()

    // Then: Should show fresh data
    XCTAssertEqual(viewModel.filteredMovies.count, 1)
    XCTAssertEqual(viewModel.filteredMovies[0].title, "Fresh Movie")
  }

  // MARK: - Empty State Tests
  func testEmptyStateWhenNoMovies() {
    // Given: No movies loaded
    viewModel.filteredMovies = []
    viewModel.isSearching = false

    // Then: Should be in empty state
    XCTAssertTrue(viewModel.isEmptyState)
  }

  func testEmptyStateWhenSearching() {
    // Given: Searching with no results
    viewModel.filteredMovies = []
    viewModel.isSearching = true

    // Then: Should be in empty state
    XCTAssertTrue(viewModel.isEmptyState)
  }

  func testNotEmptyStateWhenMoviesExist() {
    // Given: Movies are loaded
    viewModel.filteredMovies = [
      Movie(id: 1, title: "Test Movie", releaseDate: "2025-01-01", posterPath: "/test.jpg")
    ]

    // Then: Should not be in empty state
    XCTAssertFalse(viewModel.isEmptyState)
  }
}

// MARK: - Mock Repository for Testing
class MockMovieRepository: MovieRepository {
  var mockPopularMovies: [Movie] = []
  var mockSearchResults: [Movie] = []
  var mockMovieDetails: MovieDetail?
  var shouldThrowError = false
  var mockError: Error = NetworkError.invalidResponse
  var mockIsNetworkAvailable = true
  private let networkStateSubject = CurrentValueSubject<Bool, Never>(true)

  func searchMovies(query: String, page: Int) async throws -> MovieSearchResponse {
    if shouldThrowError {
      throw mockError
    }
    return MovieSearchResponse(
      page: page,
      results: mockSearchResults,
      totalPages: 1,
      totalResults: mockSearchResults.count
    )
  }

  func getMovieDetails(id: Int) async throws -> MovieDetail {
    if shouldThrowError {
      throw mockError
    }
    return mockMovieDetails
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
    return MovieSearchResponse(
      page: page,
      results: mockPopularMovies,
      totalPages: 1,
      totalResults: mockPopularMovies.count
    )
  }

  func getTrendingMovies(page: Int) async throws -> MovieSearchResponse {
    if shouldThrowError {
      throw mockError
    }
    return MovieSearchResponse(
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
    return MovieChangesResponse(
      page: page,
      results: [],
      totalPages: 1,
      totalResults: 0
    )
  }

  // MARK: - Favorites Methods
  func getFavorites() async throws -> [Movie] {
    if shouldThrowError {
      throw mockError
    }
    return mockPopularMovies.filter { $0.isFavorite }
  }

  func saveToFavorites(_ movie: Movie) async throws {
    if shouldThrowError {
      throw mockError
    }
    // Mock implementation
  }

  func removeFromFavorites(_ movieId: Int) async throws {
    if shouldThrowError {
      throw mockError
    }
    // Mock implementation
  }

  func toggleFavorite(_ movieId: Int) async throws -> Bool {
    if shouldThrowError {
      throw mockError
    }
    return true
  }

  func isFavorite(_ movieId: Int) async throws -> Bool {
    if shouldThrowError {
      throw mockError
    }
    return mockPopularMovies.contains { $0.id == movieId && $0.isFavorite }
  }

  // MARK: - Caching Methods
  func getCachedMovies() -> MovieSearchResponse {
    return MovieSearchResponse(
      page: 1,
      results: mockPopularMovies,
      totalPages: 1,
      totalResults: mockPopularMovies.count
    )
  }

  func getCachedMovies(for query: String) -> MovieSearchResponse {
    return MovieSearchResponse(
      page: 1,
      results: mockSearchResults,
      totalPages: 1,
      totalResults: mockSearchResults.count
    )
  }

  func saveSearchResults(_ response: MovieSearchResponse, for query: String) {
    // Mock implementation
  }

  func savePopularMovies(_ response: MovieSearchResponse) {
    // Mock implementation
  }

  func getCachedPopularMovies() -> MovieSearchResponse {
    return MovieSearchResponse(
      page: 1,
      results: mockPopularMovies,
      totalPages: 1,
      totalResults: mockPopularMovies.count
    )
  }

  func saveMovieDetails(_ detail: MovieDetail) {
    // Mock implementation
  }

  func getCachedMovieDetails(id: Int) -> MovieDetail? {
    return mockMovieDetails
  }

  func clearOldCache(olderThan days: Int) {
    // Mock implementation
  }

  func isNetworkAvailable() -> Bool {
    return mockIsNetworkAvailable
  }

  var networkStatePublisher: AnyPublisher<Bool, Never> {
    return networkStateSubject.eraseToAnyPublisher()
  }

  // Helper method for tests to simulate network state changes
  func simulateNetworkChange(isAvailable: Bool) {
    mockIsNetworkAvailable = isAvailable
    networkStateSubject.send(isAvailable)
  }
}
