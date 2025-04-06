//
//  Reducer.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import Foundation

import GabChat

import ComposableArchitecture



@Reducer
struct GabChatDemoReducer {
    @ObservableState
    struct State {
        var chatList: [ChatModel] = []
        var diffableUpdateState: DiffableUpdateState = .waiting
        
        var text: String = ""
        var isFocused: Bool = false
        var inputHeight: CGFloat = 0
    }
    
    enum Action {
        case onAppear
        case updateChatList([ChatModel])
        case appendRandomChat
        
        case updateDiffableUpdateState(DiffableUpdateState)
        
        case updateText(String)
        case updateIsFocused(Bool)
        case updateInputHeight(CGFloat)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.chatList = ChatModel.makeEmptyData()
                return .none
                
            case .updateChatList(let list):
                state.chatList = list
                return .none
                
            case .appendRandomChat:
                let imgUrl: String = [
                    "https://upload3.inven.co.kr/upload/2021/12/21/bbs/i15560686762.jpg?MW=800",
                    "https://upload3.inven.co.kr/upload/2023/11/21/bbs/i17226991301.png",
                    "https://upload3.inven.co.kr/upload/2023/04/03/bbs/i16565482795.jpg",
                    "https://blog.kakaocdn.net/dn/wvqpM/btsGipRVL6d/AhIj0Nz1bIhwnuH0kPXxoK/img.png",
                    "https://blog.kakaocdn.net/dn/TuHKu/btsGh6ryrVl/dgGhaIJkTE6amKtPmPmjbk/img.png",
                    "https://blog.kakaocdn.net/dn/YmNKq/btsGfKpuSFE/cAK39BdCDBiQIGoMREv0jK/img.png",
                    "https://upload3.inven.co.kr/upload/2021/12/19/bbs/i14150561074.jpg?MW=800",
                    "https://upload3.inven.co.kr/upload/2023/04/18/bbs/i15352384603.jpg",
                    "https://upload3.inven.co.kr/upload/2022/01/15/bbs/i14731996853.jpg?MW=800",
                    "https://upload3.inven.co.kr/upload/2023/08/16/bbs/i16976596468.png"
                ].randomElement() ?? "안댕"
                
                let newMsgNo: Int = (state.chatList.last?.msgNo ?? -99) + 1
                
                let newChatModel: ChatModel = .init(memNo: 2805, chatType: .img, sendType: .send, imgUrl: imgUrl, msgNo: newMsgNo)
                
                state.chatList.append(newChatModel)
                
                return .none
                
            case .updateDiffableUpdateState(let diffableUpdateState):
                state.diffableUpdateState = diffableUpdateState
                return .none
            
            case .updateText(let text):
                state.text = text
                return .none
                
            case .updateIsFocused(let isFoucsed):
                state.isFocused = isFoucsed
                return .none
                
            case .updateInputHeight(let height):
                state.inputHeight = height
                return .none
            }
        }
    }
}
