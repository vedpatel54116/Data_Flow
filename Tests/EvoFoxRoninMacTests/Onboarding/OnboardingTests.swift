/**
 OnboardingTests.swift

 Tests for onboarding UserDefaults state management.
 */

import Testing
@testable import EvoFoxRoninMac

@Suite("Onboarding State")
struct OnboardingTests {

    @Test("Onboarding completion persists in UserDefaults")
    func onboardingCompletionPersists() async {
        let key = "hasCompletedOnboarding"
        UserDefaults.standard.set(true, forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == true)

        UserDefaults.standard.removeObject(forKey: key)
    }

    @Test("Onboarding not completed by default")
    func onboardingNotCompletedByDefault() async {
        let key = "hasCompletedOnboarding"
        UserDefaults.standard.removeObject(forKey: key)
        #expect(UserDefaults.standard.bool(forKey: key) == false)
    }

    @Test("WhatsNewManager detects version correctly")
    func whatsNewManagerVersionDetection() async {
        let version = WhatsNewManager.currentVersion
        #expect(!version.isEmpty)
    }

    @Test("WhatsNewManager markSeen updates UserDefaults")
    func whatsNewManagerMarkSeen() async {
        let key = "lastSeenVersion"
        let version = WhatsNewManager.currentVersion
        WhatsNewManager.markSeen()
        #expect(UserDefaults.standard.string(forKey: key) == version)

        UserDefaults.standard.removeObject(forKey: key)
    }
}
