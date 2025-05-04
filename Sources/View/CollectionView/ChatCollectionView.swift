//
//  ChatCollectionView.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

public struct ChatCollectionView<ContentView: View, ChatModel: Hashable & Identifiable>: UIViewRepresentable {
    
    @ViewBuilder let itemBuilderClosure: (ChatCoordinator<ContentView, ChatModel>.ItemBuilderClosure) -> ContentView
    
    @Binding var keyboardOption: KeyboardOption
    let inputHeight: CGFloat
    let safeAreaInsetBottom: CGFloat
    
    @Binding var inputUpdateState: InputUpdateState
    @State var previousInputHeight: CGFloat = 0
    @State var previousKeyboardHeight: CGFloat = 0
    
    private var isRefresh: (() -> Void)?
    
    @Binding var diffableUpdateState: DiffableUpdateState
    let chatList: [ChatModel]
    
    public init(
        chatList: [ChatModel],
        keyboardOption: Binding<KeyboardOption>,
        inputUpdateState: Binding<InputUpdateState>,
        diffableUpdateState: Binding<DiffableUpdateState>,
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
        
        collectionView.refreshControl = UIRefreshControl()
        context.coordinator.setDataSource(view: collectionView)
//        context.coordinator.setData(item: self.chatList)
        
        return collectionView
    }
    
    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        DispatchQueue.main.async {
            self.conditionInputUpdateState(uiView, context: context)
            self.conditionDiffableUpdateState(uiView, context: context)
        }
    }
    
    public func makeCoordinator() -> ChatCoordinator<ContentView, ChatModel> {
        return ChatCoordinator(itemBuilder: self.itemBuilderClosure,
                               isRefresh: isRefresh)
    }
    
    public func detechRefresh(isRefresh: @escaping (() -> Void)) -> ChatCollectionView {
        var view: ChatCollectionView = self
        view.isRefresh = isRefresh
        return view
    }
}

extension ChatCollectionView {
    @MainActor
    func conditionInputUpdateState(_ uiView: UICollectionView, context: Context) {
        if diffableUpdateState == .waiting {
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
}

extension ChatCollectionView {
    @MainActor
    func conditionDiffableUpdateState(_ uiView: UICollectionView, context: Context) {
        if self.inputUpdateState != .keyboard {
            switch self.diffableUpdateState {
            case .onAppear(let isScroll):
                self.diffableOnAppearAction(uiView, context: context, isScroll: isScroll)
            case .waiting:
                self.waitingAction()
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
