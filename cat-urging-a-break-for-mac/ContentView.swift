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
    
    var appDelegate: AppDelegate
    var judgeConfigs: [WorkJudge] = []
    // 状態変更に関係する判断設定
    class WorkJudge {
        // 経過時間
        var workTime: Double = 0
        // 経過時間を経過時に呟く内容
        var catTweet: String = ""
        // 経過時間を経過時に表示する画像データ
        var catFramesImg: [NSImage] = []
        // 画像データを切り替えるタイミング
        var switchInterval: Double = 0
        init(workTime:Double, catTweet: String, catFramesImg: [NSImage], switchInterval: Double) {
            self.workTime = workTime
            self.catTweet = catTweet
            self.catFramesImg = catFramesImg
            self.switchInterval = switchInterval
        }
    }
    // 定数:デフォルト猫画像
    let DEFAULT_CAT_IMG: NSImage = NSImage(imageLiteralResourceName: "coffeeblakecat1")
    // 画面構築に利用する変数:猫の呟き
    let DEFAULT_CAT_TWEET: String = "（お仕事がんばってにゃ〜ねむねむにゃ…)"

    // 定数:仕事中か休憩中かを判断するキーとなる時間
    let WORK_OR_BREK_JUDGE_TIME: Double = (10 * 60)
    // 定数:通知時間感覚(30分おき)
    let NOTICE_TIME_INTERVAL:Double = (30 * 60)
    // 定数:仕事監視タイマーの実行間隔
    let WORK_MONITORING_TIMER_INTERVAL:Double = 1
    // 定数:高速切り替えタイマーの実行間隔（パラパラ表示させたい猫画像用）
    let HIGH_SPEED_SWITCHINGTIMER_INTERVAL: Double = 0.1

    // 画面構築に利用する変数:仕事経過時間（秒数）
    @State var workTimeInterval:Int = 0
    // 画面構築に利用する変数:休憩経過時間（秒数）
    @State var breakTimeInterval:Int = 0
    // 画面構築に利用する変数:ステータス
    @State var statusText:String = "仕事中"
    // 画面構築に利用する変数:仕事レベル
    @State var workLevel:Int = 1
    // 画面構築に利用する変数:通知した時間
    @State var notificationDate:Date = Date()
    // 画像のINDEX値
    @State var imgIndex:Int = 0

    init() {
        Swift.print("初期設定！")
        self.appDelegate = NSApplication.shared.delegate as! AppDelegate

        // 仕事レベル0(休憩中)
        let judge0 = WorkJudge(workTime: 0, catTweet: "（休憩は良いことにゃ〜リフレッシュにゃ〜)", catFramesImg: [
            NSImage(imageLiteralResourceName: "coffeeblakecat1")
            ,NSImage(imageLiteralResourceName: "coffeeblakecat2")
        ], switchInterval:self.WORK_MONITORING_TIMER_INTERVAL)
        // 仕事レベル1(仕事開始した直後）〜30分以内
        let judge1 = WorkJudge(workTime: 0, catTweet: "（お仕事がんばってにゃ〜ねむねむにゃ…)", catFramesImg: [
            NSImage(imageLiteralResourceName: "sleepcat1")
            ,NSImage(imageLiteralResourceName: "sleepcat2")
        ], switchInterval:self.WORK_MONITORING_TIMER_INTERVAL)
        // 仕事レベル2(仕事開始から30分経過後）
        let judge2 = WorkJudge(workTime: (30 * 60), catTweet: "（お仕事に集中することは良いことにゃ〜！）", catFramesImg: [
            NSImage(imageLiteralResourceName: "nobicat1")
            ,NSImage(imageLiteralResourceName: "nobicat2")
        ], switchInterval:self.WORK_MONITORING_TIMER_INTERVAL)
        // 仕事レベル3(仕事開始から1時間経過後）
        let judge3 = WorkJudge(workTime: (1 * 60 * 60), catTweet: "（結構、長い間仕事してるにゃね？\n集中力すごいのにゃ〜）", catFramesImg: [
            NSImage(imageLiteralResourceName: "sowasowa1")
            ,NSImage(imageLiteralResourceName: "sowasowa2")
        ], switchInterval:self.WORK_MONITORING_TIMER_INTERVAL)
        // 仕事レベル4(仕事開始から1時間30分経過後）
        let judge4 = WorkJudge(workTime: (1 * 60 * 60)+(30 * 60), catTweet: "（なんか長時間仕事しすぎにゃ！\nそれじゃあ肩凝るにゃ！\nそろそろ構にゃ〜！！）", catFramesImg: [
            NSImage(imageLiteralResourceName: "runcat1")
            ,NSImage(imageLiteralResourceName: "runcat2")
            ,NSImage(imageLiteralResourceName: "runcat3")
            ,NSImage(imageLiteralResourceName: "runcat4")
            ,NSImage(imageLiteralResourceName: "runcat3")
            ,NSImage(imageLiteralResourceName: "runcat2")
        ], switchInterval:self.HIGH_SPEED_SWITCHINGTIMER_INTERVAL)

        judgeConfigs.append(judge0)
        judgeConfigs.append(judge1)
        judgeConfigs.append(judge2)
        judgeConfigs.append(judge3)
        judgeConfigs.append(judge4)
    }


    // 画像を高速に切り替える用のタイマー
    var imgHighSpeedSwitchingTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: HIGH_SPEED_SWITCHINGTIMER_INTERVAL, repeats: true) {_ in
            updateCatFramesCount(withTimeInterval: HIGH_SPEED_SWITCHINGTIMER_INTERVAL)
        }
    }

    // 作業監視モニター
    var workMonitoringTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: WORK_MONITORING_TIMER_INTERVAL, repeats: true) {_ in
            updateCatFramesCount(withTimeInterval: WORK_MONITORING_TIMER_INTERVAL)
            // 最後にイベント(マウスやキーボード動かす)経過してから
            if (isWorking(TimeInterval: WORK_OR_BREK_JUDGE_TIME)) {
                self.workTimeInterval += 1
                if(self.statusText == "休憩中") {
                    Swift.print(ToStringTime(date:Date()) + ", 休憩終了, 最終休憩経過時間=" + ToStringTime(timeInterval: self.breakTimeInterval))
                    self.breakTimeInterval = 0
                    self.workTimeInterval = 0
                    self.statusText = "仕事中"
                    self.workLevel = 1  // 1は仕事始め
                }
            } else if(self.statusText == "仕事中") {
                Swift.print(ToStringTime(date:Date()) + ", 休憩開始, 最終仕事経過時間=" + ToStringTime(timeInterval: self.workTimeInterval))
                self.breakTimeInterval = 0
                self.statusText = "休憩中"
                self.workLevel = 0  // 0は休憩
            } else if(self.statusText == "休憩中") {
                self.breakTimeInterval += 1
            }

        }
    }

    // 30秒置きに通知を出す条件を満たしているかどうかをチェック
    var workCheckTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) {_ in
            if ( self.statusText == "仕事中" ) {
                if ((self.workLevel+1) < self.judgeConfigs.count) {
                    let judge = self.judgeConfigs[(self.workLevel+1)]
                    if ( isContinuousWorkFor(TimeInterval: judge.workTime) ) {
                        upWorkLevel()
                    }
                } else {
                    if (isItTimeToNotify(TimeInterval: NOTICE_TIME_INTERVAL) ) {
                        // 前回の通知時間との差分が30分以上ある場合
                        // 通知する
                        Notify()
                        Swift.print("[仕事中]通知=>" + ToStringTime(date:Date()))
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
            Divider()
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
                    .padding(.bottom)
                    Button(action: resetWorkTimeIntervalFunc) {
                        Text("リセット")
                    }

                }
                .frame(width: 100.0)
                VStack {
                    Image(nsImage: self.getCatImage())
                        .resizable()    // 画像サイズをフレームサイズに合わせる
                        .scaledToFit()      // 縦横比を維持しながらフレームに収める
                        .frame(width: 100.0, height: 100.0)

                    Text(self.getCatTweet())
                        .font(.caption)
                        .frame(height: 50.0)
                }
                .frame(width: 250.0)
            }
            Divider()
            HStack {
                Text("休憩経過時間->")
                    .font(.caption)
                Text(ToStringTime(timeInterval: self.breakTimeInterval))
                    .font(.caption)
                Text(", 最後にイベント検知した時刻->")
                    .font(.caption)
                Text(ToStringTime(date: self.appDelegate.eventDate))
                    .font(.caption)

            }
        }
        .frame(width: 400.0)
        .onAppear(perform: {
            _ = self.imgHighSpeedSwitchingTimer
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
        if (self.workLevel < self.judgeConfigs.count) {
            let judge = self.judgeConfigs[self.workLevel]
            if (self.imgIndex < judge.catFramesImg.count) {
                return judge.catFramesImg[self.imgIndex]
            }
            return judge.catFramesImg[0]
        }
        return DEFAULT_CAT_IMG
    }
    // レベルにあった猫のツイートを取得
    func getCatTweet()->String {
        if (self.workLevel < self.judgeConfigs.count) {
            let judge = self.judgeConfigs[self.workLevel]
            return judge.catTweet
        }
        return DEFAULT_CAT_TWEET
    }
    // 定義されている猫画像情報の個数取得
    func updateCatFramesCount(withTimeInterval: Double) {
        if (self.workLevel < self.judgeConfigs.count) {
            let judge = self.judgeConfigs[self.workLevel]
            if (judge.switchInterval == withTimeInterval) {
                self.imgIndex = (self.imgIndex+1) %
                    judge.catFramesImg.count
            }
        }

    }
    // 仕事レベルUp
    func upWorkLevel() {
        self.workLevel += 1
        if (self.workLevel == self.judgeConfigs.count) {
            self.workLevel = self.judgeConfigs.count - 1
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
    func ToStringTime(date:Date)->String{
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }


    // 現在動作中であるかどうか確認する
    //（最後にイベント経過してから指定時間以内ならマウスやキーボード動かし作業中）
    func isWorking(TimeInterval interval:Double)->Bool{
        // 最後にイベントが発生してから経過した時間を取得する
        let timeIntervalSince = appDelegate.eventDate.timeIntervalSinceNow
        if ( -timeIntervalSince < interval ) {
            // 前回のイベント発生時と比べて10分未満である。
            //Swift.print(String(-timeIntervalSince) + " true")
            return true
        }
        //Swift.print(String(-timeIntervalSince) + " false")
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
