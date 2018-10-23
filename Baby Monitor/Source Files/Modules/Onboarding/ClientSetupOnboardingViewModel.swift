//
//  ClientSetupOnboardingViewModel.swift
//  Baby Monitor
//

import Foundation

enum DeviceSearchError: Error {
    case timeout
}

enum DeviceSearchResult: Equatable {
    case success
    case failure(DeviceSearchError)
}

final class ClientSetupOnboardingViewModel: OnboardingViewModelProtocol, ServiceDiscoverable {
    var selectFirstAction: (() -> Void)?
    var selectSecondAction: (() -> Void)?
    
    // MARK: - Coordinator callback
    var didFinishDeviceSearch: ((DeviceSearchResult) -> Void)?
    
    private var searchCancelTimer: Timer?
    private let netServiceClient: NetServiceClientProtocol
    private let rtspConfiguration: RTSPConfiguration
    private let babyRepo: BabiesRepository
    
    init(netServiceClient: NetServiceClientProtocol, rtspConfiguration: RTSPConfiguration, babyRepo: BabiesRepository) {
        self.netServiceClient = netServiceClient
        self.rtspConfiguration = rtspConfiguration
        self.babyRepo = babyRepo
    }
    
    func startDiscovering(withTimeout timeout: TimeInterval = 5.0) {
        searchCancelTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false, block: { [weak self] _ in
            self?.didFinishDeviceSearch?(.failure(.timeout))
            self?.netServiceClient.stopFinding()
            self?.searchCancelTimer = nil
        })
        netServiceClient.didFindServiceWith = { [weak self] ip, port in
            guard let self = self,
                let serverUrl = URL.rtsp(ip: ip, port: port) else {
                    return
            }
            self.searchCancelTimer?.invalidate()
            self.rtspConfiguration.url = serverUrl
            self.netServiceClient.stopFinding()
            self.didFinishDeviceSearch?(.success)
            self.setupBaby()
        }
        netServiceClient.findService()
    }
    
    private func setupBaby() {
        if babyRepo.fetchAllBabies().first == nil {
            try! babyRepo.save(baby: Baby(name: "Anonymous"))
        }
    }
}
