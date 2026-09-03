import AppKit
import SwiftUI
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = GrammarMeServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = serviceProvider
        NSUpdateDynamicServices()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}

@main
struct GrammarMeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("GrammarMe", systemImage: "text.badge.checkmark") {
            GrammarMeMenuView()
        }
        .menuBarExtraStyle(.window)
    }
}
