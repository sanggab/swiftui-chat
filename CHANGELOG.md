#  CHANGELOG

---

## [1.5 - Fix ReadMe](https://github.com/sanggab/swiftui-chat/releases/tag/1.6) (2025-06-23)
### Fix
* ReadMe의 잘못된 부분을 수정했습니다.

---

## [1.5 - Feat Waiting Action](https://github.com/sanggab/swiftui-chat/releases/tag/1.5) (2025-06-23)
### ADD
* InputUpdateState와 DiffableUpdateState 일 때 처리하는 기능을 추가했습니다.
  * InputUpdateState 일 때 이전의 인풋창 높이와 비교해서 채팅의 스크롤을 이동시키는 기능을 추가했습니다.
  * DiffableUpdateState 일 때 diffableDataSourceSnapShot의 itemIdentifiers의 개수와 ChatModel의 개수와 비교해서 다를 경우에 snapShot을 새로 찍는 기능을 추가했습니다.

### Fix
* 인풋창 높이가 달라졌을 때 스크롤을 이동하는 기능을 처리하는 `isConditionWithDifferenceInputHeight(_ uiView:)`의 로직을 변경했습니다.

---

## [1.4 - Fix ChatModel](https://github.com/sanggab/swiftui-chat/releases/tag/1.4) (2025-06-20)
### Fix
* Generic Type인 ChatModel의 형식을 Hashable & Identifiable에서 Hashable & Identifiable & Sendable로 롤백했습니다.

---

## [1.3 - ADD & Fix](https://github.com/sanggab/swiftui-chat/releases/tag/1.3) (2025-06-20)
### ADD

* 채팅에서 빠질 수 없는 기능들을 Modifier로 만나보실 수 있습니다.  

  #### Background
  * 채팅의 backgroundColor를 변경할 수 있는 modifier를 추가했습니다.  
 
  #### DetetchRefresh
  * 채팅에서 상단 부분을 Pull해서 새로고침을 해서 채팅 데이터를 더 불러오는 로직을 위해
  * Pull하고 새로고침 Indiciator가 나오면서 사라지는 것을 감지할 수 있는 modifier를 추가했습니다.
  
  #### SetThreshold
  * 채팅의 하단에서부터 스크롤이 얼마만큼 이동했는 지의 값을 설정할 수 있는 modifier를 추가했습니다.
  * 해당 기능은 OnScrollBeyondThreshold와 연관됩니다.

  #### OnScrollBeyondThreshold와
  * 채팅의 스크롤이 threshold의 한계점을 넘었는 지 알 수 있는 modifier를 추가했습니다.
  * 해당 기능은 floatingmessage와 연결해서 사용하면 최상의 효율을 발휘합니다.
  
### Fix
* Generic Type인 ChatModel의 형식을 Hashable & Identifiable & Sendable에서 Hashable & Identifiable로 변경하였습니다.
* DiffableUpdateState의 동작 방식들을 대거 수정했습니다.

---

## [1.2 - Fix Generic Type ChatModel](https://github.com/sanggab/swiftui-chat/releases/tag/1.2) (2025-05-04)
### Fix
* Generic Type인 ChatModel의 형식을 Hashable & Identifiable에서 Hashable & Identifiable & Sendable로 변경하였습니다.

---

## [1.1 - Fix README](https://github.com/sanggab/swiftui-chat/releases/tag/1.1) (2025-05-04)
### Fix
* README 파일의 잘못된 설명을 수정했습니다.

---

## [1.0 - swiftui-Chat](https://github.com/sanggab/swiftui-chat/releases/tag/1.0) (2025-05-04)
### Release 
* SwiftUI버전 채팅 프레임워크를 소개합니다!
* 사용자의 커스텀을 극대화해서 Input창과 각 Cell을 직접 커스텀으로 구현이 가능하며, 채팅 데이터의 추가 및 Input창 높이 변화등 기타 등등 요소로 인해 채팅의 scroll 포지션 변화가 이뤄지는 것들을 쉽게 컨트롤 할 수 있습니다.

---

## [0.0 - swiftui-Chat beta](https://github.com/sanggab/swiftui-chat/releases/tag/0.0) (2025-04-06)
* 개발 시작!

