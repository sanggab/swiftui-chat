//
//  ChatView.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

public struct ChatView<ContentView: View, InputView: View, ChatModel: Hashable & Identifiable>: View {
    
    @ViewBuilder private let itemBuilderClosure: (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView
    
    @ViewBuilder private let inputBuilderClosure: () -> InputView
    
    private var isRefresh: (() -> Void)?
    private var onScrollBeyondThreshold: ((Bool) -> Void)?
    
    @Binding var chatList: [ChatModel]
    @Binding public var diffableUpdateState: DiffableUpdateState
    
    @State private var inputUpdateState: InputUpdateState = .waiting
    @State private var keyboardOption: KeyboardOption = .default
    
    @State private var inputHeight: CGFloat = 0
    @State private var insetBottom: CGFloat = 0
    @Binding private var isThreshold: Bool
    private var threshold: CGFloat = 100
    private var backgroundColor: Color = .white
    
    public init(chatList: Binding<[ChatModel]>,
                diffableUpdateState: Binding<DiffableUpdateState>,
                @ViewBuilder itemBuilderClosure: @escaping (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView,
                @ViewBuilder inputBuilderClosure: @escaping () -> InputView) {
        self._chatList = chatList
        self._diffableUpdateState = diffableUpdateState
        self.itemBuilderClosure = itemBuilderClosure
        self.inputBuilderClosure = inputBuilderClosure
        self._isThreshold = .constant(false)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ChatCollectionView(chatList: self.$chatList,
                               keyboardOption: self.$keyboardOption,
                               inputUpdateState: self.$inputUpdateState,
                               diffableUpdateState: self.$diffableUpdateState,
                               inputHeight: self.inputHeight,
                               safeAreaInsetBottom: self.insetBottom,
                               itemBuilderClosure: self.itemBuilderClosure)
            .detechRefresh {
                isRefresh?()
            }
            .onScrollBeyondThreshold { bool in
                DispatchQueue.main.async {
                    self.onScrollBeyondThreshold?(bool)
                    self.isThreshold = bool
                }
            }
            .backgroundColor(color: backgroundColor)
            
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
            self.inputUpdateState = .keyboard
            self.keyboardOption = option
        }
        .keyboardWillHide { option in
            self.inputUpdateState = .keyboard
            self.keyboardOption = option
        }
    }
    /// 새로고침 Indicaator가 끝났을 때, refresh를 하라고 알려주는 기능
    public func detechRefresh(isRefresh: @escaping (() -> Void)) -> ChatView {
        var view: ChatView = self
        view.isRefresh = isRefresh
        return view
    }
    /// 채팅의 스크롤이 ``setThreshold(_:)``로 설정한 한계점에 걸렸는 지 알려주는 기능
    public func onScrollBeyondThreshold(_ threshold: @escaping ((Bool) -> Void)) -> ChatView {
        var view: ChatView = self
        view.onScrollBeyondThreshold = threshold
        return view
    }
    /// 채팅의 스크롤이 ``setThreshold(_:)``로 설정한 한계점에 걸렸는 지 알려주는 기능
    public func onScrollBeyondThreshold(_ threshold: Binding<Bool>) -> ChatView {
        var view: ChatView = self
        view._isThreshold = threshold
        return view
    }
    /// 스크롤이 하단으로부터 얼만큼 이동했는 지를 판단하는 한계점을 설정합니다.
    ///
    /// 일반적으로, 채팅에서 Floating 메시지를 띄워야 할 경우
    /// 채팅 아래서 부터 y 좌표가 얼마나 떨어져 있냐에 따라 노출 조건이 다르게 때문에
    /// threshold을 설정해서 컨트롤 합니다.
    ///
    /// > Note: 기본적으로 설정을 안 할 경우에, threshold의 기본 값은 100입니다.
    public func setThreshold(_ threshold: CGFloat) -> ChatView {
        var view: ChatView = self
        view.threshold = threshold
        return view
    }
    /// UICollectionView의 backgroundColor를 바꿉니다.
    public func backgroundColor(color: Color) -> ChatView {
        var view: ChatView = self
        view.backgroundColor = color
        return view
    }
}
