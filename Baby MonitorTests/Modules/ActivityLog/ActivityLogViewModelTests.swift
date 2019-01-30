//
//  ActivityLogViewModelTests.swift
//  Baby MonitorTests
//

import XCTest
import RxSwift
import RxTest
import RxCocoa
@testable import BabyMonitor

class ActivityLogViewModelTests: XCTestCase {

    private var showBabiesTap = PublishSubject<Void>()
    private var bag = DisposeBag()
    
    override func setUp() {
        showBabiesTap = PublishSubject<Void>()
        bag = DisposeBag()
    }
    
    func testShouldGenerateProperSections() {
        // Given
        let disposeBag = DisposeBag()
        let babiesRepository = DatabaseRepositoryMock()
        let tommorowCryingLogEvent = ActivityLogEvent(mode: .cryingEvent, date: Date.tommorow)
        let yesterdayCryingLogEvent = ActivityLogEvent(mode: .cryingEvent, date: Date.yesterday)
        let secondYesterdayCryingLogEvent = ActivityLogEvent(mode: .cryingEvent, date: Date.yesterday.addingTimeInterval(1))
        let todayCryingLogEvent = ActivityLogEvent(mode: .cryingEvent, date: Date())
        let expectedSections = [
            GeneralSection<ActivityLogEvent>(title: "", items: [tommorowCryingLogEvent]),
            GeneralSection<ActivityLogEvent>(title: "", items: [todayCryingLogEvent]),
            GeneralSection<ActivityLogEvent>(title: "", items: [secondYesterdayCryingLogEvent, yesterdayCryingLogEvent])
        ]
        let sut = ActivityLogViewModel(databaseRepository: babiesRepository)
        var resultSections: [GeneralSection<ActivityLogEvent>] = []
        
        sut.sectionsChangeObservable.subscribe(onNext: {
            resultSections = sut.currentSections
        })
            .disposed(by: disposeBag)
        // When
        
        babiesRepository.save(activityLogEvent: yesterdayCryingLogEvent)
        babiesRepository.save(activityLogEvent: secondYesterdayCryingLogEvent)
        babiesRepository.save(activityLogEvent: todayCryingLogEvent)
        babiesRepository.save(activityLogEvent: tommorowCryingLogEvent)
        
        // Then
        XCTAssertEqual(expectedSections, resultSections)
    }
}
