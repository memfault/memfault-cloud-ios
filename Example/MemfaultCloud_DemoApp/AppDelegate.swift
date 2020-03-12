///
/// Copyright (c) Memfault, Inc.
/// See LICENSE for details
///

import UIKit
import MemfaultCloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        gMFLTLogLevel = .debug

        MemfaultApi.configureSharedApi([
            kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",
        ])
        return true
    }
}
