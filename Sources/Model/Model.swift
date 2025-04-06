//
//  Model.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import Foundation

enum MockSection: Int {
    case main
}
/// ChatCollectionView에서 내부적으로 keyboard와 textView의 입력시의 상태에 따른 offset값 조정을 위한 State
enum InputUpdateState: Equatable {
    /// 최초 세팅 시
//    case onAppear
    /// 작업 대기중
    case waiting
    /// 키보드 상태변화
    case keyboard
    /// 채팅입력 상태
    case textInput
}
/// ChatView의 Cell을 업데이트 시킬 때, reload을 할 것 인가, 재구성을 할 것 인가 정하는 옵션.
public enum DiffableUpdateState: Equatable {
    /// 작업 대기중
    case waiting
    /// Cell 리로드
    case reload
    /// Cell 재구성
    ///
    /// Bool값은 true일 경우
    case reconfigure(Bool)
}
