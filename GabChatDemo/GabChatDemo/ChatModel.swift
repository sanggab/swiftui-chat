//
//  ChatModel.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import Foundation

import GabChat

@frozen
public enum ChatType: CaseIterable, Equatable {
    case text
    case img
    case delete
}

@frozen
public enum SendType: CaseIterable, Equatable {
    case send
    case receive
}

@frozen
public enum UpdateType: CaseIterable, Equatable {
    case none
    case reload
    case reconfigure
    case scrollToBottom
    case isFoucsed
}

public struct ChatModel: Hashable, Identifiable, Sendable {
    public static func == (lhs: ChatModel, rhs: ChatModel) -> Bool {
        lhs.id == rhs.id &&
        lhs.memNo == rhs.memNo &&
        lhs.chatType == rhs.chatType &&
        lhs.sendType == rhs.sendType &&
        lhs.text == rhs.text &&
        lhs.imgUrl == rhs.imgUrl &&
        lhs.msgNo == rhs.msgNo
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
        hasher.combine(self.memNo)
        hasher.combine(self.chatType)
        hasher.combine(self.sendType)
        hasher.combine(self.text)
        hasher.combine(self.imgUrl)
        hasher.combine(self.msgNo)
    }
    
    public typealias ID = String
    
    public var id: ID = UUID().uuidString
    
    public var memNo: Int
    public var chatType: ChatType
    public var sendType: SendType
    public var text: String
    public var imgUrl: String?
    public var msgNo: Int
    public var insDate: Int
    
    public init(memNo: Int, chatType: ChatType, sendType: SendType, text: String = "", imgUrl: String? = nil, msgNo: Int, insDate: Int) {
        self.memNo = memNo
        self.chatType = chatType
        self.sendType = sendType
        self.text = text
        self.imgUrl = imgUrl
        self.msgNo = msgNo
        self.insDate = insDate
    }
    
    public static func makeEmptyData() -> [ChatModel] {
        return [
            ChatModel(memNo: 2805, chatType: .text, sendType: .send, text: "안녕! 첫 번째 메시지야!", imgUrl: nil, msgNo: 1, insDate: 1740320000),
            ChatModel(memNo: 3699, chatType: .text, sendType: .send, text: "안녕! 둘 번째 메시지야!", imgUrl: nil, msgNo: 2, insDate: 1744135000),
            ChatModel(memNo: 2805, chatType: .text, sendType: .send, text: "안녕! 셋 번째 메시지야!", imgUrl: nil, msgNo: 3, insDate: 1744230000),
            ChatModel(memNo: 2805, chatType: .img, sendType: .send, text: "안녕! 넷 번째 메시지야!", imgUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSohVs9nQ1O_NjtL0Bg0RiOFBKXU3Kgv327-A&s", msgNo: 4, insDate: 1744231385),
            ChatModel(memNo: 3699, chatType: .text, sendType: .send, text: "안녕! 다섯 번째 메시지야!", imgUrl: nil, msgNo: 5, insDate: 1744231385),
            ChatModel(memNo: 3699, chatType: .img, sendType: .send, text: "안녕! 여셧 번째 메시지야!", imgUrl: "https://upload3.inven.co.kr/upload/2023/03/29/bbs/i15472657350.jpg", msgNo: 6, insDate: 1744231385),
            ChatModel(memNo: 2805, chatType: .text, sendType: .send, text: "안녕! 일곱 번째 메시지야!", imgUrl: nil, msgNo: 7, insDate: 1744231385),
            ChatModel(memNo: 3699, chatType: .img, sendType: .send, text: "안녕! 여덟 번째 메시지야!", imgUrl: "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR_z2Jno6IFeX6KIS0qHoa-bQYvS0dwcCiuMNe2O_Yrv3UPfk3ZTsjy-V-wlenduXaWI38&usqp=CAU", msgNo: 8, insDate: 1744239000),
            ChatModel(memNo: 3699, chatType: .img, sendType: .send, text: "안녕! 아홉 번째 메시지야!", imgUrl: "https://upload3.inven.co.kr/upload/2023/02/25/bbs/i14655432921.jpg", msgNo: 9, insDate: 1744239598),
            ChatModel(memNo: 3699, chatType: .text, sendType: .send, text: "안녕! 열 번째 메시지야!", imgUrl: nil, msgNo: 10, insDate: 1744241300),
            ChatModel(memNo: 2805, chatType: .text, sendType: .send, text: "안녕! 열 하나 번째 메시지야!", imgUrl: nil, msgNo: 11, insDate: 1744241385)
        ]
    }
}

extension Int {
    func makeLocaleDate(isLTR: Bool = true) -> String {
        
        let timeInterval = TimeInterval(self)
        
        let timeDate = Date(timeIntervalSince1970: timeInterval)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = .current
        dateFormatter.timeZone = .current
        
        return dateFormatter.string(from: timeDate)
    }
}
