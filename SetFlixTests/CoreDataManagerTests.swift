//
//  CoreDataManagerTests.swift
//  SetFlixTests
//
//  Created by Manoj on 06/08/2025.
//

import CoreData
import XCTest

@testable import SetFlix

class CoreDataManagerTests: XCTestCase {
  var coreDataManager: CoreDataManager!

  override func setUp() {
    super.setUp()
    // Use the shared instance instead of trying to create a new one
    coreDataManager = CoreDataManager.shared
  }

  override func tearDown() {
    // Clean up test data
    coreDataManager.clearAllData()
    super.tearDown()
  }

  // MARK: - Movie Operations Tests

  func testSaveMovie() {
    // Given
    let movie = Movie(
      id: 1,
      title: "Test Movie",
      releaseDate: "2025-01-01",
      posterPath: "/test.jpg"
    )

    // When
    coreDataManager.saveMovie(movie)

    // Then
    let savedMovie = coreDataManager.getMovie(by: 1)
    XCTAssertNotNil(savedMovie)
    XCTAssertEqual(savedMovie?.title, "Test Movie")
  }

  func testGetMovie() {
    // Given
    let movie = Movie(
      id: 2,
      title: "Another Movie",
      releaseDate: "2025-01-02",
      posterPath: "/another.jpg"
    )
    coreDataManager.saveMovie(movie)

    // When
    let retrievedMovie = coreDataManager.getMovie(by: 2)

    // Then
    XCTAssertNotNil(retrievedMovie)
    XCTAssertEqual(retrievedMovie?.title, "Another Movie")
  }

  func testGetAllMovies() {
    // Given
    let movie1 = Movie(
      id: 3,
      title: "Movie 1",
      releaseDate: "2025-01-01",
      posterPath: "/movie1.jpg"
    )
    let movie2 = Movie(
      id: 4,
      title: "Movie 2",
      releaseDate: "2025-01-02",
      posterPath: "/movie2.jpg"
    )
    coreDataManager.saveMovie(movie1)
    coreDataManager.saveMovie(movie2)

    // When
    let allMovies = coreDataManager.getAllMovies()

    // Then
    XCTAssertEqual(allMovies.count, 2)
    XCTAssertTrue(allMovies.contains { $0.title == "Movie 1" })
    XCTAssertTrue(allMovies.contains { $0.title == "Movie 2" })
  }

  func testGetFavoriteMovies() {
    // Given
    let favoriteMovie = Movie(
      id: 5,
      title: "Favorite Movie",
      releaseDate: "2025-01-01",
      posterPath: "/favorite.jpg"
    )
    coreDataManager.saveMovie(favoriteMovie, isFavorite: true)

    let regularMovie = Movie(
      id: 6,
      title: "Regular Movie",
      releaseDate: "2025-01-02",
      posterPath: "/regular.jpg"
    )
    coreDataManager.saveMovie(regularMovie, isFavorite: false)

    // When
    let favoriteMovies = coreDataManager.getFavoriteMovies()

    // Then
    XCTAssertEqual(favoriteMovies.count, 1)
    XCTAssertEqual(favoriteMovies.first?.title, "Favorite Movie")
  }

  func testToggleFavorite() {
    // Given
    let movie = Movie(
      id: 7,
      title: "Toggle Movie",
      releaseDate: "2025-01-01",
      posterPath: "/toggle.jpg"
    )
    coreDataManager.saveMovie(movie, isFavorite: false)

    // When - Toggle to favorite
    let isFavorite = coreDataManager.toggleFavorite(for: 7)

    // Then
    XCTAssertTrue(isFavorite)
    let favoriteMovies = coreDataManager.getFavoriteMovies()
    XCTAssertTrue(favoriteMovies.contains { $0.id == 7 })

    // When - Toggle back to not favorite
    let isNotFavorite = coreDataManager.toggleFavorite(for: 7)

    // Then
    XCTAssertFalse(isNotFavorite)
    let updatedFavoriteMovies = coreDataManager.getFavoriteMovies()
    XCTAssertFalse(updatedFavoriteMovies.contains { $0.id == 7 })
  }

  func testIsMovieFavorite() {
    // Given
    let movie = Movie(
      id: 8,
      title: "Check Favorite",
      releaseDate: "2025-01-01",
      posterPath: "/check.jpg"
    )
    coreDataManager.saveMovie(movie, isFavorite: true)

    // When
    let favoriteStatus = coreDataManager.getFavoriteStatus(for: [8])
    let isFavorite = favoriteStatus[8] ?? false

    // Then
    XCTAssertTrue(isFavorite)
  }

  // MARK: - Page Operations Tests

  func testSavePage() {
    // Given
    let movies = [
      Movie(
        id: 9,
        title: "Page Movie 1",
        releaseDate: "2025-01-01",
        posterPath: "/page1.jpg"
      ),
      Movie(
        id: 10,
        title: "Page Movie 2",
        releaseDate: "2025-01-02",
        posterPath: "/page2.jpg"
      ),
    ]

    // When
    coreDataManager.savePage(query: "test", pageNumber: 1, movies: movies)

    // Then
    let pageEntity = coreDataManager.getPageEntity(query: "test", pageNumber: 1)
    XCTAssertNotNil(pageEntity)
    XCTAssertEqual(pageEntity?.movies?.count, 2)
  }

  func testGetPageEntity() {
    // Given
    let movies = [
      Movie(
        id: 11,
        title: "Get Page Movie",
        releaseDate: "2025-01-01",
        posterPath: "/getpage.jpg"
      )
    ]
    coreDataManager.savePage(query: "search", pageNumber: 1, movies: movies)

    // When
    let pageEntity = coreDataManager.getPageEntity(query: "search", pageNumber: 1)

    // Then
    XCTAssertNotNil(pageEntity)
    XCTAssertEqual(pageEntity?.query, "search")
    XCTAssertEqual(pageEntity?.pageNumber, 1)
  }

  func testClearOldCache() {
    // Given
    let oldMovies = [
      Movie(
        id: 12,
        title: "Expired Movie",
        releaseDate: "2025-01-01",
        posterPath: "/expired.jpg"
      )
    ]
    coreDataManager.savePage(query: "old", pageNumber: 1, movies: oldMovies)

    // Simulate old timestamp by directly modifying the entity
    if let pageEntity = coreDataManager.getPageEntity(query: "old", pageNumber: 1) {
      pageEntity.timestamp = Calendar.current.date(byAdding: .day, value: -10, to: Date())
      coreDataManager.saveContext()
    }

    // When
    coreDataManager.clearExpiredCache()

    // Then
    let pageEntity = coreDataManager.getPageEntity(query: "old", pageNumber: 1)
    XCTAssertNil(pageEntity)
  }

  // MARK: - MovieEntity Extension Tests

  func testMovieEntityToMovie() {
    // Given
    let movie = Movie(
      id: 13,
      title: "Convert Movie",
      releaseDate: "2025-01-01",
      posterPath: "/convert.jpg"
    )
    coreDataManager.saveMovie(movie)

    // When
    let movieEntity = coreDataManager.getMovie(by: 13)
    let convertedMovie = movieEntity?.toMovie()

    // Then
    XCTAssertNotNil(convertedMovie)
    XCTAssertEqual(convertedMovie?.id, 13)
    XCTAssertEqual(convertedMovie?.title, "Convert Movie")
    XCTAssertEqual(convertedMovie?.releaseDate, "2025-01-01")
    XCTAssertEqual(convertedMovie?.posterPath, "/convert.jpg")
  }

  // MARK: - Helper Methods

  private func clearAllData() {
    // This is a helper method to clean up test data
    // Implementation would depend on your CoreDataManager structure
  }
}
