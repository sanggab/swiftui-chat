//
//  ContentView.swift
//  GabChatDemo
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

import GabChat
import GabTextView

import ComposableArchitecture

struct ContentView: View {
    @Perception.Bindable var store: StoreOf<GabChatDemoReducer>
    
    @FocusState private var isFocused
    
    init(store: StoreOf<GabChatDemoReducer>) {
        self.store = store
    }
    
    var body: some View {
        WithPerceptionTracking {
            ChatView(chatList: $store.chatList.sending(\.updateChatList)) { (before: ChatModel?, current: ChatModel) in
                switch current.chatType {
                case .text:
                    TextCell(text: current.text)
                case .img:
                    ImageCell(urlString: current.imgUrl ?? "")
                case .delete:
                    DeletedCell()
                }
            } inputBuilderClosure: {
                WithPerceptionTracking {
                    TextView(text: $store.text.sending(\.updateText))
                        .textViewConfiguration { textView in
                            textView.backgroundColor = .systemPink
                            textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                            textView.textContainer.lineFragmentPadding = .zero
                        }
                        .receiveTextViewHeight{ store.send(.updateInputHeight($0)) }
                        .setTextViewAppearanceModel(.default)
                        .overlayPlaceHolder(.leading) {
                            Text("메시지를 입력해주세요.")
                        }
                        .frame(height: store.inputHeight)
                        .frame(maxWidth: .infinity)
                        .focused($isFocused)
                        .bind($store.isFocused.sending(\.updateIsFocused), to: $isFocused)
                }
            }
            .background(.mint)
            .onTapGesture {
                isFocused = false
            }
        }

    }
}

#Preview {
    let store: StoreOf<GabChatDemoReducer> = .init(initialState: GabChatDemoReducer.State()) {
        GabChatDemoReducer()
    }
    
    ContentView(store: store)
}
