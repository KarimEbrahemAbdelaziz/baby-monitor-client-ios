//
//  WebrtcManager.swift
//  ConnectedColors
//
//  Created by Mahabali on 4/8/16.
//  Copyright © 2016 Ralf Ebert. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift
import RxCocoa

final class WebRtcClientManager: NSObject, WebRtcClientManagerProtocol {

    var iceCandidate: Observable<IceCandidateProtocol> {
        return iceCandidatePublisher
    }
    var sdpOffer: Observable<SessionDescriptionProtocol> {
        return sdpOfferPublisher
    }
    var mediaStream: Observable<MediaStream?> {
        return mediaStreamPublisher
    }
    
    private var isStarted = false
    private let sdpOfferPublisher = PublishSubject<SessionDescriptionProtocol>()
    private let iceCandidatePublisher = PublishSubject<IceCandidateProtocol>()
    private let mediaStreamPublisher = BehaviorSubject<MediaStream?>(value: nil)
    private let disposeBag = DisposeBag()

    private var peerConnection: PeerConnectionProtocol?
    private let peerConnectionFactory: PeerConnectionFactoryProtocol
    private let connectionDelegateProxy: RTCPeerConnectionDelegateProxy
    private let remoteDescriptionDelegateProxy: RTCSessionDescriptionDelegateProxy
    private let localDescriptionDelegateProxy: RTCSessionDescriptionDelegateProxy

    private var streamMediaConstraints: RTCMediaConstraints {
        return RTCMediaConstraints(
            mandatoryConstraints: [
                RTCPair(key: WebRtcConstraintKey.offerToReceiveVideo, value: WebRtcConstraintValue.true)!,
                RTCPair(key: WebRtcConstraintKey.offerToReceiveAudio, value: WebRtcConstraintValue.true)!
            ],
            optionalConstraints: [
                RTCPair(key: WebRtcConstraintKey.dtlsSrtpKeyAgreement, value: WebRtcConstraintValue.true)!
            ]
        )
    }

    init(peerConnectionFactory: PeerConnectionFactoryProtocol) {
        self.peerConnectionFactory = peerConnectionFactory
        self.connectionDelegateProxy = RTCPeerConnectionDelegateProxy()
        self.remoteDescriptionDelegateProxy = RTCSessionDescriptionDelegateProxy()
        self.localDescriptionDelegateProxy = RTCSessionDescriptionDelegateProxy()
        super.init()
        setup()
    }

    func setup() {

        connectionDelegateProxy.onAddedStream = { [weak self] _, stream in
            guard let `self` = self else { return }
            self.mediaStreamPublisher.onNext(stream)
        }

        connectionDelegateProxy.onGotIceCandidate = { [weak self] _, iceCandidate in
            guard let `self` = self else { return }
            self.iceCandidatePublisher.onNext(iceCandidate)
        }

        localDescriptionDelegateProxy.onDidCreateSessionDescription = { [weak self] connection, sdp in
            guard let `self` = self else { return }
            connection.setLocalDescription(sdp: sdp, delegate: self.localDescriptionDelegateProxy)
            self.sdpOfferPublisher.onNext(sdp)
        }

        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification)
            .filter { [unowned self] _ in self.isStarted }
            .subscribe(onNext: { [unowned self] _ in self.pause() })
            .disposed(by: disposeBag)

        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .filter { [unowned self] _ in self.isStarted }
            .subscribe(onNext: { [unowned self] _ in self.resume() })
            .disposed(by: disposeBag)

    }

    func startIfNeeded() {
        guard !isStarted else { return }
        isStarted = true
        createOffer()
    }

    func stop() {
        peerConnection?.close()
        isStarted = false
    }

    private func pause() {
        peerConnection?.close()
    }

    private func resume() {
        createOffer()
    }

    private func createOffer() {
        peerConnection = peerConnectionFactory.peerConnection(with: connectionDelegateProxy)
        peerConnection?.createOffer(for: streamMediaConstraints, delegate: localDescriptionDelegateProxy)
    }

    func setAnswerSDP(sdp: SessionDescriptionProtocol) {
        peerConnection?.setRemoteDescription(sdp: sdp, delegate: remoteDescriptionDelegateProxy)
    }
    
    func setICECandidates(iceCandidate: IceCandidateProtocol) {
        peerConnection?.add(iceCandidate: iceCandidate)
    }

}
