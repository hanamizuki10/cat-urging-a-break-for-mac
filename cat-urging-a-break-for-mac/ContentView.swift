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
    // 仕事レベル別経過時間
    let workTimes: [Int: Double] = [
        0: 0,
        // 仕事レベル1(仕事開始した直後）〜10分以内
        1: (10 * 60),
        // 仕事レベル2(仕事開始から30分経過後）
        2: (30 * 60),
        // 仕事レベル3(仕事開始から1時間経過後）
        3: (1 * 60 * 60),
        // 仕事レベル4(仕事開始から1時間30分経過後）
        4: (1 * 60 * 60)+(30 * 60)
    ]
    // 猫のつぶやき(ルール=0:休憩,1以降:仕事中)
    let catTweets: [Int: String] = [
        0: "（休憩は良いことにゃ〜リフレッシュにゃ〜)",
        1: "（お仕事がんばってにゃ〜ねむねむにゃ…)",
        2: "（お仕事に集中することは良いことにゃ〜！）",
        3: "（結構、長い間仕事してるにゃね？\n集中力すごいのにゃ〜）",
        4: "（なんか長時間仕事しすぎにゃ！\nそれじゃあ肩凝るにゃ！\nそろそろ構にゃ〜！！）"
    ]

    let defaultCatImg: NSImage = NSImage(imageLiteralResourceName: "coffeeblakecat1")
    
    // 猫状態(ルール=0:休憩,1以降:仕事中)
    let catFramesImgs: [Int: [NSImage]] = [
        0:[
            NSImage(imageLiteralResourceName: "coffeeblakecat1")
            ,NSImage(imageLiteralResourceName: "coffeeblakecat2")
        ],
        1:[
            NSImage(imageLiteralResourceName: "sleepcat1")
            ,NSImage(imageLiteralResourceName: "sleepcat2")
        ],
        2:[
            NSImage(imageLiteralResourceName: "nobicat1")
            ,NSImage(imageLiteralResourceName: "nobicat2")
        ],
        3:[
            NSImage(imageLiteralResourceName: "sowasowa1")
            ,NSImage(imageLiteralResourceName: "sowasowa2")
        ],
        4:[
            NSImage(imageLiteralResourceName: "runcat1")
            ,NSImage(imageLiteralResourceName: "runcat2")
            ,NSImage(imageLiteralResourceName: "runcat3")
            ,NSImage(imageLiteralResourceName: "runcat4")
            ,NSImage(imageLiteralResourceName: "runcat3")
            ,NSImage(imageLiteralResourceName: "runcat2")
        ]
    ]
    // 定数:通知時間感覚(30分おき)
    let NOTICE_TIME_INTERVAL:Double = (30 * 60)
    // 画面構築に利用する変数:仕事経過時間（秒数）
    @State var workTimeInterval:Int = 0
    // 画面構築に利用する変数:ステータス
    @State var statusText:String = "仕事中"
    // 画面構築に利用する変数:仕事レベル
    @State var workLevel:Int = 1
    // 画面構築に利用する変数:猫の呟き
    @State var catTweet:String =  "（お仕事がんばってにゃ〜ねむねむにゃ…)"
    // 画面構築に利用する変数:通知した時間
    @State var notificationDate:Date = Date()
    


    @State var catFramesCount:Int = 0

    var catFramesCountTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {_ in
            if ( self.workLevel == 4) {
                self.catFramesCount = (self.catFramesCount+1) %
                    self.getCatImageCount()
            }
        }
    }

    var workMonitoringTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            if ( self.workLevel != 4) {
                self.catFramesCount = (self.catFramesCount+1) %
                    self.getCatImageCount()
            }
            // 最後にイベント(マウスやキーボード動かす)経過してから
            if let workTimeLimit = self.workTimes[1] {
                if (isWorking(TimeInterval: workTimeLimit)) {
                    self.workTimeInterval += 1
                    if(self.statusText == "休憩中") {
                        Swift.print(ToStringNowTime() + ", 休憩終了")
                        self.statusText = "仕事中"
                        upWorkLevel()
                    }
                } else if(self.statusText == "仕事中") {
                    Swift.print(ToStringNowTime() + ", 休憩開始, 仕事経過時間=" + ToStringTime(timeInterval: self.workTimeInterval))
                    self.statusText = "休憩中"
                    resetWorkTimeIntervalFunc()
                }
            }
        }
    }

    // 30秒置きに通知を出す条件を満たしているかどうかをチェック
    var workCheckTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) {_ in
            if ( self.statusText == "仕事中" ) {
                if let workTimeLimit = self.workTimes[self.workLevel] {
                    if ( isContinuousWorkFor(TimeInterval: workTimeLimit) ) {
                        upWorkLevel()
                    }
                }
            }
        }
    }

    // レイアウト
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
    // 猫画像情報の取得
    func getCatImage()->NSImage{
        if let imgs = self.catFramesImgs[self.workLevel] {
            return imgs[self.catFramesCount]
        }
        return self.defaultCatImg
    }
    // 定義されている猫画像情報の個数取得
    func getCatImageCount()->Int{
        if let imgs = self.catFramesImgs[self.workLevel] {
            return imgs.count
        }
        return 0
    }
    // 仕事レベルUp
    func upWorkLevel() {
        self.workLevel += 1
        if ( self.workLevel >= (self.workTimes.count-1) ){
            if (isItTimeToNotify(TimeInterval: NOTICE_TIME_INTERVAL) ) {
                // 前回の通知時間との差分が30分以上ある場合
                // 通知する
                Notify()
                Swift.print("[仕事中]通知=>" + ToStringNowTime())
            }
            self.workLevel = (self.workTimes.count - 1)
        }
        if let tweet = self.catTweets[self.workLevel] {
            self.catTweet = tweet
        }
    }
    // 作業時間をリセットする
    func resetWorkTimeIntervalFunc(){
        self.workTimeInterval = 0
        self.workLevel = 0  // 0は休憩
        upWorkLevel()   // からの作業レベル1へ変更
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
