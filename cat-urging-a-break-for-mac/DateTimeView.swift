//
//  DateTimeView.swift
//  cat-urging-a-break-for-mac
//
//  Created by hanamizuki on 2020/09/25.
//  Copyright © 2020 hanamizuki. All rights reserved.
//

import SwiftUI

struct DateTimeView: View {
    var timeInterval: Int
    var body: some View {
        Text(ToStringTime(timeInterval: self.timeInterval))
            .font(.body)
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
}

struct DateTimeView_Previews: PreviewProvider {
    static var previews: some View {
        DateTimeView(timeInterval:0)
    }
}
