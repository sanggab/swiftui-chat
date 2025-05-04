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

@State private var chatList: [Hashable & Identifiable] = []
@State private var diffableUpdateState: DiffableUpdateState<Hashable & Identifiable> = .waiting
    
    var body: some View {
        ChatView(chatList: <#T##[Hashable & Identifiable]#>,
                 diffableUpdateState: <#T##Binding<DiffableUpdateState<Hashable & Identifiable>>#>,
                 itemBuilderClosure: <#T##(ChatCoordinator<View, Hashable & Identifiable>.ItemBuilderClosure) -> View#>,
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
## onAppear(isScroll: Bool)

채팅 화면을 보여주고 싶을 때 최초에 한 번 `무조건` 콜을 해야하는 옵션입니다.  
기본적으로 snapShot에는 section이 비어있기 때문에, 빈 section에 item을 추가할 경우 crash가 발생합니다.

<br>

> [!Note]
> snapShot에 데이터가 비어있을 경우에만 세팅을 하고 스크롤을 이동합니다.
> 만약 데이터가 존재 하는 데 onAppear시에는 아무 작동을 안합니다.

<br>

<a name="waiting"></a>
## waiting

모든 작동을 다 수행한 후 대기중인 상태를 의미합니다.


<br>

<a name="appendItem"></a>
## appendItem(isScroll: Bool)

채팅 데이터가 추가할 때 사용하는 옵션입니다.

<br>

> [!Note]
> 만약 추가한 채팅이 기존 채팅하고 비교할 때, 새로운 채팅 데이터가 존재하지 않으면
> 아무런 작동을 수행하지 않고 스크롤을 수행하지 않습니다.

<br>

<a name="reload"></a>
## reload(isScroll: Bool)

snapShot의 item을 다 삭제하고 현재 item들로 세팅한다음 reload를 해줍니다.


<br>

<a name="reloadAnimate"></a>
## reloadAnimate(isScroll: Bool)

snapShot의 item을 다 삭제하고 현재 item들로 세팅한다음 reload를 애니메이션과 함께 적용합니다.


<br>

<a name="reloadItem"></a>
## reloadItem(isScroll: Bool)

채팅 데이터와 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reload를 애니메이션 없이 적용합니다.

<br>

> [!Warning]
> 채팅 모델 타입이 struct일 때 변하고자 하는 Item만 reload를 진행합니다.
> class일 경우 reload 옵션이 적용됩니다.

<br>

<a name="reloadItemAnimate"></a>
## reloadItemAnimate(isScroll: Bool)

채팅 데이터와 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reload를 애니메이션과 함께 적용합니다.

<br>

> [!Warning]
> 채팅 모델 타입이 struct일 때 변하고자 하는 Item만 reload를 진행합니다.
> class일 경우 reloadAnimate 옵션이 적용됩니다.


<br>

<a name="reconfigure"></a>
## reconfigure(isScroll: Bool)

채팅 데이터와 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reconfigure을 애니메이션 없이 적용합니다.  

<br>

> [!Warning]
> 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.

<br>

<a name="reconfigureAnimate"></a>
## reconfigureAnimate(isScroll: Bool)

채팅 데이터와 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reconfigure을 애니메이션과 함께 적용합니다.

<br>

> [!Warning]
> 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.


<br>


<a name="itemBuilderClosure"></a>
## ItemBuilderClosure

채팅창에서 채팅 타입에 따라 Cell을 다르게 그려야만 합니다. 일반적으로 ForEach를 돌려서 내가 관리하고 있는 채팅 리스트의 indexPath에 맞는 데이터를 뽑아서 UI를 그립니다.  

그래서 ItemBuilderClosure도 datasource에 indexPath에 맞는 item과 날짜 구분선의 케이스를 생각해서 해당 index의 이전 item을 같이 던져줍니다.

> [!Note]
> before는 indexPath가 0,0일 경우 이전 indexPath가 존재하지 않기 때문에 옵셔널로 던져줍니다.

<br>


<a name="inputBuilderClosure"></a>
## InputBuilderClosure

채팅창에서 Input창은 빠질 수 없는 요소입니다. 하지만 Input창의 높이 변경에 따라 채팅의 scroll 포지션을 변경해주는 것은 번거롭습니다.  

그래서 InputBuilderClosure에 내가 구현하고자 하는 Input창을 구현하면, 내부적으로 Input창의 높이 변화, 입력 상태, 키보드 변화를 감지해서 알맞게 채팅의 scroll 포지션을 변경해줍니다!  

> [!Note]
> 현재 채팅의 scroll 포지션에 따라 Input이 활성화 / 비활성화시에 키보드 애니메이션이 다르게 적용될 수 있습니다.
> 그 이유는 키보드가 올라갈 떄, 현재 contentOffset.y의 값이 키보드의 높이만큼 늘어난 상태가 아닌 상태여서 그대로 스크롤 포지션을 이동할 경우, 어정쩡하게 이동하는 현상이 있습니다.
> 그래서 저런 케이스 경우에는 애니메이션을 다르게 적용할 수 밖에 없었습니다.



<br>
