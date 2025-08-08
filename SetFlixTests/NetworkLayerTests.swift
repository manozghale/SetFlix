//
//  NetworkLayerTests.swift
//  SetFlixTests
//
//  Created by Manoj on 06/08/2025.
//

import XCTest

@testable import SetFlix

class NetworkLayerTests: XCTestCase {
  var mockURLProtocol: MockURLProtocol!
  var movieAPIService: MovieAPIService!

  override func setUp() {
    super.setUp()
    mockURLProtocol = MockURLProtocol()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    movieAPIService = TMDBAPIService(apiKey: "test_key", session: session)
  }

  override func tearDown() {
    mockURLProtocol = nil
    movieAPIService = nil
    super.tearDown()
  }

  // MARK: - Search Movies Tests

  func testSearchMoviesSuccess() async throws {
    // Given
    let mockResponse = """
      {
        "page": 1,
        "results": [
          {
            "id": 1,
            "title": "Test Movie",
            "release_date": "2025-01-01",
            "poster_path": "/test.jpg"
          }
        ],
        "total_pages": 1,
        "total_results": 1
      }
      """
    MockURLProtocol.mockResponse = mockResponse.data(using: .utf8)
    MockURLProtocol.mockStatusCode = 200

    // When
    let result = try await movieAPIService.searchMovies(query: "test", page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.title, "Test Movie")
    XCTAssertEqual(result.results.first?.id, 1)
  }

  func testSearchMoviesNetworkError() async {
    // Given
    MockURLProtocol.mockError = NetworkError.noInternetConnection

    // When & Then
    do {
      _ = try await movieAPIService.searchMovies(query: "test", page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  func testSearchMoviesInvalidResponse() async {
    // Given
    MockURLProtocol.mockResponse = "Invalid JSON".data(using: .utf8)
    MockURLProtocol.mockStatusCode = 200

    // When & Then
    do {
      _ = try await movieAPIService.searchMovies(query: "test", page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  func testSearchMoviesHTTPError() async {
    // Given
    MockURLProtocol.mockStatusCode = 401

    // When & Then
    do {
      _ = try await movieAPIService.searchMovies(query: "test", page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  // MARK: - Get Movie Details Tests

  func testGetMovieDetailsSuccess() async throws {
    // Given
    let mockResponse = """
      {
        "id": 1,
        "title": "Test Movie",
        "overview": "Test overview",
        "release_date": "2025-01-01",
        "poster_path": "/test.jpg"
      }
      """
    MockURLProtocol.mockResponse = mockResponse.data(using: .utf8)
    MockURLProtocol.mockStatusCode = 200

    // When
    let result = try await movieAPIService.getMovieDetails(id: 1)

    // Then
    XCTAssertEqual(result.id, 1)
    XCTAssertEqual(result.title, "Test Movie")
    XCTAssertEqual(result.overview, "Test overview")
  }

  func testGetMovieDetailsNetworkError() async {
    // Given
    MockURLProtocol.mockError = NetworkError.noInternetConnection

    // When & Then
    do {
      _ = try await movieAPIService.getMovieDetails(id: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  // MARK: - Get Popular Movies Tests

  func testGetPopularMoviesSuccess() async throws {
    // Given
    let mockResponse = """
      {
        "page": 1,
        "results": [
          {
            "id": 1,
            "title": "Popular Movie",
            "release_date": "2025-01-01",
            "poster_path": "/popular.jpg"
          }
        ],
        "total_pages": 1,
        "total_results": 1
      }
      """
    MockURLProtocol.mockResponse = mockResponse.data(using: .utf8)
    MockURLProtocol.mockStatusCode = 200

    // When
    let result = try await movieAPIService.getPopularMovies(page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.title, "Popular Movie")
  }

  func testGetPopularMoviesError() async {
    // Given
    MockURLProtocol.mockStatusCode = 500

    // When & Then
    do {
      _ = try await movieAPIService.getPopularMovies(page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  // MARK: - Get Trending Movies Tests

  func testGetTrendingMoviesSuccess() async throws {
    // Given
    let mockResponse = """
      {
        "page": 1,
        "results": [
          {
            "id": 1,
            "title": "Trending Movie",
            "release_date": "2025-01-01",
            "poster_path": "/trending.jpg"
          }
        ],
        "total_pages": 1,
        "total_results": 1
      }
      """
    MockURLProtocol.mockResponse = mockResponse.data(using: .utf8)
    MockURLProtocol.mockStatusCode = 200

    // When
    let result = try await movieAPIService.getTrendingMovies(page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.title, "Trending Movie")
  }

  func testGetTrendingMoviesError() async {
    // Given
    MockURLProtocol.mockStatusCode = 500

    // When & Then
    do {
      _ = try await movieAPIService.getTrendingMovies(page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }

  // MARK: - Get Movie Changes Tests

  func testGetMovieChangesSuccess() async throws {
    // Given
    let mockResponse = """
      {
        "page": 1,
        "results": [
          {
            "id": 1,
            "adult": false
          }
        ],
        "total_pages": 1,
        "total_results": 1
      }
      """
    MockURLProtocol.mockResponse = mockResponse.data(using: .utf8)
    MockURLProtocol.mockStatusCode = 200

    // When
    let result = try await movieAPIService.getMovieChanges(
      startDate: "2025-01-01", endDate: "2025-01-31", page: 1)

    // Then
    XCTAssertEqual(result.page, 1)
    XCTAssertEqual(result.results.count, 1)
    XCTAssertEqual(result.results.first?.id, 1)
    XCTAssertEqual(result.results.first?.adult, false)
  }

  func testGetMovieChangesError() async {
    // Given
    MockURLProtocol.mockStatusCode = 500

    // When & Then
    do {
      _ = try await movieAPIService.getMovieChanges(
        startDate: "2025-01-01", endDate: "2025-01-31", page: 1)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertTrue(error is NetworkError)
    }
  }
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
  static var mockResponse: Data?
  static var mockStatusCode: Int = 200
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

    let response = HTTPURLResponse(
      url: request.url!,
      statusCode: MockURLProtocol.mockStatusCode,
      httpVersion: "HTTP/1.1",
      headerFields: ["Content-Type": "application/json"]
    )!

    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)

    if let data = MockURLProtocol.mockResponse {
      client?.urlProtocol(self, didLoad: data)
    }

    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {
    // No implementation needed
  }
}
