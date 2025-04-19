# swiftui-chat

### Requirements
* iOS 16.0+
* Xcode 14.0+
* Swift 5.7+


### Content
* [Documentation](#documentation)
* [ChatView](#chatview)
  * [Modifier](#modifier)
    * [Style](#style)
    * [Angle](#angle)
    * [Speed](#speed)
  * [Tip](#tip)
    * [Size](#size)
    * [Color](#color)


<a name="documentation"></a>
# Documentation

명령형 언어에서의 채팅화면은 UIKit이라는 프레임워크가 훌륭하기 떄문에 구현하기 수월했습니다. 하지만 선언형 프레임워크의 SwiftUI는 아직 UIKit보다 완성도가 떨어지기에 채팅으로서 구현은 힘들었습니다.
하지만 iOS 16부터 새로운 API들이 생기면서 UIKit으로 구현한 것 보다는 성능적으로나 애니메이션적으로 부족하지는 채팅을 구현하기가 가능해졌습니다.
swiftui-chat은 SwiftUI에서 제가 이런 방식으로 채팅을 구현했구나 라고 보시는 편이 좋습니다.

<a name="chatview"></a>
# ChatView



##### Usage examples:
```swift
import GabChat

@State private var chatList: [ItemProtocol] = []
    @State private var diffableUpdateState: DiffableUpdateState<ItemProtocol> = .waiting
    
    var body: some View {
        ChatView(chatList: chatList,
                 diffableUpdateState: $diffableUpdateState,
                 itemBuilderClosure: { (before: ItemProtocol?, current: ItemProtocol) in
            CellView()
        }) {
            InputView()
        }
    }
```

