///
/// Copyright (c) 2020-Present Memfault, Inc.
/// See LICENSE for details
///

import UIKit
import MemfaultCloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    lazy var api: MemfaultApi = MemfaultApi(configuration: [
        kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",
    ])

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        gMFLTLogLevel = .debug
        return true
    }
}
