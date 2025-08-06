//
//  NetworkLayerTests.swift
//  SetFlixTests
//
//  Created by Manoj on 06/08/2025.
//

import XCTest

@testable import SetFlix

class NetworkLayerTests: XCTestCase {

  var apiService: MovieAPIService!
  var mockSession: URLSession!

  override func setUpWithError() throws {
    super.setUp()

    // Create a mock URLSession for testing
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    mockSession = URLSession(configuration: config)

    // Initialize API service with mock session
    apiService = TMDBAPIService(apiKey: "test_api_key", session: mockSession)
  }

  override func tearDownWithError() throws {
    apiService = nil
    mockSession = nil
    super.tearDown()
  }

  // MARK: - Movie Search Tests

  func testSearchMoviesSuccess() async throws {
    // Given
    let mockResponse = MovieSearchResponse(
      page: 1,
      results: [
        Movie(
          id: 1,
          title: "Test Movie",
          releaseDate: "2023-01-01",
          overview: "Test overview",
          posterPath: "/test.jpg"
        )
      ],
      totalPages: 1,
      totalResults: 1
    )

    MockURLProtocol.mockData = try JSONEncoder().encode(mockResponse)
    MockURLProtocol.mockResponse = HTTPURLResponse(
      url: URL(string: "https://api.themoviedb.org/3/search/movie")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )

    // When
    let result = try await apiService.searchMovies(query: "test", page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.title, "Test Movie")
  }

  func testSearchMoviesNetworkError() async {
    // Given
    MockURLProtocol.mockError = NetworkError.noInternetConnection

    // When & Then
    do {
      _ = try await apiService.searchMovies(query: "test", page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  // MARK: - Movie Details Tests

  func testGetMovieDetailsSuccess() async throws {
    // Given
    let mockMovieDetail = MovieDetail(
      id: 1,
      title: "Test Movie",
      releaseDate: "2023-01-01",
      overview: "Test overview",
      posterPath: "/test.jpg"
    )

    MockURLProtocol.mockData = try JSONEncoder().encode(mockMovieDetail)
    MockURLProtocol.mockResponse = HTTPURLResponse(
      url: URL(string: "https://api.themoviedb.org/3/movie/1")!,
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )

    // When
    let result = try await apiService.getMovieDetails(id: 1)

    // Then
    XCTAssertEqual(result.id, 1)
    XCTAssertEqual(result.title, "Test Movie")
    XCTAssertEqual(result.overview, "Test overview")
  }

  // MARK: - Error Handling Tests

  func testUnauthorizedError() async {
    // Given
    MockURLProtocol.mockResponse = HTTPURLResponse(
      url: URL(string: "https://api.themoviedb.org/3/search/movie")!,
      statusCode: 401,
      httpVersion: nil,
      headerFields: nil
    )

    // When & Then
    do {
      _ = try await apiService.searchMovies(query: "test", page: 1)
      XCTFail("Expected unauthorized error")
    } catch let error as NetworkError {
      XCTAssertEqual(error, .unauthorized)
    } catch {
      XCTFail("Expected NetworkError.unauthorized")
    }
  }

  func testServerError() async {
    // Given
    MockURLProtocol.mockResponse = HTTPURLResponse(
      url: URL(string: "https://api.themoviedb.org/3/search/movie")!,
      statusCode: 500,
      httpVersion: nil,
      headerFields: nil
    )

    // When & Then
    do {
      _ = try await apiService.searchMovies(query: "test", page: 1)
      XCTFail("Expected server error")
    } catch let error as NetworkError {
      XCTAssertEqual(error, .serverError(500))
    } catch {
      XCTFail("Expected NetworkError.serverError")
    }
  }
}

// MARK: - Mock URL Protocol
class MockURLProtocol: URLProtocol {
  static var mockData: Data?
  static var mockResponse: HTTPURLResponse?
  static var mockError: Error?

  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    return request
  }

  override func startLoading() {
    if let error = MockURLProtocol.mockError {
      client?.urlProtocol(self, didFailWithError: error)
      return
    }

    if let response = MockURLProtocol.mockResponse {
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
    }

    if let data = MockURLProtocol.mockData {
      client?.urlProtocol(self, didLoad: data)
    }

    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {
    // Reset mock data
    MockURLProtocol.mockData = nil
    MockURLProtocol.mockResponse = nil
    MockURLProtocol.mockError = nil
  }
}
