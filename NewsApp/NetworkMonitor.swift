//
//  NetworkMonitor.swift
//  NewsApp
//
//  Created by SAGAR THUKRAL on 26/05/21.
//

import Foundation
import Network

final class NetworkMonitor : ObservableObject {
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "Monitor")
    
    @Published var isConnected = true
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied ? true : false
            }
        }
        monitor.start(queue: queue)
    }
}
