//
//  AppDelegate.swift
//  cat-urging-a-break-for-mac
//
//  Created by hanamizuki on 2020/09/25.
//  Copyright © 2020 hanamizuki. All rights reserved.
//

import Cocoa
import SwiftUI
import UserNotifications

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    // イベント発生時時間
    var eventDate:Date = Date()
    
    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        
        NSEvent.addGlobalMonitorForEvents(matching: .any, handler: { (event) in
            self.eventDate = Date()
            //Swift.print("addGlobalMonitorForEvents")
        })
        NSEvent.addLocalMonitorForEvents(matching: .any, handler: { (event) in
            self.eventDate = Date()
            //Swift.print("addLocalMonitorForEvents")
            return event
        })
        //=================================================================
        // https://qiita.com/aokiplayer/items/3f02453af743a54de718
        // iOS 10
        // notification center (singleton)
        let center = UNUserNotificationCenter.current()

        // ------------------------------------
        // 前準備: ユーザに通知の許可を求める
        // ------------------------------------
        // request to notify for user
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("通知許可")
            } else {
                print("通知拒否")
            }
        }
        // https://qiita.com/yamataku29/items/f45e77de3026d4c50016
        //=================================================================

        
        
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view. 
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // ウインドウのクローズとともにアプリケーションを終了させる
        return true
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}

