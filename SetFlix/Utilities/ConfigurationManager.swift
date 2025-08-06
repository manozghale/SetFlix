//
//  ConfigurationManager.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    
    private var configDict: [String: Any] = [:]
    
    private init() {
        loadConfiguration()
    }
    
    // MARK: - Configuration Loading
    
    private func loadConfiguration() {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            fatalError("Config.plist not found or invalid")
        }
        configDict = dict
    }
    
    // MARK: - API Configuration
    
    var tmdbAPIKey: String {
        guard let apiKey = configDict["TMDB_API_KEY"] as? String,
              apiKey != "YOUR_API_KEY_HERE" else {
            fatalError("Please set your TMDB API key in Config.plist")
        }
        return apiKey
    }
    
    var tmdbBaseURL: String {
        return configDict["TMDB_BASE_URL"] as? String ?? "https://api.themoviedb.org/3"
    }
    
    var tmdbImageBaseURL: String {
        return configDict["TMDB_IMAGE_BASE_URL"] as? String ?? "https://image.tmdb.org/t/p/"
    }
    
    // MARK: - App Configuration
    
    var appName: String {
        return configDict["APP_NAME"] as? String ?? "SetFlix"
    }
    
    var appVersion: String {
        return configDict["APP_VERSION"] as? String ?? "1.0.0"
    }
    
    // MARK: - Network Configuration
    
    var requestTimeout: TimeInterval {
        return 30.0
    }
    
    var maxRetryAttempts: Int {
        return 3
    }
    
    // MARK: - Cache Configuration
    
    var imageCacheSizeLimit: Int {
        return 50 * 1024 * 1024 // 50MB
    }
    
    var imageCacheCountLimit: Int {
        return 100
    }
    
    var searchCacheExpirationTime: TimeInterval {
        return 3600 // 1 hour
    }
    
    var movieDetailCacheExpirationTime: TimeInterval {
        return 86400 // 24 hours
    }
} 