//
//  BCPeripheralManagerTests.swift
//  BlueCapKit
//
//  Created by Troy Stribling on 3/25/15.
//  Copyright (c) 2015 Troy Stribling. The MIT License (MIT).
//

import UIKit
import XCTest
import CoreBluetooth
import CoreLocation
@testable import BlueCapKit

// MARK: - BCPeripheralManagerTests -
class BCPeripheralManagerTests: XCTestCase {

    let peripheralName  = "Test Peripheral"
    let advertisedUUIDs = CBUUID(string: Gnosus.HelloWorldService.Greeting.UUID)
  
    override func setUp() {
        GnosusProfiles.create()
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    // MARK: Power on
    func testPowerOnWhenPoweredOn() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOnWhenPoweredOff() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOn()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        mock.state = .PoweredOn
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Power off
    func testPowerOffWhenPoweredOn() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        mock.state = .PoweredOff
        peripheralManager.didUpdateState()
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testPowerOffWhenPoweredOff() {
        let (_, peripheralManager) = createPeripheralManager(false, state: .PoweredOff)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.whenPowerOff()
        future.onSuccess {
            expectation.fulfill()
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Start advertising
    func testStartAdvertisingSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            XCTAssert(peripheralManager.isAdvertising, "isAdvertising invalid value")
            if let advertisedData = mock.advertisementData,
                   name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                   uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTFail("advertisementData not found")
            }
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        peripheralManager.didStartAdvertising(nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingFailure() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            if let advertisedData = mock.advertisementData,
                name = advertisedData[CBAdvertisementDataLocalNameKey] as? String,
                uuids = advertisedData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
                    XCTAssertEqual(name, self.peripheralName, "peripheralName invalid")
                    XCTAssertEqual(uuids[0], self.advertisedUUIDs, "advertised UUIDs invalid")
            } else {
                XCTFail("advertisementData not found")
            }
        }
        peripheralManager.didStartAdvertising(TestFailure.error)
        waitForExpectationsWithTimeout(2) { error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingWhenAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(self.peripheralName, uuids:[self.advertisedUUIDs])
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "Error code is invalid")
            XCTAssert(mock.advertisementData == nil, "advertisementData found")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: iBeacon
    func testStartAdvertisingBeaconSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
            XCTAssert(peripheralManager.isAdvertising, "isAdvertising invalid value")
        }
        future.onFailure { error in
            XCTFail("onFailure called")
        }
        peripheralManager.didStartAdvertising(nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingBeaconFailure() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure { error in
            expectation.fulfill()
            XCTAssertEqual(error.code, TestFailure.error.code, "error code invalid")
            XCTAssert(mock.startAdvertisingCalled, "startAdvertising not called")
        }
        peripheralManager.didStartAdvertising(TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStartAdvertisingBeaconWhenAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.startAdvertising(FLBeaconRegion(proximityUUID: NSUUID(), identifier: "Beacon Regin"))
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsAdvertising.rawValue, "Error code is invalid \(error.code)")
            XCTAssertFalse(mock.startAdvertisingCalled, "startAdvertising not called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Stop advertising
    func testStopAdvertising() {
        let (mock, peripheralManager) = createPeripheralManager(true, state: .PoweredOn)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.stopAdvertising()
        future.onSuccess {
            expectation.fulfill()
            XCTAssert(mock.stopAdvertisingCalled, "stopAdvertisingCalled not called")
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        mock.isAdvertising = false
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testStopAdvertisingWhenNotAdvertsing() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let expectation = expectationWithDescription("onFailure fulfilled for future")
        let future = peripheralManager.stopAdvertising()
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            XCTAssertEqual(error.code, BCPeripheralManagerErrorCode.IsNotAdvertising.rawValue, "Error code is invalid")
            XCTAssertFalse(mock.stopAdvertisingCalled, "stopAdvertisingCalled called")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Add Service
    func testAddService_WhenNoErrorInAck_CompletesSuccess() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[0].UUID, "addedService has invalid UUID")
            if let addedService = mock.addedService {
                XCTAssertEqual(services[0].UUID, addedService.UUID, "addedService UUID invalid")
            } else {
                XCTFail("addService not found")
            }
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: nil)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddService_WhenErrorOnAck_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addService(services[0])
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        peripheralManager.didAddService(services[0].cbMutableService, error: TestFailure.error)
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddServices_WhenNoErrorInAck_CompletesSuccessfully() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        future.onSuccess {
            expectation.fulfill()
            let peripheralServices = peripheralManager.services.map { $0.UUID }
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 2, "peripheralManager service count invalid")
            XCTAssert(peripheralServices.contains(services[0].UUID), "addedService has invalid UUID")
            XCTAssert(peripheralServices.contains(services[1].UUID), "addedService has invalid UUID")
        }
        future.onFailure {error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testAddServices_WhenErrorInAck_CompletesWithAckError() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let future = peripheralManager.addServices(services)
        peripheralManager.error = TestFailure.error
        future.onSuccess {
            XCTFail("onSuccess called")
        }
        future.onFailure {error in
            expectation.fulfill()
            let peripheralServices = peripheralManager.services
            XCTAssertEqual(TestFailure.error.code, error.code, "error code is invalid")
            XCTAssert(mock.addServiceCalled, "addService not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: Remove Service
    func testRemovedService_WhenServiceIsPresent_RemovesService() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        addServicesFuture.onSuccess {
            expectation.fulfill()
            peripheralManager.removeService(services[0])
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeServiceCalled, "removeService not called")
            XCTAssertEqual(peripheralServices.count, 1, "peripheralManager service count invalid")
            XCTAssertEqual(peripheralServices[0].UUID, services[1].UUID, "addedService has invalid UUID")
            if let removedService = mock.removedService {
                XCTAssertEqual(removedService.UUID, services[0].UUID, "removeService has invalid UUID")
            } else {
                XCTFail("removedService not found")
            }
        }
        addServicesFuture.onFailure {error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    func testRemovedService_WhenSNoerviceIsPresent_DoesNothing() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        peripheralManager.removeService(services[0])
        XCTAssert(mock.removeServiceCalled, "removeService not called")
    }

    func testRemovedAllServices_WhenServicesArePresent_RemovesAllServices() {
        let (mock, peripheralManager) = createPeripheralManager(false, state: .PoweredOn)
        let services = createPeripheralManagerServices(peripheralManager)
        let expectation = expectationWithDescription("onSuccess fulfilled for future")
        let addServicesFuture = peripheralManager.addServices(services)
        addServicesFuture.onSuccess {
            expectation.fulfill()
            peripheralManager.removeAllServices()
            let peripheralServices = peripheralManager.services
            XCTAssert(mock.removeAllServicesCalled, "removeAllServices not called")
            XCTAssertEqual(peripheralServices.count, 0, "peripheralManager service count invalid")
        }
        addServicesFuture.onFailure {error in
            XCTFail("onFailure called")
        }
        waitForExpectationsWithTimeout(2) {error in
            XCTAssertNil(error, "\(error)")
        }
    }

    // MARK: State Restoration
    func testStateRestoration() {

    }

}
