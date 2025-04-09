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
        var diffableUpdateState: DiffableUpdateState<ChatModel> = .waiting
        
        var text: String = ""
        var isFocused: Bool = false
        var inputHeight: CGFloat = 0
    }
    @CasePathable
    enum Action {
        case onAppear
        case updateChatList([ChatModel])
        case appendRandomChat
        
        case deleteChat(ChatModel)
        
//        case reloadItem
        case reconfigureItem(ChatModel)
        
        case reloadItem(ChatModel)
        
        case reload(ChatModel)
        
        case updateDiffableUpdateState(DiffableUpdateState<ChatModel>)
        
        case updateText(String)
        case updateIsFocused(Bool)
        case updateInputHeight(CGFloat)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.chatList = ChatModel.makeEmptyData()
                state.diffableUpdateState = .onAppear(isScroll: true)
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
                
                state.diffableUpdateState = .appendItem(isScroll: true)
                return .none
                
            case .deleteChat(let chatModel):
                if let matchIndex: Array<ChatModel>.Index = state.chatList.firstIndex(of: chatModel) {
                    state.chatList[matchIndex].chatType = .delete
                    print("\(#function) state.chatList[matchIndex].chatType: \(state.chatList[matchIndex].id)")
                    state.diffableUpdateState = .reconfigure(isScroll: true)
                }
                
                return .none
                
            case .reloadItem(let chatModel):
                if let matchIndex: Array<ChatModel>.Index = state.chatList.firstIndex(of: chatModel) {
                    state.chatList[matchIndex].chatType = .delete
                    state.diffableUpdateState = .reloadItemAnimate(isScroll: true)
                }
                return .none
                
            case .reload(let chatModel):
                if let matchIndex: Array<ChatModel>.Index = state.chatList.firstIndex(of: chatModel) {
                    state.chatList[matchIndex].chatType = .delete
                    state.diffableUpdateState = .reload(isScroll: true)
                }
                return .none
                
            case .reconfigureItem(let chatModel):
                if let matchIndex: Array<ChatModel>.Index = state.chatList.firstIndex(of: chatModel) {
                    state.chatList[matchIndex].imgUrl = "https://blog.kakaocdn.net/dn/dUy6fR/btrqmqsWSKk/ub13rlAwt1KMKvYHyvul61/img.png"
                    state.diffableUpdateState = .reconfigureAnimate(isScroll: false)
                }
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
