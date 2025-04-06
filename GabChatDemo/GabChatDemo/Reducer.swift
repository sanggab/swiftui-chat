//
//  Reducer.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import Foundation
import ComposableArchitecture



@Reducer
struct GabChatDemoReducer {
    @ObservableState
    struct State {
        var chatList: [ChatModel] = []
        
        
        var text: String = ""
        var isFocused: Bool = false
        var inputHeight: CGFloat = 0
    }
    
    enum Action {
        case onAppear
        case updateChatList([ChatModel])
        
        
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
