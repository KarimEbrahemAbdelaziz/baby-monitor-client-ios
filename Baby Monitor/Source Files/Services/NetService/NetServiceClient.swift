//
//  NetServiceClient.swift
//  Baby Monitor
//

import Foundation
import RxCocoa
import RxSwift

/// This type is used to describe a Bonjour service by its IP and port.
typealias NetServiceDescriptor = (ip: String, port: String)

protocol NetServiceClientProtocol: AnyObject {

    /// The observable of Bonjour service, if any, that the client is currently
    /// connected to.
    var service: Observable<NetServiceDescriptor?> { get }

    /// The variable controlling the state of the client. Changing its
    /// underlying `value` to `true` enables the client and changing it to
    /// `false` disables it.
    var isEnabled: Variable<Bool> { get }
}

final class NetServiceClient: NSObject, NetServiceClientProtocol {

    private enum ServiceError: Error {
        case didNotResolve, didNotSearch, didRemoveDomain, IPNotParsed
    }

    let isEnabled = Variable<Bool>(false)

    lazy var service = serviceVariable.asObservable()
    private let serviceVariable = Variable<NetServiceDescriptor?>(nil)

    private var netService: NetService?
    private let netServiceBrowser = NetServiceBrowser()
    private let netServiceAllowedPorts = [Constants.androidWebsocketPort, Constants.iosWebsocketPort]

    private let errorLogger: ServerErrorLogger

    private let disposeBag = DisposeBag()

    init(serverErrorLogger: ServerErrorLogger) {
        self.errorLogger = serverErrorLogger
        super.init()
        setupRx()
    }

    private func setupRx() {
        isEnabled.asObservable()
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self] in $0 ? self.start() : self.stop() })
            .disposed(by: disposeBag)
    }

    private func start() {
        netServiceBrowser.delegate = self
        netServiceBrowser.searchForServices(ofType: Constants.netServiceType, inDomain: Constants.domain)
    }

    private func stop() {
        netServiceBrowser.stop()
        serviceVariable.value = nil
        netService = nil
    }

    /// Convert IP address bytes into human readable IP address string.
    ///
    /// - Parameters:
    ///     - data: Bytes representing an IP address.
    ///
    /// - Returns: An IP address string or `nil` if conversion failed.
    private func ip(from data: Data) -> String? {
        return data.withUnsafeBytes { (pointer: UnsafePointer<sockaddr>) in
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(pointer, socklen_t(data.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                return String(cString: hostname)
            } else {
                return nil
            }
        }
    }

}

// MARK: - NetServiceBrowserDelegate
extension NetServiceClient: NetServiceBrowserDelegate {

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard service.name == Constants.netServiceName else { return }
        netServiceBrowser.stop()
        netService = service
        netService!.delegate = self
        /// Setting an infinite timeout for the resolve process as the timeout is being controllered by the instance, which starts discoverign (ex viewModel).
        netService!.resolve(withTimeout: 0)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        serviceVariable.value = nil
        netService = nil
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        errorLogger.log(error: ServiceError.didNotSearch, additionalInfo: errorDict)
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didRemoveDomain domainString: String, moreComing: Bool) {
        errorLogger.log(error: ServiceError.didRemoveDomain, additionalInfo: ["name": domainString])
    }

}

// MARK: - NetServiceDelegate
extension NetServiceClient: NetServiceDelegate {

    func netServiceDidResolveAddress(_ sender: NetService) {
        guard let address = sender.addresses?.first,
            netServiceAllowedPorts.contains(sender.port),
            let ip = ip(from: address) else {
                let errorDict: [String: Any] = [
                    "adress": sender.addresses?.first ?? "null",
                    "containsPort": netServiceAllowedPorts.contains(sender.port)
                ]
                errorLogger.log(error: ServiceError.IPNotParsed, additionalInfo: errorDict)
                return
        }
        serviceVariable.value = (ip: ip, port: String(sender.port))
    }

    func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
        errorLogger.log(error: ServiceError.didNotResolve, additionalInfo: errorDict)
    }

}
