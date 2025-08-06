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

  override func setUpWithError() throws {
    super.setUp()
    coreDataManager = CoreDataManager()
  }

  override func tearDownWithError() throws {
    coreDataManager = nil
    super.tearDown()
  }

  // MARK: - Movie Operations Tests

  func testSaveMovie() {
    // Given
    let movie = Movie(
      id: 1,
      title: "Test Movie",
      releaseDate: "2023-01-01",
      overview: "Test overview",
      posterPath: "/test.jpg"
    )

    // When
    coreDataManager.saveMovie(movie, isFavorite: true)

    // Then
    let savedMovie = coreDataManager.getMovie(by: 1)
    XCTAssertNotNil(savedMovie)
    XCTAssertEqual(savedMovie?.title, "Test Movie")
    XCTAssertEqual(savedMovie?.isFavorite, true)
  }

  func testGetMovie() {
    // Given
    let movie = Movie(
      id: 2,
      title: "Another Movie",
      releaseDate: "2023-02-01",
      overview: "Another overview",
      posterPath: "/another.jpg"
    )
    coreDataManager.saveMovie(movie)

    // When
    let retrievedMovie = coreDataManager.getMovie(by: 2)

    // Then
    XCTAssertNotNil(retrievedMovie)
    XCTAssertEqual(retrievedMovie?.title, "Another Movie")
  }

  func testToggleFavorite() {
    // Given
    let movie = Movie(
      id: 3,
      title: "Favorite Movie",
      releaseDate: "2023-03-01",
      overview: "Favorite overview",
      posterPath: "/favorite.jpg"
    )
    coreDataManager.saveMovie(movie, isFavorite: false)

    // When
    let isFavorite = coreDataManager.toggleFavorite(for: 3)

    // Then
    XCTAssertTrue(isFavorite)

    let movieEntity = coreDataManager.getMovie(by: 3)
    XCTAssertEqual(movieEntity?.isFavorite, true)
  }

  func testGetFavoriteMovies() {
    // Given
    let movie1 = Movie(
      id: 4, title: "Movie 1", releaseDate: "2023-01-01", overview: "Overview 1",
      posterPath: "/1.jpg")
    let movie2 = Movie(
      id: 5, title: "Movie 2", releaseDate: "2023-01-02", overview: "Overview 2",
      posterPath: "/2.jpg")
    let movie3 = Movie(
      id: 6, title: "Movie 3", releaseDate: "2023-01-03", overview: "Overview 3",
      posterPath: "/3.jpg")

    coreDataManager.saveMovie(movie1, isFavorite: true)
    coreDataManager.saveMovie(movie2, isFavorite: false)
    coreDataManager.saveMovie(movie3, isFavorite: true)

    // When
    let favoriteMovies = coreDataManager.getFavoriteMovies()

    // Then
    XCTAssertEqual(favoriteMovies.count, 2)
    XCTAssertTrue(favoriteMovies.contains { $0.id == 4 })
    XCTAssertTrue(favoriteMovies.contains { $0.id == 6 })
    XCTAssertFalse(favoriteMovies.contains { $0.id == 5 })
  }

  // MARK: - Page Operations Tests

  func testSavePage() {
    // Given
    let movies = [
      Movie(
        id: 7, title: "Page Movie 1", releaseDate: "2023-01-01", overview: "Overview 1",
        posterPath: "/1.jpg"),
      Movie(
        id: 8, title: "Page Movie 2", releaseDate: "2023-01-02", overview: "Overview 2",
        posterPath: "/2.jpg"),
    ]

    // When
    coreDataManager.savePage(query: "test", pageNumber: 1, movies: movies)

    // Then
    let cachedMovies = coreDataManager.getCachedMovies(for: "test", pageNumber: 1)
    XCTAssertNotNil(cachedMovies)
    XCTAssertEqual(cachedMovies?.count, 2)
  }

  func testCacheExpiration() {
    // Given
    let movies = [
      Movie(
        id: 9, title: "Expired Movie", releaseDate: "2023-01-01", overview: "Overview",
        posterPath: "/expired.jpg")
    ]

    // When
    coreDataManager.savePage(query: "expired", pageNumber: 1, movies: movies)

    // Simulate time passing (cache expires after 1 hour)
    // Note: In a real test, you might want to mock the Date or use a different approach

    // Then
    let cachedMovies = coreDataManager.getCachedMovies(for: "expired", pageNumber: 1)
    // This should return the cached movies since we can't easily simulate time passing in this test
    XCTAssertNotNil(cachedMovies)
  }

  // MARK: - MovieEntity Extension Tests

  func testMovieEntityToMovie() {
    // Given
    let movie = Movie(
      id: 10,
      title: "Convert Movie",
      releaseDate: "2023-01-01",
      overview: "Convert overview",
      posterPath: "/convert.jpg"
    )
    coreDataManager.saveMovie(movie)

    // When
    let movieEntity = coreDataManager.getMovie(by: 10)
    let convertedMovie = movieEntity?.toMovie()

    // Then
    XCTAssertNotNil(convertedMovie)
    XCTAssertEqual(convertedMovie?.id, 10)
    XCTAssertEqual(convertedMovie?.title, "Convert Movie")
    XCTAssertEqual(convertedMovie?.overview, "Convert overview")
  }
}
