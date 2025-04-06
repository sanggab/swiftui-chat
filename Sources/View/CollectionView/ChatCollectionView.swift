//
//  ChatCollectionView.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

public struct ChatCollectionView<ContentView: View, ChatModel: Hashable>: UIViewRepresentable {
    
    @ViewBuilder let itemBuilderClosure: (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView
    
    @Binding var keyboardOption: KeyboardOption
    let inputHeight: CGFloat
    let safeAreaInsetBottom: CGFloat
    
    @State var inputUpdateState: InputUpdateState = .waiting
    @State var previousInputHeight: CGFloat = 0
    @State var previousKeyboardHeight: CGFloat = 0
    
    @Binding var diffableUpdateState: DiffableUpdateState
    @Binding var chatList: [ChatModel]
    
    public init(
        chatList: Binding<[ChatModel]>,
        keyboardOption: Binding<KeyboardOption>,
        diffableUpdateState: Binding<DiffableUpdateState>,
        inputHeight: CGFloat,
        safeAreaInsetBottom: CGFloat,
        @ViewBuilder itemBuilderClosure: @escaping (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView,) {
            self._keyboardOption = keyboardOption
            self._diffableUpdateState = diffableUpdateState
            self.inputHeight = inputHeight
            self.safeAreaInsetBottom = safeAreaInsetBottom
            self._chatList = chatList
            self.itemBuilderClosure = itemBuilderClosure
        }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let collectionView: UICollectionView = .init(frame: .zero,
                                                     collectionViewLayout: context.coordinator.createCompositionalLayout())
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "chatcell")
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = context.coordinator
        
        context.coordinator.setDataSource(view: collectionView)
        context.coordinator.setData(item: self.chatList)
        
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        self.conditionInputUpdateState(uiView, context: context)
        self.conditionDiffableUpdateState(uiView, context: context)
    }
    
    public func makeCoordinator() -> ChatCoordinator<ContentView, ChatModel> {
        return ChatCoordinator(itemBuilder: self.itemBuilderClosure)
    }
}

extension ChatCollectionView {
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
    func conditionDiffableUpdateState(_ uiView: UICollectionView, context: Context) {
        
    }
}
