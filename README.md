# SetFlix - iOS Movie Discovery App

A modern iOS movie discovery application built with Swift, featuring MVVM architecture, offline capabilities, and comprehensive testing.

## 📱 Features

- **Movie Search & Discovery**: Search for movies using TMDB API
- **Offline-Focused Design**: Works seamlessly without internet connection
- **Favorites System**: Save and manage favorite movies
- **Smart Caching**: Intelligent data caching for optimal performance
- **Tab Bar Navigation**: Easy navigation between Movies and Favorites
- **Pull-to-Refresh**: Real-time data updates
- **Comprehensive Testing**: Unit tests and UI tests for all components

## 🏗️ Architecture

- **MVVM (Model-View-ViewModel)**: Clean separation of concerns
- **Repository Pattern**: Data abstraction layer
- **Core Data**: Local persistence for favorites and cached data
- **Combine Framework**: Reactive programming for data binding
- **Protocol-Oriented Design**: Testable and maintainable code
- **Online-First Design**: Prioritizes fresh data with intelligent offline fallback

## 📋 Prerequisites

- **Xcode 16.0+** (Latest version recommended)
- **iOS 15.6+** deployment target
- **macOS 14.0+** (for development)
- **TMDB API Key** (for movie data)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd SetFlix
```

### 2. Configure API Key

1. Get a free API key from [TMDB](https://www.themoviedb.org/settings/api)
2. Open `SetFlix/Config.plist`
3. Replace `YOUR_API_KEY_HERE` with your actual TMDB API key:

```xml
<key>TMDB_API_KEY</key>
<string>your_actual_api_key_here</string>
```

### 3. Open the Project

```bash
open SetFlix.xcodeproj
```

### 4. Build and Run

#### Method 1: Using Xcode IDE (Recommended)

1. **Select Target Device**:

   - Choose iOS Simulator (iPhone 16 recommended)
   - Or connect a physical iOS device

2. **Build and Run**:

   - Press `⌘ + R` to build and run
   - Or click the **Run** button (▶️) in Xcode toolbar
   - Or go to **Product → Run** in the menu

3. **First Launch**:
   - App will attempt to load fresh data first (online-first design)
   - Shows loading indicator during data fetch
   - Falls back to cached data if network is unavailable
   - Pull-to-refresh to force fresh data update

#### Method 2: Using Command Line

```bash
# Build the project
xcodebuild -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run the app
xcodebuild -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16' run
```

## �� Testing Guide

### Running Tests

#### Method 1: Using Xcode IDE

1. **Run All Tests**:

   - Press `⌘ + U` to run all tests
   - Or go to **Product → Test** in the menu
   - Or click the **Test** button in the toolbar

2. **Run Specific Test Classes**:

   - Right-click on any test file in the navigator
   - Select **"Test [ClassName]"**
   - Or click the diamond icon next to the class name

3. **Run Individual Test Methods**:

   - Click the diamond icon next to any test method
   - Or right-click on the method and select **"Test [MethodName]"**

4. **View Test Results**:
   - Press `⌘ + 6` to open Test Navigator
   - Green checkmarks ✅ = Passed tests
   - Red X marks ❌ = Failed tests
   - Gray diamonds ◇ = Tests not yet run

#### Method 2: Using Command Line

```bash
# Run all tests
xcodebuild test -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16'

# Run only unit tests (excluding UI tests)
xcodebuild test -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SetFlixTests

# Run only UI tests
xcodebuild test -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SetFlixUITests

# Run specific test class
xcodebuild test -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:SetFlixTests/CoreDataManagerTests

# Run with verbose output
xcodebuild test -project SetFlix.xcodeproj -scheme SetFlix -destination 'platform=iOS Simulator,name=iPhone 16' -verbose
```

### Test Suite Overview

#### 1. CoreDataManagerTests.swift

- **Purpose**: Tests Core Data operations
- **Key Tests**:
  - `testSaveMovie()` - Tests saving movies to Core Data
  - `testGetFavoriteStatus()` - Tests retrieving favorite status
  - `testClearExpiredCache()` - Tests cache cleanup
  - `testDeleteMovie()` - Tests movie deletion

#### 2. MovieRepositoryTests.swift

- **Purpose**: Tests data layer and API integration
- **Key Tests**:
  - `testSearchMoviesSuccess()` - Tests successful movie search
  - `testGetMovieDetailsSuccess()` - Tests movie detail retrieval
  - `testGetTrendingMoviesSuccess()` - Tests trending movies
  - `testNetworkUnavailable()` - Tests offline behavior

#### 3. MovieSearchViewModelTests.swift

- **Purpose**: Tests MVVM ViewModel logic
- **Key Tests**:
  - `testLoadInitialDataSuccess()` - Tests initial data loading
  - `testSearchMoviesSuccess()` - Tests search functionality
  - `testLoadMoreResultsSuccess()` - Tests pagination
  - `testNetworkAvailability()` - Tests network state handling

#### 4. NetworkLayerTests.swift

- **Purpose**: Tests network layer and API calls
- **Key Tests**:
  - `testSearchMoviesSuccess()` - Tests API search
  - `testGetMovieDetailsSuccess()` - Tests movie details API
  - `testGetPopularMoviesSuccess()` - Tests popular movies API
  - `testHTTPError()` - Tests error handling

### Troubleshooting Test Issues

#### Simulator Issues:

```bash
# Reset all simulators
xcrun simctl shutdown all
xcrun simctl erase all

# Boot specific simulator
xcrun simctl boot "iPhone 16"
```

#### Build Issues:

```bash
# Clean build folder
xcodebuild clean -project SetFlix.xcodeproj -scheme SetFlix

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/SetFlix-*
```

## 📁 Project Structure

```
SetFlix/
├── SetFlix/                          # Main app target
│   ├── AppDelegate.swift             # App lifecycle management
│   ├── SceneDelegate.swift           # Scene lifecycle and navigation setup
│   ├── Info.plist                    # App configuration
│   ├── Config.plist                  # API keys and configuration
│   │
│   ├── Models/                       # Data models
│   │   ├── Movie.swift               # Movie data model
│   │   ├── MovieDetail.swift         # Detailed movie information
│   │   └── NetworkError.swift        # Network error types
│   │
│   ├── ViewModels/                   # MVVM ViewModels
│   │   ├── MovieSearchViewModel.swift # Main search and list logic
│   │   ├── MovieDetailViewModel.swift # Movie detail logic
│   │   └── FavoritesViewModel.swift  # Favorites management
│   │
│   ├── ViewControllers/              # UI Controllers
│   │   ├── MovieSearchViewController.swift # Main search screen
│   │   ├── MovieDetailViewController.swift # Movie detail screen
│   │   └── FavoritesViewController.swift   # Favorites screen
│   │
│   ├── Views/                        # Custom UI components
│   │   ├── MovieTableViewCell.swift  # Movie list cell
│   │   └── EmptyStateView.swift      # Empty state display
│   │
│   ├── Services/                     # Business logic and data layer
│   │   ├── MovieAPIService.swift     # TMDB API integration
│   │   ├── MovieRepository.swift     # Data access abstraction
│   │   ├── MovieRepositoryFactory.swift # Repository factory
│   │   ├── CacheManager.swift        # Data caching logic
│   │   ├── ImageLoader.swift         # Image loading and caching
│   │   ├── NetworkReachabilityService.swift # Network monitoring
│   │   └── README.md                 # Service layer documentation
│   │
│   ├── CoreData/                     # Data persistence
│   │   ├── CoreDataManager.swift     # Core Data operations
│   │   └── SetFlix.xcdatamodeld/     # Data model schema
│   │
│   ├── Utilities/                    # Helper classes
│   │   ├── ConfigurationManager.swift # App configuration
│   │   └── Extensions/               # Swift extensions
│   │
│   ├── Assets.xcassets/              # App icons and images
│   └── Base.lproj/                   # Localization files
│       ├── Main.storyboard           # Main storyboard
│       └── LaunchScreen.storyboard   # Launch screen
│
├── SetFlixTests/                     # Unit tests target
│   ├── CoreDataManagerTests.swift    # Core Data testing
│   ├── MovieRepositoryTests.swift    # Repository layer testing
│   ├── MovieSearchViewModelTests.swift # ViewModel testing
│   ├── NetworkLayerTests.swift       # Network layer testing
│   └── SetFlixTests.swift            # Test configuration
│
├── SetFlixUITests/                   # UI tests target
│   ├── MovieSearchUITests.swift      # UI interaction testing
│   ├── SetFlixUITests.swift          # UI test configuration
│   └── SetFlixUITestsLaunchTests.swift # Launch testing
│
├── SetFlix.xcodeproj/                # Xcode project file
├── README.md                         # Project documentation
└── DEVELOPMENT_WRITEUP.md            # Development decisions and challenges
```

### Architecture Overview

#### **MVVM Pattern**

- **Models**: `Movie`, `MovieDetail`, `NetworkError`
- **ViewModels**: Business logic and data binding
- **Views**: UI Controllers and custom components

#### **Repository Pattern**

- **Repository Interface**: `MovieRepository` protocol
- **Implementation**: `MovieRepositoryImpl` with API and cache
- **Factory**: `MovieRepositoryFactory` for dependency injection

#### **Service Layer**

- **API Service**: TMDB API integration
- **Cache Manager**: Data persistence and retrieval
- **Image Loader**: Image caching and loading
- **Network Monitor**: Connectivity status

#### **Data Layer**

- **Core Data**: Local persistence for favorites and cache
- **UserDefaults**: Lightweight data storage
- **File System**: Image cache storage

### Key Design Patterns

1. **Dependency Injection**: Services injected via protocols
2. **Factory Pattern**: Repository creation and configuration
3. **Observer Pattern**: Combine framework for reactive updates
4. **Singleton Pattern**: Shared services (CoreDataManager, ImageLoader)
5. **Protocol-Oriented**: Testable and maintainable interfaces
