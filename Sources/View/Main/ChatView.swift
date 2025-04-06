//
//  ChatView.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

public struct ChatView<ContentView: View, InputView: View, ChatModel: Hashable>: View {
    
    @ViewBuilder private let itemBuilderClosure: (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView
    
    @ViewBuilder private let inputBuilderClosure: () -> InputView
    
    @Binding public var chatList: [ChatModel]
    
    @State private var keyboardOption: KeyboardOption = .default
    @State private var updateState: UpdateState = .waiting
    
    @State private var inputHeight: CGFloat = 0
    @State private var insetBottom: CGFloat = 0
    
    @State private var oldChatList: [ChatModel] = []
    
    public init(chatList: Binding<[ChatModel]>,
                @ViewBuilder itemBuilderClosure: @escaping (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView,
                @ViewBuilder inputBuilderClosure: @escaping () -> InputView) {
        self._chatList = chatList
        self.itemBuilderClosure = itemBuilderClosure
        self.inputBuilderClosure = inputBuilderClosure
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ChatCollectionView(chatList: self.$chatList,
                               keyboardOption: self.$keyboardOption,
                               updateState: self.$updateState,
                               inputHeight: self.inputHeight,
                               safeAreaInsetBottom: self.insetBottom,
                               itemBuilderClosure: self.itemBuilderClosure)
            
            inputBuilderClosure()
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .frame(width: 0, height: 0)
                            .hidden()
                            .preference(key: InputHeightKey.self, value: proxy.size.height)
                            .onAppear {
                                self.insetBottom = proxy.safeAreaInsets.bottom
                            }
                    }
                }
        }
        .onPreferenceChange(InputHeightKey.self) { self.inputHeight = $0 }
        .keyboardWillShow { option in
            self.updateState = .keyboard
            self.keyboardOption = option
        }
        .keyboardWillHide { option in
            self.updateState = .keyboard
            self.keyboardOption = option
        }
        .onChange(of: chatList) { newValue in
            
        }
    }
}
