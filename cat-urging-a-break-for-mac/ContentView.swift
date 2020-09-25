//
//  ContentView.swift
//  cat-urging-a-break-for-mac
//
//  Created by hanamizuki on 2020/09/25.
//  Copyright © 2020 hanamizuki. All rights reserved.
//
import SwiftUI

struct ContentView: View {
    // 仕事経過時間（秒数）
    @State var workTimeInterval:Int = 0
    // 通知した時間
    var notificationDate:Date = Date()

    var workMonitoringTimer: Timer {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
            self.workTimeInterval += 1
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.calendar = Calendar(identifier: .japanese)
            formatter.dateFormat = "HH:mm:ss"

            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            
            
            Swift.print(formatter.string(from: appDelegate.eventDate))

        }
    }

    var body: some View {
        VStack {
            Text("仕事経過時間")
                .font(.body)
            DateTimeView(timeInterval:self.workTimeInterval)
            .frame(width: 100.0)
            .onAppear(perform: {
                _ = self.workMonitoringTimer
            })
            Button(action: resetFunc) {
                Text("リセット")
            }
        }
    }
    func resetFunc(){
        self.workTimeInterval = 0
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
