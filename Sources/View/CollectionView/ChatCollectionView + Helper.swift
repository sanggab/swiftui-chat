//
//  ChatCollectionView + Helper.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI
// MARK: - Condition Top
extension ChatCollectionView {
    /// 현재 위치가 상단인지 확인하는 기능
    func isTop(_ uiView: UICollectionView) -> Bool {
        let offsetY: CGFloat = uiView.contentOffset.y
        
        return offsetY == .zero
    }
    /// 리스트가 frame보다 더 큰지 체크하는 기능
    ///
    /// contentSize.height가 frame.height보다 큰지 체크합니다
    ///
    /// - returns:
    ///     - true: 리스트 크기가 더 큽니다.
    ///     - false: 리스트 크기가 더 작습니다.
    func isContentBiggerThanFrame(_ uiView: UICollectionView) ->  Bool {
        let viewHeight: CGFloat = uiView.frame.height
        let contentHeight: CGFloat = uiView.contentSize.height
        
        return viewHeight < contentHeight
    }
    
    /// 현재 스크롤이 상단 근처인지 체크하는 기능
    ///
    /// uicollectionview.contentOffset.y의 값이 키보드 높이를 고려해서 최상단인지 알려줍니다.
    ///
    /// - Note : keyboard가 올라올 때, 최상단 근처인 경우랑, 최하단인 경우에 애니메이션을 다르게 가져가기 때문에 필요합니다.
    func isNearTop(_ uiView: UICollectionView) -> Bool {
        let viewHeight: CGFloat = uiView.frame.height
        let contentHeight: CGFloat = uiView.contentSize.height
        let offsetY: CGFloat = uiView.contentOffset.y
        let keyboardHeight: CGFloat = self.keyboardOption.size.height
        let intriHeight: CGFloat = viewHeight + keyboardHeight - self.safeAreaInsetBottom
        
        return !(intriHeight < contentHeight && (keyboardHeight - self.safeAreaInsetBottom) <= offsetY)
    }
}
// MARK: - Condition Bottom
extension ChatCollectionView {
    /// 현재 위치가 바닥인지 확인하는 기능
    func isBottom(_ uiView: UICollectionView) -> Bool {
        let viewHeight: Int = Int(uiView.frame.height)
        let contentHeight: Int = Int(uiView.contentSize.height)
        let offsetY: Int = Int(uiView.contentOffset.y)
        return offsetY == (contentHeight - viewHeight)
    }
    
    func isBottomToOffset(_ uiView: UICollectionView, offset: CGFloat) -> Bool {
        
        return false
    }
    /// 현재 스크롤이 하단 근처인지 체크하는 기능
    ///
    /// uiCollectionView.contentOffset.y의 값이 키보드 높이를 고려해서 최하단인지 알려줍니다.
    func isNearBottom(_ uiView: UICollectionView) -> Bool {
        let viewHeight: CGFloat = uiView.frame.height
        let contentHeight: CGFloat = uiView.contentSize.height
        
        let moveOffsetY: CGFloat = self.computeMoveOffsetY(uiView)
        
        return moveOffsetY > contentHeight - viewHeight
    }
    /// 현재 스크롤이 하단 근처인지 체크하는 기능
    ///
    /// uiCollectionView.contentOffset.y의 값이 키보드 높이를 고려해서 최하단인지 알려줍니다.
    func isNearBottom(_ uiView: UICollectionView, offsetY: CGFloat) -> Bool {
        let viewHeight: CGFloat = uiView.frame.height
        let contentHeight: CGFloat = uiView.contentSize.height
        
        return offsetY > contentHeight - viewHeight
    }
}

extension ChatCollectionView {
    func computeMoveOffsetY(_ uiView: UICollectionView) -> CGFloat {
        let viewHeight: CGFloat = uiView.frame.height
        let contentHeight: CGFloat = uiView.contentSize.height
        let offsetY: CGFloat = uiView.contentOffset.y
        let keyboardHeight: CGFloat = self.keyboardOption.size.height
        var moveOffsetY: CGFloat = .zero
        
        if self.keyboardOption.state.isShowing {
            if self.isContentBiggerThanFrame(uiView) {
                moveOffsetY = offsetY + (keyboardHeight - self.safeAreaInsetBottom)
            } else {
                // item의 높이가 collectionView을 채우지 못 한 경우
                moveOffsetY = abs(offsetY + (viewHeight - contentHeight - keyboardHeight + self.safeAreaInsetBottom))
            }
        } else {
            if !isNearTop(uiView) {
                // item의 실제 높이가 collectionView의 실제 높이보다 크면서, contentOffset.y의 값이 keyboard의 높이보다 크거나 같은 경우에, y의 값을 바꿔준다.
                moveOffsetY = offsetY - (keyboardHeight - self.safeAreaInsetBottom)
            }
        }
        
        return moveOffsetY
    }
}
// MARK: - textInput State Helper
extension ChatCollectionView {
    /// 키보드 높이가 변경됐는지 알려주는 기능
    func isDifferenceKeyboardHeight() -> Bool {
        return self.previousKeyboardHeight != self.keyboardOption.size.height && self.previousKeyboardHeight != .zero
    }
    /// 인풋창 높이가 변경됐는지 알려주는 기능
    func isDifferenceInputHeight() -> Bool {
        return self.previousInputHeight != self.inputHeight && self.previousInputHeight != .zero
    }
}
