//
//  ChatCollectionView + Animation.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

extension ChatCollectionView {
    /// setContentOffset 애니메이션 기능
    func executeSetContentOffset(_ uiView: UICollectionView, offset: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + self.keyboardOption.duration) {
            uiView.setContentOffset(CGPoint(x: 0, y: offset), animated: true)
            uiView.layoutIfNeeded()
        }
    }
    /// UIViewPropertyAnimator 기능
    func executeAnimator(_ uiView: UICollectionView, offsetY: CGFloat) {
        let curve = UIView.AnimationCurve(rawValue: self.keyboardOption.curve)!
        let animtor = UIViewPropertyAnimator(duration: self.keyboardOption.duration, curve: curve)

        animtor.addAnimations {
            uiView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)

            uiView.layoutIfNeeded()
        }

        animtor.startAnimation()
    }
    /// 키보드 내릴 시 애니메이터
    ///
    /// 키보드 내릴 때 애니메이션을 부여할 경우 맨 하단 Cell이 flickering이 발생하는 문제가 생김
    /// 이것을 해결하기 위해 여러가지 방법을 테스트 해봄
    /// 1. cell에 id 부여 -> 실패
    /// 2. animator를 각종 다른 animation으로 변경 -> 실패
    /// 3. state 변화를 애니메이션 끝나고 실행 -> 실패
    /// 4. setContentOffset animated true로 부여 -> flickering은 제거됬으나 특정 좌표에서 offsetY대로 움직이지 않는 현상 발견 ex) 773으로 세팅했는데 655로 가버림
    /// 각종 방법들로 실행한 결과 다 안되서 임시로 애니메이션 제거
    @MainActor
    func keyboardHideAnimator(_ uiView: UICollectionView, offsetY: CGFloat) {
        uiView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
    }
}
