# Network Layer Documentation

## Overview

The SetFlix network layer is built using Swift's native `URLSession` with modern `async/await` concurrency. It provides a clean, testable, and efficient way to communicate with The Movie Database (TMDB) API.

## Architecture

### Core Components

1. **MovieAPIService Protocol** - Defines the contract for API operations
2. **TMDBAPIService** - Concrete implementation for TMDB API
3. **NetworkError** - Comprehensive error handling
4. **ImageLoader** - Efficient image loading and caching
5. **NetworkReachabilityService** - Network connectivity monitoring

## Features

### ✅ Modern Swift Concurrency
- Uses `async/await` instead of completion handlers
- No callback hell or nested closures
- Better error handling and control flow

### ✅ Comprehensive Error Handling
- Network-specific error types
- HTTP status code mapping
- User-friendly error messages
- Recovery suggestions

### ✅ Efficient Image Loading
- Memory and disk caching
- Automatic cache cleanup
- Background processing
- Memory warning handling

### ✅ Network Monitoring
- Real-time connectivity status
- Connection type detection
- Offline mode support

## Usage Examples

### Search Movies
```swift
let apiService = TMDBAPIService(apiKey: "your_api_key")

do {
    let response = try await apiService.searchMovies(query: "Avengers", page: 1)
    print("Found \(response.totalResults) movies")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

### Get Movie Details
```swift
do {
    let movieDetail = try await apiService.getMovieDetails(id: 299536)
    print("Movie: \(movieDetail.title)")
    print("Runtime: \(movieDetail.formattedRuntime)")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

### Load Images
```swift
// Using completion handler
imageView.loadImage(from: movie.posterPath) { image in
    // Image loaded
}

// Using async/await
let image = await ImageLoader.shared.loadImageAsync(from: movie.posterPath)
```

## Configuration

### API Key Setup
1. Get your TMDB API key from [The Movie Database](https://www.themoviedb.org/settings/api)
2. Add it to `Config.plist`:
```xml
<key>TMDB_API_KEY</key>
<string>YOUR_ACTUAL_API_KEY</string>
```

### Network Configuration
- Request timeout: 30 seconds
- Max retry attempts: 3
- Image cache size: 50MB
- Image cache count: 100 items

## Error Handling

The network layer provides detailed error information:

```swift
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    case noInternetConnection
    case serverError(Int)
    case timeout
    case unauthorized
    case rateLimitExceeded
    case unknown
}
```

Each error includes:
- `errorDescription`: User-friendly error message
- `recoverySuggestion`: Actionable recovery advice

## Testing

The network layer includes comprehensive unit tests:

- ✅ API service tests with mock responses
- ✅ Error handling tests
- ✅ Image loading tests
- ✅ Network reachability tests

Run tests with: `Cmd + U` in Xcode

## Performance Optimizations

### Image Caching
- **Memory Cache**: NSCache with automatic cleanup
- **Disk Cache**: Persistent storage for offline access
- **Background Processing**: Non-blocking image loading
- **Memory Management**: Automatic cleanup on memory warnings

### Network Efficiency
- **Request Deduplication**: Prevents duplicate requests
- **Proper Caching Headers**: Respects server cache directives
- **Background Queues**: Non-blocking network operations
- **Connection Pooling**: Reuses HTTP connections

## Security

### API Key Management
- Stored securely in configuration
- Not hardcoded in source code
- Environment-specific configuration support

### Network Security
- HTTPS enforcement
- Certificate pinning support
- Secure URL construction
- Input validation

## Future Enhancements

### Planned Features
- [ ] Request/Response logging
- [ ] Retry with exponential backoff
- [ ] Request queuing for offline mode
- [ ] Background refresh
- [ ] Analytics integration

### Technical Improvements
- [ ] Combine integration for reactive programming
- [ ] Custom URLSession configuration
- [ ] Advanced caching strategies
- [ ] Network performance metrics

## Dependencies

This network layer uses **zero external dependencies** and relies entirely on Apple's native frameworks:

- **Foundation**: URLSession, JSONDecoder, FileManager
- **UIKit**: UIImage, UIImageView extensions
- **Network**: NWPathMonitor for reachability
- **Combine**: @Published for reactive updates

## Best Practices

1. **Always handle errors gracefully**
2. **Use async/await for better readability**
3. **Cache images appropriately**
4. **Monitor network connectivity**
5. **Provide user feedback for network operations**
6. **Test with mock data**
7. **Respect API rate limits** 