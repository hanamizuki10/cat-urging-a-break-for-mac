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
    // キーボード監視も許可する否かフラグ(trueにしても、App Sandboxの有効化を解除しなければ動きません。意味がわからない場合はfalseにする事）
    let IS_KEY_EVENT_ALLOW:Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // キーボード状態監視も有効にする（有効になってなければ通知を促す）
        if (self.IS_KEY_EVENT_ALLOW) {
            // [システム環境設定]->[セキュリティーとプライバシー]->[アクセシビリティ]で有効にするのを促す
            requestKeyEventAuthorization()
        }
        // イベント監視処理を登録
        addMonitorForEvents()
        // ユーザへ通知許可を要求
        requestNotificationAuthorization()

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

    // キーボードイベントの許可要求
    func requestKeyEventAuthorization() {
        // ウィンドウ外でキーボードイベントも検知したい場合
        // [システム環境設定]->[セキュリティーとプライバシー]->[アクセシビリティ]で有効にするのを促す
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "cat-urging-a-break-for-mac.app"
            alert.informativeText = "システム環境設定でcat-urging-a-break-for-mac.app（このダイアログの後ろにあるダイアログを参照）のアクセシビリティを有効にして、このアプリを再度起動する必要があります"
            alert.addButton(withTitle: "OK")
            alert.runModal()
            // 設定できたらアプリを再起動しないと意味ないためアプリ強制終了
            NSApplication.shared.terminate(self)
        }
    }

    // イベント監視処理を登録
    func addMonitorForEvents() {
        // ウィンドウ外でイベントが発生するたびに検知してイベント日付を更新する
        NSEvent.addGlobalMonitorForEvents(matching: .any, handler: { (event) in
            self.eventDate = Date()
        })
        // ウィンドウ内でイベントが発生するたびに検知してイベント日付を更新する
        NSEvent.addLocalMonitorForEvents(matching: .any, handler: { (event) in
            self.eventDate = Date()
            return event
        })
    }

    // ユーザーに通知許可を要求する
    func requestNotificationAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("通知許可")
            } else {
                print("通知拒否")
            }
        }
    }
    
}
