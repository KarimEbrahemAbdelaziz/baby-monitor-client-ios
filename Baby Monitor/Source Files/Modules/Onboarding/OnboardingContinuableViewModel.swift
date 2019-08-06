//
//  OnboardingContinuableViewModel.swift
//  Baby Monitor
//

import Foundation
import RxSwift

final class OnboardingContinuableViewModel {
    
    enum Role: Equatable {
        case baby(BabyRole)
        case parent(ParentRole)
    }
    
    enum BabyRole: Equatable {
        case connectToWiFi
        case putNextToBed
    }
    
    enum ParentRole: Equatable {
        case hello
        case error
        case allDone
    }
    
    let role: Role
    let bag = DisposeBag()
    var title: String {
        switch role {
        case .baby(let babyRole):
            switch babyRole {
            case .connectToWiFi:
                return Localizable.Onboarding.connecting
            case .putNextToBed:
                return Localizable.Onboarding.Connecting.setupInformation
            }
        case .parent(let parentRole):
            switch parentRole {
            case .hello, .error:
                return Localizable.Onboarding.connecting
            case .allDone:
                return Localizable.Onboarding.Pairing.allDone
            }
        }
    }
    var description: String {
        switch role {
        case .baby(let babyRole):
            switch babyRole {
            case .connectToWiFi:
                return Localizable.Onboarding.Connecting.connectToWiFi
            case .putNextToBed:
                return Localizable.Onboarding.Connecting.placeDevice
            }
        case .parent(let parentRole):
            switch parentRole {
            case .hello:
                return Localizable.Onboarding.Pairing.hello
            case .error:
                return Localizable.Onboarding.Pairing.error
            case .allDone:
                return Localizable.Onboarding.Pairing.startUsingBabyMonitor
            }
        }
    }
    var secondDescription: NSMutableAttributedString? {
        switch role {
        case .baby, .parent(.allDone):
            return nil
        case .parent(.hello):
            let firstAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.babyMonitorPurple,
                .font: UIFont.customFont(withSize: .small, weight: .regular)
            ]
            let importantTextAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.customFont(withSize: .caption, weight: .bold)
            ]
            let lastTextAttributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.white,
                .font: UIFont.customFont(withSize: .caption, weight: .regular)
            ]
            let firstPartText = NSMutableAttributedString(
                string: Localizable.Onboarding.Pairing.timeToInstallBabyMonitor,
                attributes: firstAttributes)
            let secondPartText = NSMutableAttributedString(
                string: Localizable.General.important,
                attributes: importantTextAttributes)
            let lastPartText = NSMutableAttributedString(
                string: Localizable.Onboarding.Pairing.errorSecondDescriptionBottomPart,
                attributes: lastTextAttributes)
            let combinationText = NSMutableAttributedString(string: "")
            [firstPartText, secondPartText, lastPartText].forEach {
                combinationText.append($0)
            }
            return combinationText
        case .parent(.error):
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.babyMonitorPurple,
                .font: UIFont.customFont(withSize: .small, weight: .regular)
            ]
            let text = NSMutableAttributedString(
                string: Localizable.Onboarding.Pairing.errorSecondDescription,
                attributes: attributes)
            return text
        }
    }
    var buttonTitle: String {
        switch role {
        case .baby(let babyRole):
            switch babyRole {
            case .connectToWiFi:
                return Localizable.Onboarding.Connecting.connectToWiFiButtonTitle
            case .putNextToBed:
                return Localizable.Onboarding.Connecting.startMonitoring
            }
        case .parent(let parentRole):
            switch parentRole {
            case .hello:
                return Localizable.Onboarding.Connecting.connectToWiFiButtonTitle
            case .error:
                return Localizable.Onboarding.Pairing.tryAgain
            case .allDone:
                return Localizable.Onboarding.Pairing.getStarted
            }
        }
    }
    var image: UIImage {
        switch role {
        case .baby(let babyRole):
            switch babyRole {
            case .connectToWiFi:
                return #imageLiteral(resourceName: "onboarding-connecting")
            case .putNextToBed:
                return #imageLiteral(resourceName: "onboarding-camera")
            }
        case .parent(let parentRole):
            switch parentRole {
            case .hello:
                return #imageLiteral(resourceName: "onboarding-shareLink")
            case .error:
                return #imageLiteral(resourceName: "onboarding-error")
            case .allDone:
                return #imageLiteral(resourceName: "recordings")
            }
        }
    }
    var cancelTap: Observable<Void>?
    var nextButtonTap: Observable<Void>?
    
    init(role: Role) {
        self.role = role
    }
    
    func attachInput(buttonTap: Observable<Void>, cancelButtonTap: Observable<Void>) {
        cancelTap = cancelButtonTap
        nextButtonTap = buttonTap
    }
}
