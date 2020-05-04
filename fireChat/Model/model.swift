//
//  model.swift
//  fireChat
//
//  Created by 李郁祥 on 2020/1/8.
//  Copyright © 2020 Corgi. All rights reserved.
//

import Foundation

class Channel{
    var id: String?
    var name: String?
    var text: String?
    var url: URL?
    var timeStamp: String
    init(id: String, name:String, text:String, url:URL, timeStamp:String){
        self.id = id
        self.name = name
        self.text = text
        self.url = url
        self.timeStamp = timeStamp
    }
}
enum ViewTitle : Int , CaseIterable {
    case Room = 0, Option
    var title: String {
        switch self {
        case .Room:
            return "聊天室"
        case .Option:
            return "個人資料"
        }
    }
}
