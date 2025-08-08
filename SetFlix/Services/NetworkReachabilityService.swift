//
//  NetworkReachabilityService.swift
//  SetFlix
//
//  Created by Manoj on 07/08/2025.
//

import Foundation
import Network

// MARK: - Network Reachability Protocol
protocol NetworkReachabilityProtocol {
  var isConnected: Bool { get }
  func isNetworkAvailable() -> Bool
  func getConnectionTypeString() -> String
  func addConnectionObserver(_ observer: @escaping (Bool) -> Void)
}

class NetworkReachabilityService: NetworkReachabilityProtocol {
  static let shared = NetworkReachabilityService()

  private let monitor = NWPathMonitor()
  private let queue = DispatchQueue(label: "com.setflix.networkmonitor")

  @Published private(set) var isConnected = false
  @Published private(set) var connectionType: ConnectionType = .unknown

  enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
  }

  private init() {
    setupNetworkMonitoring()
  }

  deinit {
    monitor.cancel()
  }

  // MARK: - Setup

  private func setupNetworkMonitoring() {
    monitor.pathUpdateHandler = { [weak self] path in
      DispatchQueue.main.async {
        self?.isConnected = path.status == .satisfied
        self?.connectionType = self?.getConnectionType(from: path) ?? .unknown
      }
    }

    monitor.start(queue: queue)
  }

  private func getConnectionType(from path: NWPath) -> ConnectionType {
    if path.usesInterfaceType(.wifi) {
      return .wifi
    } else if path.usesInterfaceType(.cellular) {
      return .cellular
    } else if path.usesInterfaceType(.wiredEthernet) {
      return .ethernet
    } else {
      return .unknown
    }
  }

  // MARK: - Public Methods

  func isNetworkAvailable() -> Bool {
    return isConnected
  }

  func getConnectionTypeString() -> String {
    switch connectionType {
    case .wifi:
      return "WiFi"
    case .cellular:
      return "Cellular"
    case .ethernet:
      return "Ethernet"
    case .unknown:
      return "Unknown"
    }
  }

  func addConnectionObserver(_ observer: @escaping (Bool) -> Void) {
    // This could be expanded to use a proper observer pattern
    // For now, we'll use the @Published property
  }
}
