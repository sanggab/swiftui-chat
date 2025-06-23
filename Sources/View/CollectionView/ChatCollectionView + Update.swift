//
//  ChatCollectionView + Update.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

// MARK: - onAppear
extension ChatCollectionView {
    @available(*, deprecated, message: "잠정 폐지")
    /// onAppear State일 때 처리하는 기능 모음
    func onAppearAction(_ uiView: UICollectionView, context: Context) {
//        let size: CGSize = uiView.frame.size
//        let contentSize: CGSize = uiView.contentSize
//
//        if size.height != .zero && contentSize.height != .zero && self.inputUpdateState == .onAppear {
//            DispatchQueue.main.async {
//                self.inputUpdateState = .waiting
//            }
//        }
    }
}
// MARK: - waiting
extension ChatCollectionView {
    /// waiting State일 때 처리하는 기능 모음
    func inputWaitingAction(_ uiView: UICollectionView) {
        let inputHeightCondition: Bool = self.isDifferenceInputHeight()
        if inputHeightCondition {
            self.isConditionWithDifferenceInputHeight(uiView)
        }
        
        self.previousKeyboardHeight = self.keyboardOption.size.height
        self.previousInputHeight = self.inputHeight
    }
    
    func diffableWaitingAction(_ uiView: UICollectionView, context: Context) {
        if context.coordinator.getSnapShotItemCount() != self.chatList.count {
            self.reconfigureAction(uiView, context: context, isScroll: true)
        }
    }
}
// MARK: - textInput
extension ChatCollectionView {
    /// textInput State일 떄 처리하는 기능 모음
    @MainActor
    func textInputAction(_ uiView: UICollectionView) {
        if self.keyboardOption.state == .willHide || self.keyboardOption.state == .didHide {
            self.inputUpdateState = .keyboard
        }
        
        let keyboardCondition: Bool = self.isDifferenceKeyboardHeight()
        let inputHeightCondition: Bool = self.isDifferenceInputHeight()
        
        switch (keyboardCondition, inputHeightCondition) {
        case (true, false):
            self.isConditionWithDifferenceKeyboardHeight(uiView)
        case (false, true):
            self.isConditionWithDifferenceInputHeight(uiView)
        case (true, true):
            break
        case (false, false):
            break
        }
        
        self.previousKeyboardHeight = self.keyboardOption.size.height
        self.previousInputHeight = self.inputHeight
        self.previousInputUpdateState = self.inputUpdateState
    }
    /// 키보드 높이가 달라졌을 때 처리하는 기능
    @MainActor
    func isConditionWithDifferenceKeyboardHeight(_ uiView: UICollectionView) {
        let currentOffsetY: CGFloat = uiView.contentOffset.y
        let viewHeight: CGFloat = uiView.frame.height
        let contentHeight: CGFloat = uiView.contentSize.height
        let maxOffsetY: CGFloat = contentHeight - viewHeight
        let differenceHeight: CGFloat = self.keyboardOption.size.height - self.previousKeyboardHeight
        
        // 현재 offsetY에서 키보드 차이만큼 더 하고 나온 값이, 현재 offsetY를 오버하거나
        // 현재 offsetY에서 키보드 차이만큼 뺀 값이 0보다 작을 경우에 애니메이션 다르게 가져간다.
        if currentOffsetY + differenceHeight > maxOffsetY || currentOffsetY - differenceHeight < 0 {
            self.executeSetContentOffset(uiView, offset: uiView.contentOffset.y + differenceHeight)
        } else {
            self.executeAnimator(uiView, offsetY: uiView.contentOffset.y + differenceHeight)
        }
    }
    /// 인풋창 높이가 달라졌을 때 처리하는 기능
    @MainActor
    func isConditionWithDifferenceInputHeight(_ uiView: UICollectionView) {
        guard isContentBiggerThanFrame(uiView) else { return }

        let viewHeight = uiView.frame.height
        let contentHeight = uiView.contentSize.height
        let currentOffsetY = uiView.contentOffset.y
        let differenceHeight = self.inputHeight - self.previousInputHeight
        
        // MARK: 최상단일 경우
        if currentOffsetY <= 0 {
            // 최상단이므로 위로 올릴 필요 없음
            return
        }

        // MARK: 최하단일 경우
        let isAtBottom = currentOffsetY + viewHeight >= contentHeight - 1.0
        if isAtBottom {
            // 키보드가 올라가면 자동으로 따라가게끔 유지
            scrollToBottom(uiView)
            return
        }

        // MARK: 중간일 경우 → 자연스럽게 offset 조정
        let newOffsetY = currentOffsetY + differenceHeight
        let clampedOffsetY = max(0, min(newOffsetY, contentHeight - viewHeight))
        self.executeAnimator(uiView, offsetY: clampedOffsetY)
    }
    
    func scrollToBottom(_ uiView: UICollectionView, animated: Bool = true) {
        let contentHeight = uiView.contentSize.height
        let viewHeight = uiView.bounds.size.height
        let bottomOffset = CGPoint(x: 0, y: max(0, contentHeight - viewHeight))
        uiView.setContentOffset(bottomOffset, animated: animated)
    }
}
// MARK: - keyboard
extension ChatCollectionView {
    /// Keyboard의 상태 변화에 따른 UICollectionView contentOffset 조절하는 기능
    @MainActor
    func controlOffsetWithKeyboard(_ uiView: UICollectionView) {
        switch self.keyboardOption.state {
        case .willShow:
            self.isConditionWithKeyboardShow(uiView)
        case .willHide:
            self.isConditionWithKeyboardHide(uiView)
        case .didShow:
            break
        case .didHide:
            break
        case .none:
            break
        }
    }
    /// Keyboard가 올라올 때 처리를 하는 method
    ///
    /// Keyboard가 올라올 때, UICollectionView의 contentOffset.y을 조절해줍니다
    ///
    /// - Note: UICollectionView의 contentOffset.y의 위치에 따라 애니메이션이 다를 수 있습니다.
    @MainActor
    private func isConditionWithKeyboardShow(_ uiView: UICollectionView) {
        let moveOffsetY: CGFloat = self.computeMoveOffsetY(uiView)
        
        // 키보드가 올라올 때, contentOffset.y의 값이 키보드의 높이만큼 안 떨어져 있을 경우에, 키보드가 올라올 경우, 예를 들어 현재 y값이 784인데 높이가 312인 키보드가 올라올 경우, 1096이 맨 아래의 좌표값인데 키보드 애니메이션 도중에 y의 값이1096까지 확장이 안 된 상태에서 1096으로 setContentOffset을 해버릴 경우, 도중에 스크롤이 멈추는 형상이 있어서 애니메이션을 다르게 가져갑니다.
        self.isNearBottom(uiView) ? self.executeSetContentOffset(uiView, offset: moveOffsetY) : self.executeAnimator(uiView, offsetY: moveOffsetY)
        
        self.inputUpdateState = .textInput
        self.previousInputUpdateState = self.inputUpdateState
        self.keyboardOption.state = .none
    }
    
    /// Keyboard가 내려갈 때 처리를 하는 method
    ///
    /// Keyboard가 내려갈 때, UICollectionView의 contentOffset.y을 조절해줍니다
    @MainActor
    private func isConditionWithKeyboardHide(_ uiView: UICollectionView) {
        let moveOffsetY: CGFloat = self.computeMoveOffsetY(uiView)
        
        self.keyboardHideAnimator(uiView, offsetY: moveOffsetY)
        
        self.inputUpdateState = .waiting
        self.previousInputUpdateState = self.inputUpdateState
        self.keyboardOption.state = .none
    }
}
