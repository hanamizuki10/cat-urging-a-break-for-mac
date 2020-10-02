//
//  ContentView.swift
//  cat-urging-a-break-for-mac
//
//  Created by hanamizuki on 2020/09/25.
//  Copyright © 2020 hanamizuki. All rights reserved.
//
import SwiftUI
import UserNotifications

struct ContentView: View {
    // 仕事経過時間（秒数）
    @State var workTimeInterval:Int = 0
    @State var statusText:String = "仕事中"
    @State var catTweet:String = "(お仕事がんばってにゃ〜)"

    // 通知した時間
    @State var notificationDate:Date = Date()

    var workMonitoringTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            if (isWorking()) {
                self.workTimeInterval += 1
                if(self.statusText == "休憩中") {
                    Swift.print(ToStringNowTime() + ", 休憩終了")
                    self.statusText = "仕事中"
                }
            } else if(self.statusText == "仕事中") {
                Swift.print(ToStringNowTime() + ", 休憩開始, 仕事経過時間=" + ToStringTime(timeInterval: self.workTimeInterval))
                self.statusText = "休憩中"
                resetWorkTimeIntervalFunc()
            }
        }
    }

    // 30秒置きに通知を出す条件を満たしているかどうかをチェック
    var workCheckTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) {_ in
            if ( isWorking() ) {
                // 前回のイベント発生時と比べて10分未満である。
                Swift.print("10分未満である、仕事中")
                Swift.print(String(self.workTimeInterval))
                if ( isContinuousWorkFor(TimeInterval:((1 * 60 * 60)+(30 * 60))) ) {
                    // 1時間30分以上の連続作業である
                    Swift.print("1時間30分以上の連続作業である")
                    self.catTweet = "（なんか長時間仕事しすぎにゃ！\nそれじゃあ肩凝るにゃ！\nそろそろ構にゃ〜！！）"
                    if (isItTimeToNotify() ) {
                        // 前回の通知時間との差分が30分以上ある場合
                        // 通知する
                        Notify()
                    }
                } else if (isContinuousWorkFor(TimeInterval:(1 * 60 * 60)) ) {
                    // 1時間以上の連続作業である
                    Swift.print("1時間以上の連続作業である")
                    self.catTweet = "（結構、長い間仕事してるにゃね？\n集中力すごいのにゃ〜）"
                } else if (isContinuousWorkFor(TimeInterval:(30 * 60)) ) {
                    // 30分以上の連続作業である
                    Swift.print("30分以上の連続作業である")
                    self.catTweet = "（お仕事に集中することは良いことにゃ〜！）"
                }
            }
        }
    }

    var body: some View {
        VStack() {
            Text("仕事監視Cat")
                .font(.title)
                .multilineTextAlignment(.leading)
            HStack {
                VStack {
                    VStack {
                        Text("ステータス")
                            .font(.caption)
                        Text(self.statusText)
                            .font(.body)
                    }
                    .padding(.vertical)
                    VStack {
                        Text("仕事経過時間")
                            .font(.caption)
                        Text(ToStringTime(timeInterval: self.workTimeInterval))
                            .font(.body)
                    }
                    Button(action: resetWorkTimeIntervalFunc) {
                        Text("リセット")
                    }
                    .padding(.bottom)

                }
                .frame(width: 100.0)
                VStack {
                    Image("nobinobicat")
                        .resizable()    // 画像サイズをフレームサイズに合わせる
                        .scaledToFit()      // 縦横比を維持しながらフレームに収める
                        .frame(width: 100.0, height: 100.0)

                    Text(self.catTweet)
                        .font(.caption)
                }
                .frame(width: 250.0)
            }
        }
        .frame(width: 400.0)
        .onAppear(perform: {
            _ = self.workMonitoringTimer
        })
        .onAppear(perform: {
            _ = self.workCheckTimer
        })
    }
    // 通知する
    func Notify() {
        self.notificationDate = Date()
        let outputDateString = ToStringTime(timeInterval:self.workTimeInterval)
        // content
        let content = UNMutableNotificationContent()
        content.title = "そろそろ構えにゃ"
        content.subtitle = "長時間パソコン触りすぎにゃ！"
        content.body = "仕事し続けて[" + outputDateString + "]結果してるにゃ。そろそろ休憩しようにゃー。気分転換しようにゃー。"
        content.userInfo = ["title" : "そろそろ構えにゃ"]
        content.sound = UNNotificationSound.default
        //content.contentImage =  NSImage(named: "black_cat2")
        if let imageUrl = Bundle.main.url(forResource: "nobinobicat", withExtension: "png"),
            let imageAttachment = try? UNNotificationAttachment(identifier: "ImageAttachment", url: imageUrl, options: nil) {
            content.attachments.append(imageAttachment)
            print("ImageAttachmentした")
        }

        // trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                        repeats: false)

        // request includes content & trigger
        let request = UNNotificationRequest(identifier: "breakCat_\(outputDateString)",
                                            content: content,
                                            trigger: trigger)

        // schedule notification by adding request to notification center
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    func ToStringTime(timeInterval interval:Int)->String{
        let calendar = Calendar(identifier: .japanese)
        let time000 = calendar.startOfDay(for: Date())
        let dispTime = Calendar.current.date(byAdding: .second, value: interval, to: time000)!
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: dispTime)
    }
    func ToStringNowTime()->String{
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    // 作業時間をリセットする
    func resetWorkTimeIntervalFunc(){
        self.workTimeInterval = 0
    }
    // 最後にイベントが発生してから経過した時間を取得する
    func getElapsedTimeLastEvent()->TimeInterval{
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        return appDelegate.eventDate.timeIntervalSinceNow
    }

    // 現在動作中であるかどうか確認する
    //（最後にイベント経過してから10分以内ならマウスやキーボード動かし作業中）
    func isWorking()->Bool{
        let timeIntervalSince = getElapsedTimeLastEvent()
        Swift.print(String(-timeIntervalSince))
        if ( -timeIntervalSince < (10 * 60) ) {
            // 前回のイベント発生時と比べて10分未満である。
            return true
        }
        return false
    }
    // 指定時間以上の連続作業中であるかどうかを確認する
    func isContinuousWorkFor(TimeInterval interval:Int)->Bool{
        if ( self.workTimeInterval < interval ) {
            // 前回のイベント時と比べて1時間未満である。
            return false
        }
        // 1時間以上の連続作業である
        return true
    }

    // 通知する時間であるかどうか
    // 最後に通知してから30分以上経過しているかどうか
    func isItTimeToNotify()->Bool{
        let timeIntervalSince = self.notificationDate.timeIntervalSinceNow
        Swift.print(String(timeIntervalSince))
        if ( -timeIntervalSince < (30 * 60 ) ) {
            // 前回のイベント時と比べて30分時間未満である。
            return false
        }
        // 通知対象である
        return true
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
