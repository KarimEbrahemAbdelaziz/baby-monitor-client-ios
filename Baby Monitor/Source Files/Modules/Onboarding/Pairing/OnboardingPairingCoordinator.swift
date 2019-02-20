//
//  OnboardingPairingCoordinator.swift
//  Baby Monitor
//

import Foundation
import UIKit

final class OnboardingPairingCoordinator: Coordinator {
    
    init(_ navigationController: UINavigationController, appDependencies: AppDependencies) {
        self.navigationController = navigationController
        self.appDependencies = appDependencies
    }
    
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    var appDependencies: AppDependencies
    var onEnding: (() -> Void)?
    
    func start() {
        switch UserDefaults.appMode {
        case .none:
            showContinuableView(role: .parent(.hello))
        case .parent:
            showPairingView()
        case .baby:
            break
        }
    }
    
    private func showContinuableView(role: OnboardingContinuableViewModel.Role) {
        let viewController = prepareContinuableViewController(role: role)
        switch role {
        case .parent(.error):
            navigationController.present(viewController, animated: true, completion: nil)
        default:
            navigationController.pushViewController(viewController, animated: true)
        }
    }
    
    private func prepareContinuableViewController(role: OnboardingContinuableViewModel.Role) -> UIViewController {
        let viewModel = OnboardingContinuableViewModel(role: role)
        let viewController = OnboardingContinuableViewController(viewModel: viewModel)
        viewController.rx.viewDidLoad.subscribe(onNext: { [weak self] in
            self?.connectTo(viewModel: viewModel)
        })
        .disposed(by: viewModel.bag)
        return viewController
    }
    
    private func connectTo(viewModel: OnboardingContinuableViewModel) {
        viewModel.cancelTap?.subscribe(onNext: { [weak self] in
            self?.navigationController.popViewController(animated: true)
        })
        .disposed(by: viewModel.bag)
        viewModel.nextButtonTap?.subscribe(onNext: { [weak self, weak viewModel] in
            guard let role = viewModel?.role else {
                return
            }
            switch role {
            case .parent(let parentRole):
                switch parentRole {
                case .hello:
                    self?.showPairingView()
                case .error:
                    self?.navigationController.dismiss(animated: true, completion: nil)
                case .allDone:
                    self?.onEnding?()
                }
            case .baby:
                break
            }
        })
        .disposed(by: viewModel.bag)
    }
    
    private func showPairingView() {
        let viewModel = ClientSetupOnboardingViewModel(
            netServiceClient: appDependencies.netServiceClient(),
            urlConfiguration: appDependencies.urlConfiguration,
            activityLogEventsRepository: appDependencies.databaseRepository,
            cacheService: appDependencies.cacheService,
            webSocketEventMessageService: appDependencies.webSocketEventMessageService.get())
        viewModel.didFinishDeviceSearch = { [weak self] result in
            switch result {
            case .success:
                switch UserDefaults.appMode {
                case .parent:
                    self?.onEnding?()
                case .none:
                    self?.showContinuableView(role: .parent(.allDone))
                case .baby:
                    break
                }
            case .failure:
                self?.showContinuableView(role: .parent(.error))
            }
        }
        let viewController = OnboardingClientSetupViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
