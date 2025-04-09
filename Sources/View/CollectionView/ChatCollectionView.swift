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
    
    @Binding var inputUpdateState: InputUpdateState
    @State var previousInputHeight: CGFloat = 0
    @State var previousKeyboardHeight: CGFloat = 0
    
    @Binding var diffableUpdateState: DiffableUpdateState<ChatModel>
    let chatList: [ChatModel]
    
    public init(
        chatList: [ChatModel],
        keyboardOption: Binding<KeyboardOption>,
        inputUpdateState: Binding<InputUpdateState>,
        diffableUpdateState: Binding<DiffableUpdateState<ChatModel>>,
        inputHeight: CGFloat,
        safeAreaInsetBottom: CGFloat,
        @ViewBuilder itemBuilderClosure: @escaping (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView) {
            self._keyboardOption = keyboardOption
            self._inputUpdateState = inputUpdateState
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
        if self.inputUpdateState != .keyboard {
            switch self.diffableUpdateState {
            case .onAppear(let isScroll):
                self.diffableOnAppearAction(uiView, context: context, isScroll: isScroll)
            case .waiting:
                print("대기..")
            case .appendItem(let isScroll):
                self.appendItem(uiView, context: context, isScroll: isScroll)
            case .reload(let isScroll):
                self.reloadAction(uiView, context: context, isScroll: isScroll)
            case .reloadAnimate(let isScroll):
                self.reloadAnimateAction(uiView, context: context, isScroll: isScroll)
            case .reloadItem(let isScroll):
                self.reloadItemAction(uiView, context: context, isScroll: isScroll)
            case .reloadItemAnimate(let isScroll):
                self.reloadItemAnimateAction(uiView, context: context, isScroll: isScroll)
            case .reconfigure(let isScroll):
                self.reconfigureAction(uiView, context: context, isScroll: isScroll)
            case .reconfigureAnimate(let isScroll):
                self.reconfigureAnimateAction(uiView, context: context, isScroll: isScroll)
            case .hi(let item):
                print("상갑 logEvent \(#function) hi")
            }
        }
        
    }
}

extension ChatCollectionView {
    @MainActor
    func diffableOnAppearAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.onAppear(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: false)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func appendItem(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            let success: Bool = await context.coordinator.appendItems(item: self.chatList)
            
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && success && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func reloadAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.reloadWithoutAnimate(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: false)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func reloadAnimateAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.reloadWithAnimate(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func reloadItemAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.reloadItemWithoutAnimate(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func reloadItemAnimateAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.reloadItemWithAnimate(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func reconfigureAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.reconfigureWithoutAnimating(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }
    
    @MainActor
    func reconfigureAnimateAction(_ uiView: UICollectionView, context: Context, isScroll: Bool) {
        Task {
            await context.coordinator.reconfigureWithAnimating(item: self.chatList)
            if self.chatList.count > 0 && !context.coordinator.isEmpty() && isScroll {
                uiView.scrollToItem(at: IndexPath(item: self.chatList.count - 1, section: 0), at: .bottom, animated: true)
            }
            self.diffableUpdateState = .waiting
        }
    }

}
