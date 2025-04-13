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
    func waitingAction() {
//        if self.keyboardOption.state != .none {
//            DispatchQueue.main.async {
//                self.inputUpdateState = .keyboard
//            }
//        }
    }
}
// MARK: - textInput
extension ChatCollectionView {
    /// textInput State일 떄 처리하는 기능 모음
    @MainActor
    func textInputAction(_ uiView: UICollectionView) {
        if self.keyboardOption.state == .willHide || self.keyboardOption.state == .didHide {
            self.inputUpdateState = .keyboard
//            DispatchQueue.main.async {
//                self.inputUpdateState = .keyboard
//            }
        }
        
        let keyboardCondition: Bool = self.isDifferenceKeyboardHeight()
        let inputHeightCondition: Bool = self.isDifferenceInputHeight()
        
        switch (keyboardCondition, inputHeightCondition) {
        case (true, false):
            self.isConditionWithDifferenceKeyboardHeight(uiView)
        case (false, true):
            self.isConditionWithDifferenceInputHeight(uiView)
        case (true, true):
            print("존재할 수 있나 모르겠네..")
        case (false, false):
            print("아무 처리 안한다")
        }
        
        self.previousKeyboardHeight = self.keyboardOption.size.height
        self.previousInputHeight = self.inputHeight
//        DispatchQueue.main.async {
//            self.previousKeyboardHeight = self.keyboardOption.size.height
//            self.previousInputHeight = self.inputHeight
//        }
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
        let currentOffsetY: CGFloat = uiView.contentOffset.y
        let differenceHeight: CGFloat = self.inputHeight - self.previousInputHeight
        
        if currentOffsetY + differenceHeight >= 0 {
            self.executeAnimator(uiView, offsetY: uiView.contentOffset.y + differenceHeight)
        }
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
            print("didShow")
        case .didHide:
            print("didHide")
        case .none:
            print("아무 처리 안함")
            print("상갑 logEvent \(#function) frame: \(uiView.frame)")
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
        self.keyboardOption.state = .none
//        DispatchQueue.main.async {
//            self.inputUpdateState = .textInput
//            self.keyboardOption.state = .none
//        }
    }
    
    /// Keyboard가 내려갈 때 처리를 하는 method
    ///
    /// Keyboard가 내려갈 때, UICollectionView의 contentOffset.y을 조절해줍니다
    @MainActor
    private func isConditionWithKeyboardHide(_ uiView: UICollectionView) {
        let moveOffsetY: CGFloat = self.computeMoveOffsetY(uiView)
        
        self.keyboardHideAnimator(uiView, offsetY: moveOffsetY)
        
        self.inputUpdateState = .waiting
        self.keyboardOption.state = .none
    }
}
