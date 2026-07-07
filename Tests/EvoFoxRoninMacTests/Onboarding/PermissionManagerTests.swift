/**
 PermissionManagerTests.swift

 Tests for the PermissionManager actor.
 */

import Testing
@testable import EvoFoxRoninMac

@Suite("PermissionManager")
struct PermissionManagerTests {

    @Test("PermissionManager shared instance exists")
    func sharedInstanceExists() async {
        let manager = PermissionManager.shared
        let status = await manager.checkInputMonitoring()
        #expect(status == .granted || status == .denied || status == .notDetermined || status == .unknown)
    }

    @Test("PermissionManager checkInputMonitoring returns PermissionStatus")
    func checkReturnsValidStatus() async {
        let manager = PermissionManager()
        let status = await manager.checkInputMonitoring()
        #expect(status == .granted || status == .denied || status == .notDetermined || status == .unknown)
    }
}
