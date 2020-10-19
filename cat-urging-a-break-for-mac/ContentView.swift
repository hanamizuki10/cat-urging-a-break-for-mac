//
//  ContentView.swift
//  cat-urging-a-break-for-mac
//
//  Created by hanamizuki on 2020/09/25.
//  Copyright © 2020 hanamizuki. All rights reserved.
//
import SwiftUI
import UserNotifications
import AppKit
struct ContentView: View {
    // 仕事レベル0(休憩中）
    let WORK_LEVEL_0 = 0
    // 仕事レベル1(仕事開始した直後）
    let WORK_LEVEL_1 = 1
    // 仕事レベル2(仕事開始から30分経過後）
    let WORK_LEVEL_2 = 2
    // 仕事レベル3(仕事開始から1時間経過後）
    let WORK_LEVEL_3 = 3
    // 仕事レベル4(仕事開始から1時間30分経過後）
    let WORK_LEVEL_4 = 4
    
    // 仕事レベル1(仕事開始した直後）〜10分以内
    let WORK_LEVEL_1_TIME:Double = (10 * 60)
    // 仕事レベル2(仕事開始から30分経過後）
    let WORK_LEVEL_2_TIME:Double = (30 * 60)
    // 仕事レベル3(仕事開始から1時間経過後）
    let WORK_LEVEL_3_TIME:Double = (1 * 60 * 60)
    // 仕事レベル4(仕事開始から1時間30分経過後）
    let WORK_LEVEL_4_TIME:Double = (1 * 60 * 60)+(30 * 60)

    // 猫のつぶやき
    let CAT_TWEET_0 = "（休憩は良いことにゃ〜リフレッシュにゃ〜)"
    let CAT_TWEET_1 = "（お仕事がんばってにゃ〜ねむねむにゃ…)"
    let CAT_TWEET_2 =  "（お仕事に集中することは良いことにゃ〜！）"
    let CAT_TWEET_3 = "（結構、長い間仕事してるにゃね？\n集中力すごいのにゃ〜）"
    let CAT_TWEET_4 = "（なんか長時間仕事しすぎにゃ！\nそれじゃあ肩凝るにゃ！\nそろそろ構にゃ〜！！）"
    
    // 通知時間感覚
    let NOTICE_TIME_INTERVAL:Double = (30 * 60)

    // 猫状態
    let catLevel0FramesImg:[NSImage] = [
        NSImage(imageLiteralResourceName: "coffeeblakecat1")
        ,NSImage(imageLiteralResourceName: "coffeeblakecat2")
    ]
    let catLevel1FramesImg:[NSImage] = [
        NSImage(imageLiteralResourceName: "sleepcat1")
        ,NSImage(imageLiteralResourceName: "sleepcat2")
    ]
    let catLevel2FramesImg:[NSImage] = [
        NSImage(imageLiteralResourceName: "nobicat1")
        ,NSImage(imageLiteralResourceName: "nobicat2")
    ]
    let catLevel3FramesImg:[NSImage] = [
        NSImage(imageLiteralResourceName: "sowasowa1")
        ,NSImage(imageLiteralResourceName: "sowasowa2")
    ]
    let catLevel4FramesImg:[NSImage] = [
        NSImage(imageLiteralResourceName: "runcat1")
        ,NSImage(imageLiteralResourceName: "runcat2")
        ,NSImage(imageLiteralResourceName: "runcat3")
        ,NSImage(imageLiteralResourceName: "runcat4")
        ,NSImage(imageLiteralResourceName: "runcat3")
        ,NSImage(imageLiteralResourceName: "runcat2")
    ]

    // 仕事経過時間（秒数）
    @State var workTimeInterval:Int = 0
    // ステータス
    @State var statusText:String = "仕事中"

    // 仕事レベル(1:仕事開始,2:仕事開始1時間後,3:仕事開始1時間30分後)
    @State var workLevel:Int = 1

    @State var catTweet:String =  "（お仕事がんばってにゃ〜ねむねむにゃ…)"

    // 通知した時間
    @State var notificationDate:Date = Date()
    


    @State var catLevel0FramesCount = 0
    @State var catLevel1FramesCount = 0
    @State var catLevel2FramesCount = 0
    @State var catLevel3FramesCount = 0
    @State var catLevel4FramesCount = 0

    var catFramesCountTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {_ in
            self.catLevel4FramesCount = (self.catLevel4FramesCount + 1) % catLevel4FramesImg.count
        }
    }

    var workMonitoringTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            self.catLevel0FramesCount = (self.catLevel0FramesCount + 1) % catLevel0FramesImg.count
            self.catLevel1FramesCount = (self.catLevel1FramesCount + 1) % catLevel1FramesImg.count
            self.catLevel2FramesCount = (self.catLevel2FramesCount + 1) % catLevel2FramesImg.count
            self.catLevel3FramesCount = (self.catLevel3FramesCount + 1) % catLevel3FramesImg.count

            // 最後にイベント(マウスやキーボード動かす)経過してから
            // 10以内なら仕事中とみなす
            if (isWorking(TimeInterval: WORK_LEVEL_1_TIME)) {
                self.workTimeInterval += 1
                if(self.statusText == "休憩中") {
                    Swift.print(ToStringNowTime() + ", 休憩終了")
                    self.statusText = "仕事中"
                    self.catTweet = CAT_TWEET_1
                    self.workLevel = WORK_LEVEL_1
                }
            } else if(self.statusText == "仕事中") {
                Swift.print(ToStringNowTime() + ", 休憩開始, 仕事経過時間=" + ToStringTime(timeInterval: self.workTimeInterval))
                self.statusText = "休憩中"
                self.catTweet = CAT_TWEET_0
                resetWorkTimeIntervalFunc()
                self.workLevel = WORK_LEVEL_0
            }
        }
    }

    // 30秒置きに通知を出す条件を満たしているかどうかをチェック
    var workCheckTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) {_ in
            if ( self.statusText == "仕事中" ) {
                // 前回のイベント発生時と比べて10分未満である。
                if ( isContinuousWorkFor(TimeInterval: WORK_LEVEL_4_TIME) ) {
                    // 1時間30分以上の連続作業である
                    Swift.print("[仕事中]1時間30分以上の連続作業である")
                    self.catTweet = CAT_TWEET_4
                    self.workLevel = WORK_LEVEL_4
                    if (isItTimeToNotify(TimeInterval: NOTICE_TIME_INTERVAL) ) {
                        // 前回の通知時間との差分が30分以上ある場合
                        // 通知する
                        Notify()
                        Swift.print("[仕事中]通知=>" + ToStringNowTime())
                    }
                } else if (isContinuousWorkFor(TimeInterval: WORK_LEVEL_3_TIME) ) {
                    // 1時間以上の連続作業である
                    Swift.print("[仕事中]1時間以上の連続作業である")
                    self.catTweet = CAT_TWEET_3
                    self.workLevel = WORK_LEVEL_3

                } else if (isContinuousWorkFor(TimeInterval: WORK_LEVEL_2_TIME) ) {
                    // 30分以上の連続作業である
                    Swift.print("[仕事中]30分以上の連続作業である")
                    self.catTweet = CAT_TWEET_2
                    self.workLevel = WORK_LEVEL_2
                } else {
                    Swift.print("[仕事中]30分未満の連続作業中である")
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
                    Image(nsImage: self.getCatImage())
                        .resizable()    // 画像サイズをフレームサイズに合わせる
                        .scaledToFit()      // 縦横比を維持しながらフレームに収める
                        .frame(width: 100.0, height: 100.0)

                    Text(self.catTweet)
                        .font(.caption)
                        .frame(height: 50.0)
                }
                .frame(width: 250.0)
            }
        }
        .frame(width: 400.0)
        .onAppear(perform: {
            _ = self.catFramesCountTimer
        })
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
        content.body = "仕事し続けて [" + outputDateString + "] 経過してるにゃ。そろそろ休憩しようにゃー。気分転換しようにゃー。"
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
    func getCatImage()->NSImage{
        if(self.workLevel == WORK_LEVEL_1) {
            return self.catLevel1FramesImg[self.catLevel1FramesCount]
        } else if(self.workLevel == WORK_LEVEL_2) {
            return self.catLevel2FramesImg[self.catLevel2FramesCount]
        } else if(self.workLevel == WORK_LEVEL_3) {
            return self.catLevel3FramesImg[self.catLevel3FramesCount]
        } else if(self.workLevel == WORK_LEVEL_4) {
            return self.catLevel4FramesImg[self.catLevel4FramesCount]
        }
        return self.catLevel0FramesImg[self.catLevel0FramesCount]
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
    //（最後にイベント経過してから指定時間以内ならマウスやキーボード動かし作業中）
    func isWorking(TimeInterval interval:Double)->Bool{
        let timeIntervalSince = getElapsedTimeLastEvent()
        //Swift.print(String(-timeIntervalSince))
        if ( -timeIntervalSince < interval ) {
            // 前回のイベント発生時と比べて10分未満である。
            return true
        }
        return false
    }
    // 指定時間以上の連続作業中であるかどうかを確認する
    func isContinuousWorkFor(TimeInterval interval:Double)->Bool{
        if ( Double(self.workTimeInterval) < interval ) {
            // 前回のイベント時と比べて指定時間未満である。
            return false
        }
        // 指定時間以上の連続作業である
        return true
    }

    // 通知する時間であるかどうか
    // 最後に通知してから指定時間以上経過しているかどうか
    func isItTimeToNotify(TimeInterval interval:Double)->Bool{
        let timeIntervalSince = self.notificationDate.timeIntervalSinceNow
        Swift.print(String(timeIntervalSince))
        if ( -timeIntervalSince < interval ) {
            // 前回のイベント時と比べて指定時間経過未満である。
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
