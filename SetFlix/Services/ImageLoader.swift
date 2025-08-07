//
//  ImageLoader.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import UIKit

class ImageLoader {
  static let shared = ImageLoader()

  private let cache = NSCache<NSString, UIImage>()
  private let session = URLSession.shared
  private let fileManager = FileManager.default
  private let cacheDirectory: URL
  private let queue = DispatchQueue(label: "com.setflix.imageloader", qos: .utility)

  private init() {
    // Configure cache limits
    cache.countLimit = 100
    cache.totalCostLimit = 50 * 1024 * 1024  // 50MB

    // Setup disk cache directory
    let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    cacheDirectory = documentsPath.appendingPathComponent("ImageCache")

    try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

    // Add memory warning observer
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(clearMemoryCache),
      name: UIApplication.didReceiveMemoryWarningNotification,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: - Public Methods

  func loadImage(from path: String, size: String = "w500", completion: @escaping (UIImage?) -> Void)
  {
    let imageURL = "https://image.tmdb.org/t/p/\(size)\(path)"
    let cacheKey = "\(path)_\(size)" as NSString

    // Check memory cache first
    if let cachedImage = cache.object(forKey: cacheKey) {
      completion(cachedImage)
      return
    }

    // Check disk cache
    if let diskImage = loadFromDisk(path: cacheKey as String) {
      cache.setObject(diskImage, forKey: cacheKey)
      completion(diskImage)
      return
    }

    // Download from network
    guard let url = URL(string: imageURL) else {
      completion(nil)
      return
    }

    queue.async { [weak self] in
      self?.downloadImage(from: url, cacheKey: cacheKey, completion: completion)
    }
  }

  func loadImageAsync(from path: String, size: String = "w500") async -> UIImage? {
    return await withCheckedContinuation { continuation in
      loadImage(from: path, size: size) { image in
        continuation.resume(returning: image)
      }
    }
  }

  func clearCache() {
    clearMemoryCache()
    clearDiskCache()
  }

  // MARK: - Private Methods

  private func downloadImage(
    from url: URL, cacheKey: NSString, completion: @escaping (UIImage?) -> Void
  ) {
    Task {
      do {
        let (data, _) = try await session.data(from: url)
        if let image = UIImage(data: data) {
          // Save to cache
          cache.setObject(image, forKey: cacheKey)
          saveToDisk(image: image, path: cacheKey as String)

          DispatchQueue.main.async {
            completion(image)
          }
        } else {
          DispatchQueue.main.async {
            completion(nil)
          }
        }
      } catch {
        print("Image download error: \(error)")
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }
  }

  private func loadFromDisk(path: String) -> UIImage? {
    let fileName = path.replacingOccurrences(of: "/", with: "_")
    let fileURL = cacheDirectory.appendingPathComponent(fileName)

    guard let data = try? Data(contentsOf: fileURL) else { return nil }
    return UIImage(data: data)
  }

  private func saveToDisk(image: UIImage, path: String) {
    let fileName = path.replacingOccurrences(of: "/", with: "_")
    let fileURL = cacheDirectory.appendingPathComponent(fileName)

    if let data = image.jpegData(compressionQuality: 0.8) {
      try? data.write(to: fileURL)
    }
  }

  @objc private func clearMemoryCache() {
    cache.removeAllObjects()
  }

  private func clearDiskCache() {
    try? fileManager.removeItem(at: cacheDirectory)
    try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
  }
}

// MARK: - UIImageView Extension
extension UIImageView {
  func loadImage(from path: String?, size: String = "w500", placeholder: UIImage? = nil) {
    // Set placeholder
    self.image = placeholder

    guard let path = path else { return }

    ImageLoader.shared.loadImage(from: path, size: size) { [weak self] image in
      DispatchQueue.main.async {
        self?.image = image
      }
    }
  }

  func loadImageAsync(from path: String?, size: String = "w500", placeholder: UIImage? = nil) async
  {
    // Set placeholder
    self.image = placeholder

    guard let path = path else { return }

    let image = await ImageLoader.shared.loadImageAsync(from: path, size: size)
    await MainActor.run {
      self.image = image
    }
  }
}
