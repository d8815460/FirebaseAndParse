//
//  Copyright (c) 2016 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Firebase
import FirebaseUI
import GTMSessionFetcher
import TwitterKit
import Parse
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Successfully running this sample requires an app in Firebase and an
        // accompanying valid GoogleService-Info.plist file.
        FirebaseApp.configure()
        TWTRTwitter.sharedInstance().start(withConsumerKey: "consumer-key",
                                           consumerSecret: "consumer-secret");
        GTMSessionFetcher.setLoggingEnabled(true)
        // ****************************************************************************
        // Initialize Parse SDK
        // ****************************************************************************
        let configuration = ParseClientConfiguration {
            // Add your Parse applicationId:
            $0.applicationId = "XcQ0KKdcEpvKaqHMXT4Xyrk0cBLFQfM69Um5hgP6"
            // Uncomment and add your clientKey (it's not required if you are using Parse Server):
            $0.clientKey = "Ysx7fcKDt25W1oXePkstB4aZhUciUPFQ6frk9oBM"
            
            // Uncomment the following line and change to your Parse Server address;
            $0.server = "https://pg-app-ambcidt2nw8v4pyzpddxcwf9s6ev18.scalabl.cloud/1/"
            
            // Enable storing and querying data from Local Datastore.
            // Remove this line if you don't want to use Local Datastore features or want to use cachePolicy.
            $0.isLocalDatastoreEnabled = false
        }
        
        Parse.initialize(with: configuration)
        PFUser.enableRevocableSessionInBackground()
        
        let defaultACL = PFACL()
        // If you would like all objects to be private by default, remove this line.
        defaultACL.hasPublicReadAccess = true
        
        PFACL.setDefault(defaultACL, withAccessForCurrentUser: true)
        
        if application.applicationState != UIApplicationState.background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let oldPushHandlerOnly = !responds(to: #selector(UIApplicationDelegate.application(_:didReceiveRemoteNotification:fetchCompletionHandler:)))
            var noPushPayload = false
            if let options = launchOptions {
                noPushPayload = options[UIApplicationLaunchOptionsKey.remoteNotification] == nil
            }
            if oldPushHandlerOnly || noPushPayload {
                PFAnalytics.trackAppOpened(launchOptions: launchOptions)
            }
        }
        if #available(iOS 10.0, *) {
            // iOS 10+
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
                print("Notifications access granted: \(granted.description)")
            }
            application.registerForRemoteNotifications()
        } else {
            // iOS 8, 9
            let types: UIUserNotificationType = [.alert, .badge, .sound]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        return true
        
    }
    
    //--------------------------------------
    // MARK: Push Notifications
    //--------------------------------------
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let installation = PFInstallation.current()
        installation?.setDeviceTokenFrom(deviceToken)
        installation?.saveInBackground()
        
        PFPush.subscribeToChannel(inBackground: "") { succeeded, error in
            if succeeded {
                print("ParseStarterProject successfully subscribed to push notifications on the broadcast channel.\n")
            } else {
                print("ParseStarterProject failed to subscribe to push notifications on the broadcast channel with error = %@.\n", error!)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        if error._code == 3010 {
            print("Push notifications are not supported in the iOS Simulator.\n")
        } else {
            print("application:didFailToRegisterForRemoteNotificationsWithError: %@\n", error)
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        PFPush.handle(userInfo)
        if application.applicationState == UIApplicationState.inactive {
            PFAnalytics.trackAppOpened(withRemoteNotificationPayload: userInfo)
        }
    }
    
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let sourceApplication = options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?
        return self.handleOpenUrl(url, sourceApplication: sourceApplication)
    }
    
    @available(iOS 8.0, *)
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.handleOpenUrl(url, sourceApplication: sourceApplication)
    }
    
    
    func handleOpenUrl(_ url: URL, sourceApplication: String?) -> Bool {
        if FUIAuth.defaultAuthUI()?.handleOpen(url, sourceApplication: sourceApplication) ?? false {
            return true
        }
        // other URL handling goes here.
        return false
    }

}

