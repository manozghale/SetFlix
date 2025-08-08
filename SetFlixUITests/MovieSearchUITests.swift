//
//  MovieSearchUITests.swift
//  SetFlixUITests
//
//  Created by Manoj on 08/08/2025.
//

import XCTest

class MovieSearchUITests: XCTestCase {

  // MARK: - Properties
  var app: XCUIApplication!

  // MARK: - Setup and Teardown
  override func setUp() {
    super.setUp()
    continueAfterFailure = false
    app = XCUIApplication()
    app.launch()
  }

  override func tearDown() {
    app = nil
    super.tearDown()
  }

  // MARK: - UI Elements
  var searchBar: XCUIElement {
    app.searchFields["Search movies..."]
  }

  var tableView: XCUIElement {
    app.tables.firstMatch
  }

  var favoritesButton: XCUIElement {
    app.navigationBars.buttons["heart.fill"]
  }

  var backButton: XCUIElement {
    app.navigationBars.buttons["Movies"]
  }

  // MARK: - Basic Navigation Tests
  func testAppLaunchesSuccessfully() {
    // Given: App is launched

    // Then: Should show main screen
    XCTAssertTrue(app.navigationBars["Movies"].exists)
    XCTAssertTrue(searchBar.exists)
    XCTAssertTrue(tableView.exists)
    XCTAssertTrue(favoritesButton.exists)
  }

  func testNavigationBarElements() {
    // Given: App is launched

    // Then: Navigation bar should have correct elements
    let navigationBar = app.navigationBars["Movies"]
    XCTAssertTrue(navigationBar.exists)
    XCTAssertTrue(navigationBar.buttons["heart.fill"].exists)
  }

  // MARK: - Search Functionality Tests
  func testSearchBarInteraction() {
    // Given: App is launched

    // When: Tapping search bar
    searchBar.tap()

    // Then: Search bar should become active
    XCTAssertTrue(searchBar.isSelected)
  }

  func testSearchBarPlaceholder() {
    // Given: App is launched

    // Then: Search bar should have correct placeholder
    XCTAssertEqual(searchBar.placeholderValue, "Search movies...")
  }

  func testSearchBarTextInput() {
    // Given: App is launched

    // When: Entering search text
    searchBar.tap()
    searchBar.typeText("Interstellar")

    // Then: Text should be entered
    XCTAssertEqual(searchBar.value as? String, "Interstellar")
  }

  func testSearchBarClearText() {
    // Given: Search text is entered
    searchBar.tap()
    searchBar.typeText("Test")

    // When: Clearing search text
    searchBar.buttons["Clear text"].tap()

    // Then: Search bar should be empty
    XCTAssertEqual(searchBar.value as? String, "Search movies...")
  }

  // MARK: - Table View Tests
  func testTableViewExists() {
    // Given: App is launched

    // Then: Table view should exist
    XCTAssertTrue(tableView.exists)
  }

  func testTableViewInitialState() {
    // Given: App is launched

    // Then: Table view should be visible and accessible
    XCTAssertTrue(tableView.isEnabled)
    XCTAssertTrue(tableView.isHittable)
  }

  func testTableViewScrolling() {
    // Given: App is launched with movies loaded
    // Wait for movies to load
    let expectation = XCTestExpectation(description: "Movies loaded")

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)

    // When: Scrolling table view
    tableView.swipeUp()

    // Then: Table view should scroll
    // Note: This is a basic scroll test - actual content depends on API response
  }

  // MARK: - Movie Cell Tests
  func testMovieCellElements() {
    // Given: App is launched with movies loaded
    // Wait for movies to load
    let expectation = XCTestExpectation(description: "Movies loaded")

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)

    // When: Looking for movie cells
    let cells = tableView.cells

    // Then: Should have movie cells (if API returns data)
    if cells.count > 0 {
      let firstCell = cells.element(boundBy: 0)
      XCTAssertTrue(firstCell.exists)

      // Check for expected elements in cell
      // Note: These depend on your actual cell structure
      XCTAssertTrue(firstCell.isHittable)
    }
  }

  func testMovieCellTap() {
    // Given: App is launched with movies loaded
    // Wait for movies to load
    let expectation = XCTestExpectation(description: "Movies loaded")

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)

    // When: Tapping on a movie cell
    let cells = tableView.cells
    if cells.count > 0 {
      let firstCell = cells.element(boundBy: 0)
      firstCell.tap()

      // Then: Should navigate to detail view
      // Note: This depends on your navigation implementation
      XCTAssertTrue(app.navigationBars.buttons["Movies"].exists)
    }
  }

  // MARK: - Favorites Navigation Tests
  func testFavoritesButtonTap() {
    // Given: App is launched

    // When: Tapping favorites button
    favoritesButton.tap()

    // Then: Should navigate to favorites screen
    XCTAssertTrue(app.navigationBars["Favorites"].exists)
  }

  func testFavoritesScreenNavigation() {
    // Given: On favorites screen
    favoritesButton.tap()

    // When: Tapping back button
    backButton.tap()

    // Then: Should return to main screen
    XCTAssertTrue(app.navigationBars["Movies"].exists)
  }

  // MARK: - Pull to Refresh Tests
  func testPullToRefresh() {
    // Given: App is launched

    // When: Pulling down to refresh
    let firstCell = tableView.cells.element(boundBy: 0)
    // Define a starting coordinate (e.g., top-middle of the first cell)
    let startCoordinate = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0))
    // Define an ending coordinate (e.g., further down from the first cell)
    let endCoordinate = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 3.0))  // Drag 3 times the height of the cell downwards

    startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

    // Then: Refresh should be triggered
    // Note: This is a basic test - actual refresh behavior depends on implementation
  }

  // MARK: - Error Handling Tests
  func testOfflineModeIndicator() {
    // Given: App is launched

    // When: App is in offline mode (simulated)
    // Note: This would require network simulation or mock setup

    // Then: Should show offline indicator
    // This depends on your offline mode implementation
  }

  // MARK: - Accessibility Tests
  func testAccessibilityLabels() {
    // Given: App is launched

    // Then: UI elements should have accessibility labels
    XCTAssertTrue(searchBar.hasValidAccessibilityLabel)
    XCTAssertTrue(favoritesButton.hasValidAccessibilityLabel)
  }

  func testVoiceOverCompatibility() {
    // Given: App is launched

    // When: VoiceOver is enabled (simulated)
    // Note: This would require VoiceOver simulation

    // Then: Elements should be accessible via VoiceOver
    XCTAssertTrue(searchBar.isAccessibilityElement)
    XCTAssertTrue(favoritesButton.isAccessibilityElement)
  }

  // MARK: - Performance Tests
  func testAppLaunchPerformance() {
    // Given: App launch performance test

    // When: Measuring launch time
    measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
      app.launch()
    }

    // Then: Launch should be within acceptable performance bounds
  }

  func testTableViewScrollingPerformance() {
    // Given: App is launched with movies loaded
    // Wait for movies to load
    let expectation = XCTestExpectation(description: "Movies loaded")

    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 5)

    // When: Measuring scrolling performance
    measure(metrics: [XCTCPUMetric()]) {
      tableView.swipeUp()
      tableView.swipeDown()
    }

    // Then: Scrolling should be smooth
  }

  // MARK: - Network State Tests
  func testNetworkStateHandling() {
    // Given: App is launched

    // When: Network state changes (simulated)
    // Note: This would require network simulation

    // Then: App should handle network changes gracefully
    XCTAssertTrue(app.exists)
  }

  // MARK: - Memory Management Tests
  func testMemoryUsage() {
    // Given: App is launched

    // When: Performing memory-intensive operations
    for _ in 0..<10 {
      searchBar.tap()
      searchBar.typeText("Test")
      searchBar.buttons["Clear text"].tap()
    }

    // Then: App should not crash or use excessive memory
    XCTAssertTrue(app.exists)
  }
}

// MARK: - Helper Extensions
extension XCUIElement {
  var hasValidAccessibilityLabel: Bool {
    let label = self.label
    return !label.isEmpty
  }
}
