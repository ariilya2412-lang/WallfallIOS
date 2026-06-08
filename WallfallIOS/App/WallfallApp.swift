import SwiftUI

@main
struct WallfallApp: App {
    var body: some Scene {
        WindowGroup {
            GameWebView()
                .ignoresSafeArea()
        }
    }
}
