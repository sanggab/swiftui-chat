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
    /// 작업 대기중
    case waiting
    /// 키보드 상태변화
    case keyboard
    /// 채팅입력 상태
    case textInput
}
/// ChatView의 Cell을 업데이트 시킬 때, reload을 할 것 인가, 재구성을 할 것 인가 정하는 옵션.
public enum DiffableUpdateState<ChatModel: Hashable>: Equatable {
    /// 최초 데이터 세팅 시
    ///
    /// > Note: snapShot에 데이터가 비어있을 경우에만 세팅을 하고 스크롤을 이동합니다.
    /// 만약 데이터가 존재 하는 데 onAppear시에는 아무 작동을 안합니다.
    case onAppear(Bool)
    /// 작업 대기중
    case waiting
//    case isScroll
    
    /// 채팅 추가
    ///
    /// Bool값은 ture일 경우 scrollToBottom 수행
    /// > Note: 만약 추가한 채팅이 기존 채팅하고 비교할 때, 새로운 채팅 데이터가 존재하지 않으면
    /// 아무런 작동을 수행하지 않고 스크롤을 수행하지 않습니다.
    case appendItem(Bool)
    /// CollectionView 전체 reload
    case reload(Bool)
    /// CollectionView 전체 reload
    case reloadAnimate(Bool)
    /// Cell Item 리로드
    ///
    /// Cell reload 시 애니메이션을 적용 안 한다
    case reloadItem(Bool)
    /// cell Item 리로드
    ///
    /// Cell reload 시 애니메이션을 적용시킨다
    case reloadItemAnimate(Bool)
    /// Cell 재구성
    ///
    /// Cell 재구성 시 애니메이션을 적용 안 한다.
    /// Bool값은 true일 경우 scrollToBottom 수행
    case reconfigure(Bool)
    /// Cell 재구성
    ///
    /// Cell 재구성 시 애니메이션을 적용시킨다
    /// Bool값은 true일 경우 scrollToBottom 수행
    case reconfigureAnimate(Bool)
    
    case hi(ChatModel)
}
