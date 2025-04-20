# swiftui-chat

### Requirements
* iOS 16.0+
* Xcode 14.0+
* Swift 5.7+


### Content
* [Documentation](#documentation)
* [ChatView](#chatview)
  * [ChatList](#chatlist)
  * [DiffableUpdateState](#diffableUpdateState)
    * [onAppear(isScroll: Bool)](#onappear)
    * [waiting](#waiting)
    * [appendItem(isScroll: Bool)](#appendItem)
    * [reload(isScroll: Bool)](#reload)
    * [reloadAnimate(isScroll: Bool)](#reloadAnimate)
    * [reloadItem(isScroll: Bool)](#reloadItem)
    * [reloadItemAnimate(isScroll: Bool)](#reloadItemAnimate)
    * [reconfigure(isScroll: Bool)](#reconfigure)
    * [reconfigureAnimate(isScroll: Bool)](#reconfigureAnimate)
  * [ItemBuilderClosure](#itemBuilderClosure)
  * [InputBuilderClosure](#inputBuilderClosure)


<a name="documentation"></a>
# Documentation

명령형 언어에서의 채팅화면은 UIKit이라는 프레임워크가 훌륭하기 떄문에 구현하기 수월했습니다. 하지만 선언형 프레임워크의 SwiftUI는 아직 UIKit보다 완성도가 떨어지기에 채팅으로서 구현은 힘들었습니다.
하지만 iOS 16부터 새로운 API들이 생기면서 UIKit으로 구현한 것 보다 성능적으로나 애니메이션적으로 부족하지는 채팅을 구현하기가 가능해졌습니다.
swiftui-chat은 SwiftUI에서 제가 이런 방식으로 채팅을 구현했구나 라고 보시는 편이 좋습니다.

<a name="chatview"></a>
# ChatView

채팅UI입니다.  
ChatView는 UICollectionView와 UICollectionViewDiffableDataSource를 활용해서 만들었습니다.  
기본적인 설명 방법은 간단합니다.

- ItemProtocol을 채택한 모델을 넣어준다.
- 채팅을 업데이트 하고 싶을 때 DiffableUpdateState를 내가 원하는 업데이트 방법으로 설정해준다.
- itemBuilderClosure에서 들어오는 ItemProtocol로 Cell을 설정헌다.
- inputBuilderClosure에 인풋창을 구현한다.

이렇게만 놓고 보면 이해하기 힘들거라고 샏각듭니다. 그래서 하나씩 자세하게 파고 들어가겠습니다.

##### Usage examples:
```swift
import GabChat

@State private var chatList: [ItemProtocol] = []
@State private var diffableUpdateState: DiffableUpdateState<ItemProtocol> = .waiting
    
    var body: some View {
        ChatView(chatList: <#T##[ItemProtocol]#>,
                 diffableUpdateState: <#T##Binding<DiffableUpdateState<ItemProtocol>>#>,
                 itemBuilderClosure: <#T##(ChatCoordinator<View, ItemProtocol>.ItemBuilderClosure) -> View#>,
                 inputBuilderClosure: <#T##() -> View#>)
    }
```

<a name="chatlist"></a>
## ChatList

채팅을 구성하는 모델을 뜻합니다.  

ChatView에서 사용자가 정의한 채팅의 Entity, VO, Model을 받는 이유는 간단합니다. ChatView 내부의 diffableDataSource의 관리를 사용자가 아닌 framework 내부적으로 관리하기 때문에 받습니다.

어떻게 내부적으로 그것을 관리하는 지 자세하게 설명해드리겠습니다.

먼저 ChatList는 ItemProtocol을 채택해야 합니다. DIffableDataSource는 ItemIdentifier가 Hashable을 준수하기 떄문에 ChatModel이 Hashable을 채택을 합니다.
그 다음에 snapShot에 reload를 하거나 reconfigure, append, delete시에 중복되는 값을 제외하는 필요성이 있기 때문에 Identifiable를 채택해야 합니다.  
마지막으로 Thread의 안정성 이유로 Sendable을 채택해야 합니다. 그래서 ItemProtocol을 채택해야 합니다.

이 ChatList가 Binding이 아닌 이유는 만약 Socket이나 Restful API를 이용해서 채팅이 추가 되거나, 삭제 시에 View는 어차피 redraw 되기 때문에 필요가 없습니다.

<a name="diffableUpdateState"></a>
## DiffableUpdateState

diffableDataSource에 어떤 방식으로 업데이트를 시킬 지 결정하는 옵션입니다.

아까 framework가 내부적으로 관리를 한다고 했는 데, 채팅의 경우 상대방이 들어온 경우에 '어 나는 상대방의 메시지가 들어올 때, 하단으로 이동해야 해', '어 나는 이동하면 안 되는 데' 이러한 많은 경우의 수가 생깁니다.
그래서 사용자는 ChatList를 업데이트 하고 나서 diffableUpdateState를 설정하면 View가 다시 redraw 되면서 설정한 업데이트 옵션에 따라 dataSource가 변경될겁니다.

차근 차근 하나씩 살펴 보도록 하겠습니다.

`DiffableUpdateState`의 파라미터들을 살펴봅시다!
기본적으로 ``isScroll`` 옵션은 채팅의 맨 하단으로 scroll을 할 지 말지 여부를 결정하는 옵션입니다.
- ``onAppear(isScroll: Bool)`` : 최초 채팅을 세팅할 때, diffableDataSource에 snapShot을 찍기 위해서 필요한 옵션입니다.
- ``waiting`` : 정지상태입니다. 아무것도 작동을 하지 않습니다.
- ``appendItem(isScroll: Bool)`` : ChatList가 추가될 때 설정하는 옵션입니다.
- ``reload(isScroll: Bool)`` : ChatList을 전체적으로 다시 reload을 하는 옵션입니다.
- ``reloadAnimate(isScroll: Bool)`` : ChatList을 전체적으로 애니메이션과 함께 reload하는 옵션입니다.
- ``reloadItem(isScroll: Bool)`` : ChatList에서 중복인 item을 제외한 나머지 item들만 reload을 하는 옵션입니다.
- ``reloadItemAnimate(isScroll: Bool)`` : ChatList에서 중복이 아닌 item들만 애니메이션과 함께 reload을 하는 옵션입니다.
- ``reconfigure(isScroll: Bool)`` : ChatList에서 중복이 아닌 item들만 reconfigure를 하는 옵션입니다.
- ``reconfigureAnimate(isScroll: Bool)`` : ChatList에서 중복이 아닌 item들만 애니메이션과 함께 reconfigure를 하는 옵션입니다.

자 이렇게 간단하게 설명했는 데 이것만 보고 파악하긴 어려우니 하나씩 자세하게 설명드리겠습니다.


<a name="onappear"></a>
### onAppear(isScroll: Bool)
