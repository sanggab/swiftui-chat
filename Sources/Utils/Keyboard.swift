//
//  Keyboard.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import Foundation
import SwiftUI
import Combine

/// Keyboard의 옵션
///
/// ``KeyboardModifier``의 각종 modifier들의 Return 값
///
/// - Parameters:
///     - size: 키보드 사이즈 (CGSize)
///     - curve: 키보드 애니메이션 곡선 (Int)
///     - duration: 키보드 애니메이션 시간 (TimeInterval)
///     - state: 키보드 상태 값 (``KeyboardState``)
///
///  - Note: ``KeyboardOption/default``는 빈 값입니다.
public struct KeyboardOption: Hashable {
    public let size: CGSize
    public let curve: Int
    public let duration: TimeInterval
    public var state: KeyboardState
    
    @MainActor public static let `default`: KeyboardOption = .init(size: .zero,
                                                        curve: .zero,
                                                        duration: .zero,
                                                        state: .none)
    
    public init(size: CGSize,
                curve: Int,
                duration: TimeInterval,
                state: KeyboardState = .none) {
        self.size = size
        self.curve = curve
        self.duration = duration
        self.state = state
    }
}

extension KeyboardOption {
    /// Keyboard의 Animation을 만드는 기능입니다.
    ///
    /// ``KeyboardOption/curve`` 와 ``KeyboardOption/duration``을 이용해서 Animation을 만듭니다.
    ///
    /// - returns: Animation
    public func makingCurveAnimation() -> Animation {
        let uikitCurve: UIView.AnimationCurve! = .init(rawValue: curve)
        
        let timing = UICubicTimingParameters(animationCurve: uikitCurve)
        
        let curveAnimation: Animation = .timingCurve(Double(timing.controlPoint1.x),
                                             Double(timing.controlPoint1.x),
                                             Double(timing.controlPoint1.x),
                                             Double(timing.controlPoint1.x),
                                             duration: duration)
        
        return curveAnimation
    }
}

/// Keyboard의 State 값
///
/// - Parameters:
///     - none: 상태가 변한 후의 값 - default
///     - willShow: KeyboardWillShow
///     - willHide: KeyboardWillHide
///     - didShow: KeyboardDidShow
///     - didHide: KeyboardDidHide
@frozen
public enum KeyboardState: Hashable {
    case none
    
    case willShow
    case willHide
    
    case didShow
    case didHide
}

public extension KeyboardState {
    /// 키보드가 보여질려고 하거나 키보드가 보여지는 여부를 확인하는 값
    ///
    /// - returns: Bool
    var isShowing: Bool {
        switch self {
        case .willShow, .didShow:
            return true
        default:
            return false
        }
    }
}

/// Keyboard Modifier
///
/// Keyboard의 willShow, didShow, willHide, didHide의 변화에 따라 ``KeyboardOption`` 으로 키보드의 데이터를 알려주는 modifier
public struct KeyboardModifier: ViewModifier {
    private let keyboardWillShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        .compactMap(\.userInfo)
    
    private let keyboardDidShow = NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
        .compactMap(\.userInfo)
    
    private let keyboardWillHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        .compactMap(\.userInfo)
    
    private let keyboardDidHide = NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
        .compactMap(\.userInfo)
    
    private let willShow: ((KeyboardOption) -> Void)?
    private let willHide: ((KeyboardOption) -> Void)?
    private let didShow: ((KeyboardOption) -> Void)?
    private let didHide: ((KeyboardOption) -> Void)?
    
    public init(willShow: ((KeyboardOption) -> Void)? = nil,
         willHide: ((KeyboardOption) -> Void)? = nil,
         didShow: ((KeyboardOption) -> Void)? = nil,
         didHide: ((KeyboardOption) -> Void)? = nil) {
        self.willShow = willShow
        self.willHide = willHide
        self.didShow = didShow
        self.didHide = didHide
    }
    
    public func body(content: Content) -> some View {
        content
            .onReceive(keyboardWillShow) { userInfo in
                let size: CGSize = (userInfo["UIKeyboardFrameEndUserInfoKey"] as? CGRect)?.size ?? .zero
                let curve: Int = (userInfo["UIKeyboardAnimationCurveUserInfoKey"] as? Int) ?? .zero
                let duration: TimeInterval = (userInfo["UIKeyboardAnimationDurationUserInfoKey"] as? TimeInterval) ?? .zero
                
                let keyboardOption: KeyboardOption = self.makeKeyboardOption(size: size,
                                                                             curve: curve,
                                                                             duration: duration,
                                                                             state: .willShow)
                
                self.willShow?(keyboardOption)
            }
            .onReceive(keyboardDidShow) { userInfo in
                let size: CGSize = (userInfo["UIKeyboardFrameEndUserInfoKey"] as? CGRect)?.size ?? .zero
                let curve: Int = (userInfo["UIKeyboardAnimationCurveUserInfoKey"] as? Int) ?? .zero
                let duration: TimeInterval = (userInfo["UIKeyboardAnimationDurationUserInfoKey"] as? TimeInterval) ?? .zero
                
                let keyboardOption: KeyboardOption = self.makeKeyboardOption(size: size,
                                                                             curve: curve,
                                                                             duration: duration,
                                                                             state: .didShow)
                
                self.didShow?(keyboardOption)
            }
            .onReceive(keyboardWillHide) { userInfo in
                let size: CGSize = (userInfo["UIKeyboardFrameEndUserInfoKey"] as? CGRect)?.size ?? .zero
                
                let curve: Int = (userInfo["UIKeyboardAnimationCurveUserInfoKey"] as? Int) ?? .zero
                let duration: TimeInterval = (userInfo["UIKeyboardAnimationDurationUserInfoKey"] as? TimeInterval) ?? .zero
                
                let keyboardOption: KeyboardOption = self.makeKeyboardOption(size: size,
                                                                             curve: curve,
                                                                             duration: duration,
                                                                             state: .willHide)
                
                self.willHide?(keyboardOption)
            }
            .onReceive(keyboardDidHide) { userInfo in
                let size: CGSize = (userInfo["UIKeyboardFrameEndUserInfoKey"] as? CGRect)?.size ?? .zero
                
                let curve: Int = (userInfo["UIKeyboardAnimationCurveUserInfoKey"] as? Int) ?? .zero
                let duration: TimeInterval = (userInfo["UIKeyboardAnimationDurationUserInfoKey"] as? TimeInterval) ?? .zero
                
                let keyboardOption: KeyboardOption = self.makeKeyboardOption(size: size,
                                                                             curve: curve,
                                                                             duration: duration,
                                                                             state: .didHide)
                
                self.didHide?(keyboardOption)
            }
    }
    
    
    private func makeKeyboardOption(size keyboardSize: CGSize,
                                    curve animationCurve: Int,
                                    duration keyboardAnimationDuration: TimeInterval,
                                    state: KeyboardState = .none) -> KeyboardOption {
        return KeyboardOption(size: keyboardSize,
                              curve: animationCurve,
                              duration: keyboardAnimationDuration,
                              state: state)
    }
}

public extension View {
    /// Keyboard가 willShow일 때, ``KeyboardOption``을 던져줍니다.
    func keyboardWillShow(willShow: ((KeyboardOption) -> Void)? = nil) -> some View {
        modifier(KeyboardModifier(willShow: willShow))
    }
    /// Keyboard가 willHide일 때, ``KeyboardOption``을 던져줍니다.
    func keyboardWillHide(willHide: ((KeyboardOption) -> Void)? = nil) -> some View {
        modifier(KeyboardModifier(willHide: willHide))
    }
    /// Keyboard가 didShow일 때, ``KeyboardOption``을 던져줍니다.
    func keyboardDidShow(didShow: ((KeyboardOption) -> Void)? = nil) -> some View {
        modifier(KeyboardModifier(didShow: didShow))
    }
    /// Keyboard가 didHide일 때, ``KeyboardOption``을 던져줍니다.
    func keyboardDidHide(didHide: ((KeyboardOption) -> Void)? = nil) -> some View {
        modifier(KeyboardModifier(didHide: didHide))
    }
}
