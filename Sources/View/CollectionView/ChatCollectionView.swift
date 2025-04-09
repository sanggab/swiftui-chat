//
//  ChatCollectionView.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

public struct ChatCollectionView<ContentView: View, ChatModel: ItemProtocol>: UIViewRepresentable {
    
    @ViewBuilder let itemBuilderClosure: (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView
    
    @Binding var keyboardOption: KeyboardOption
    let inputHeight: CGFloat
    let safeAreaInsetBottom: CGFloat
    
    @State var inputUpdateState: InputUpdateState = .waiting
    @State var previousInputHeight: CGFloat = 0
    @State var previousKeyboardHeight: CGFloat = 0
    
    @Binding var diffableUpdateState: DiffableUpdateState<ChatModel>
    let chatList: [ChatModel]
    
    public init(
        chatList: [ChatModel],
        keyboardOption: Binding<KeyboardOption>,
        diffableUpdateState: Binding<DiffableUpdateState<ChatModel>>,
        inputHeight: CGFloat,
        safeAreaInsetBottom: CGFloat,
        @ViewBuilder itemBuilderClosure: @escaping (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView) {
            self._keyboardOption = keyboardOption
            self._diffableUpdateState = diffableUpdateState
            self.inputHeight = inputHeight
            self.safeAreaInsetBottom = safeAreaInsetBottom
            self.chatList = chatList
            self.itemBuilderClosure = itemBuilderClosure
        }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let collectionView: UICollectionView = .init(frame: .zero,
                                                     collectionViewLayout: context.coordinator.createCompositionalLayout())
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "chatcell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = context.coordinator
        
        context.coordinator.setDataSource(view: collectionView)
//        context.coordinator.setData(item: self.chatList)
        
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
//        print("\(#function) inputUpdateState: \(self.inputUpdateState)")
//        print("\(#function) diffableUpdateState: \(self.diffableUpdateState)")
//        print("\(#function) chatList: \(self.chatList)")
//        print("\(#function) diffableUpdateState: \(context.coordinator.check())")
        self.conditionInputUpdateState(uiView, context: context)
        self.conditionDiffableUpdateState(uiView, context: context)
    }
    
    public func makeCoordinator() -> ChatCoordinator<ContentView, ChatModel> {
        return ChatCoordinator(itemBuilder: self.itemBuilderClosure)
    }
}

extension ChatCollectionView {
    @MainActor
    func conditionInputUpdateState(_ uiView: UICollectionView, context: Context) {
        switch self.inputUpdateState {
        case .waiting:
            self.waitingAction()
        case .textInput:
            self.textInputAction(uiView)
        case .keyboard:
            self.controlOffsetWithKeyboard(uiView)
        }
    }
}

extension ChatCollectionView {
    @MainActor
    func conditionDiffableUpdateState(_ uiView: UICollectionView, context: Context) {
//        print("\(#function) self.chatList: \(self.chatList)")
//        print("\(#function) previousChatList: \(previousChatList)")
//        print("same : \(self.chatList == self.previousChatList)")
        switch self.diffableUpdateState {
        case .onAppear:
            self.diffableOnAppearAction(uiView, context: context)
        case .waiting:
            print("대기..")
        case .appendItem(let isScroll):
            self.appendItem(uiView, context: context, isScroll: isScroll)
        case .reload:
            self.reloadAction(uiView, context: context)
        case .reloadItem:
            self.reloadItemAction(uiView, context: context)
        case .reconfigure(let isScroll):
            self.reconfigure(uiView, context: context, isScroll: isScroll)
        case .reconfigureAnimate(let isScroll):
            self.reconfigureAnimate(uiView, context: context, isScroll: isScroll)
        case .hi(let item):
            print("상갑 logEvent \(#function) hi")
        }
    }
}

extension ChatCollectionView {
    @MainActor
    func diffableOnAppearAction(_ uiView: UICollectionView, context: Context) {
        Task {
            await context.coordinator.onAppear(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: false)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    func appendItem(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            let success: Bool = await context.coordinator.appendItem(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && success {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    func reloadAction(_ uiView: UICollectionView, context: Context) {
        Task {
//            await context.coordinator.reconfigure(item: self.chatList)
        }
    }
    
    func reloadItemAction(_ uiView: UICollectionView, context: Context) {
        Task {
            
        }
    }
    
    func reconfigure(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        print("\(#function)")
        Task {
            await context.coordinator.reconfigureWithoutAnimating(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    func reconfigureAnimate(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        print("\(#function)")
        Task {
            await context.coordinator.reconfigureWithAnimating(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }

}
