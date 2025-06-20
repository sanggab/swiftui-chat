//
//  ChatCoordinator.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

/// ChatCoordinator
///
/// UICollectionView와 관련된 요소(ex: delegate)를 처리하는 class
public final class ChatCoordinator<ContentView: View, ChatModel: Hashable & Identifiable & Sendable>: NSObject, UICollectionViewDelegate {
    
    public typealias ItemBuilderClosure = (before: ChatModel?, current: ChatModel, after: ChatModel?)
    
    private var itemBuilder: (ItemBuilderClosure) -> ContentView
    
    private var isRefresh: (() -> Void)?
    private var onScrollBeyondThreshold: ((Bool) -> Void)?
    private var onEndEditing: (() -> Void)?
    
    private var dataSource: UICollectionViewDiffableDataSource<MockSection, ChatModel.ID>!
    
    private var isKeyboardInteracting = false
    private var lastOffsetFromBottom: CGFloat = 0
    private let threshold: CGFloat
    
    private let isClassType: Bool
    @Binding var chatList: [ChatModel]
    
    public init(itemBuilder: @escaping (ItemBuilderClosure) -> ContentView,
                isRefresh: (() -> Void)?,
                onScrollBeyondThreshold: ((Bool) -> Void)?,
                onEndEditing: (() -> Void)? = nil,
                chatList: Binding<[ChatModel]>,
                threshold: CGFloat = 100) {
        self.itemBuilder = itemBuilder
        self.isRefresh = isRefresh
        self.onScrollBeyondThreshold = onScrollBeyondThreshold
        self.onEndEditing = onEndEditing
        self._chatList = chatList
        self.isClassType = ChatModel.self is AnyObject.Type
        self.threshold = threshold
    }
    
    public func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, environment in
            let widthDimensions: NSCollectionLayoutDimension = .fractionalWidth(1.0)
            let heightDimension: NSCollectionLayoutDimension = .estimated(1.0)
            
            let itemLayoutSize: NSCollectionLayoutSize = .init(widthDimension: widthDimensions,
                                                               heightDimension: heightDimension)
            
            let item: NSCollectionLayoutItem = .init(layoutSize: itemLayoutSize)
            
            let groupLayoutSize: NSCollectionLayoutSize = .init(widthDimension: widthDimensions,
                                                                heightDimension: heightDimension)
            
            let group: NSCollectionLayoutGroup = .vertical(layoutSize: groupLayoutSize,
                                                           subitems: [item])
            
            let section: NSCollectionLayoutSection = NSCollectionLayoutSection(group: group)
            
            return section
        }
    }
    
    @objc func handleTap() {
        onEndEditing?()
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    @MainActor
    public func setDataSource(view: UICollectionView) {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatKeyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatKeyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatKeyboardDidHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chatKeyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        self.dataSource = UICollectionViewDiffableDataSource<MockSection, ChatModel.ID>(collectionView: view, cellProvider: { [weak self] collectionView, indexPath, id in
            guard let self else { return UICollectionViewCell() }
            
            let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "chatcell", for: indexPath)
            
            if self.chatList.count > indexPath.item {
                cell.contentConfiguration = nil
                
                let beforeListModel: ChatModel? = self.beforeListModel(in: indexPath)
                let currentListModel: ChatModel = self.chatList[indexPath.item]
                let afterListModel: ChatModel? = self.afterListModel(in: indexPath)
                
                cell.contentConfiguration = UIHostingConfiguration {
                    self.itemBuilder((beforeListModel, currentListModel, afterListModel))
                }
                .minSize(width: 0, height: 0)
                .margins(.all, 0)
                
                return cell
            } else {
                cell.contentConfiguration = UIHostingConfiguration {
                    EmptyView()
                }
                .minSize(width: 0, height: 0)
                .margins(.all, 0)
                
                return cell
            }
        })
    }
    
    @MainActor
    private func beforeListModel(in index: IndexPath) -> ChatModel? {
        return self.chatList[safe: index.item - 1]
    }
    
    @MainActor
    private func afterListModel(in index: IndexPath) -> ChatModel? {
        return self.chatList[safe: index.item + 1]
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isKeyboardInteracting else {
            return
        }
        
        let offsetFromBottom = scrollView.contentSize.height - scrollView.contentOffset.y - scrollView.bounds.height

        let isAboveThreshold = offsetFromBottom > threshold

        // 상태가 변경됐을 때만 클로저 호출
        if isAboveThreshold != (lastOffsetFromBottom > threshold) {
            onScrollBeyondThreshold?(isAboveThreshold)
        }

        lastOffsetFromBottom = offsetFromBottom
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let isRefreshing = scrollView.refreshControl?.isRefreshing, isRefreshing {
            self.isRefresh?()
            scrollView.refreshControl?.endRefreshing()
        }
    }

    @objc
    private func chatKeyboardWillShow(_ notification: Notification) {
        isKeyboardInteracting = true
    }

    @objc
    private func chatKeyboardWillHide(_ notification: Notification) {
        isKeyboardInteracting = true
    }
    
    @objc
    private func chatKeyboardDidShow(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isKeyboardInteracting = false
        }
    }

    @objc
    private func chatKeyboardDidHide(_ notification: Notification) {
        isKeyboardInteracting = false
    }
}

// MARK: DiffableUpdateState - onAppear
extension ChatCoordinator {
    @MainActor
    public func onAppear(item: [ChatModel]) async {
        if self.dataSource.snapshot().itemIdentifiers.count == 0 {
            await self.asyncSetData(item: item)
            print("상갑 logEvent \(#function) self.dataSource.snapshot().itemIdentifiers.count: \(self.dataSource.snapshot().itemIdentifiers.count)")
            if self.dataSource.snapshot().itemIdentifiers.count != item.count {
                await self.onAppear(item: item)
            }
        }
    }
    
    @MainActor
    public func asyncSetData(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = .init()
        
        snapShot.appendSections([.main])
        
        let itemList = item.map { $0.id }
        
        snapShot.appendItems(itemList, toSection: .main)
        
        await self.dataSource.apply(consume snapShot)
    }
}

// MARK: DiffableUpdateState - appendItem
extension ChatCoordinator {
    /// snapShot에 Cell 추가
    ///
    /// snapShot에 item을 추가하고 apply 시킨다.
    @MainActor
    public func appendItem(item: consuming ChatModel) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
        
        snapShot.appendItems([item.id])
        await self.dataSource.apply(snapShot)
    }
    /// snapShot에 Cell 추가
    ///
    /// 현재 snapShot의 item하고 파라미터의 item하고 비교해서 중복이 아닌 item들을 뽑아내서 item이 비어있지 않으면 apply 시켜준다
    ///
    /// - returns: snapShot에 item 추가가 성공하면 true / 실패하면 false를 반환
    ///
    /// > Note: ``appendItem(item:)`` 하고 다르게 현재 snapShot의 item들과 비교해서 중복이 아닌 데이터들을 따로 뽑아내 추가합니다.
    @MainActor
    public func appendItems(item: [ChatModel]) async -> Bool {
        if !isClassType {
            return await appendItemsApply(item)
        } else {
            let snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            await self.dataSource.apply(snapShot, animatingDifferences: false)
        }
        
        return false
    }
    
    func appendItemsApply(_ item: [ChatModel]) async -> Bool {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            
            guard isDifferenceItem(from: snapShot.itemIdentifiers, to: newItem) else {
                continuation.resume(returning: false)
                return
            }
            
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: false) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reconfigureItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: false)
                continuation.resume(returning: true)
            }
        }
    }
    
    func isDifferenceItem(from baseModels: consuming [ChatModel.ID], to filterModels: consuming [ChatModel.ID]) -> Bool {
        let item: [ChatModel.ID] = filterModels.filter({ id in !baseModels.contains(id) })
        return !item.isEmpty
    }
    
    /// 두 파라미터를 비교해서 중복을 데이터를 데이터를 던져준다
    ///
    /// newItem에 filter을 돌려서 oldItem의 리스트에서 포함되지 않는 item들을 뽑아서 반환해준다.
    ///
    /// - returns: oldItem에 포함되지 않은 item들을 반환 - [ChatModel]
    public func removeDuplicates(oldItem: consuming [ChatModel.ID], newItem: consuming [ChatModel.ID]) -> [ChatModel.ID] {
        return newItem.compactMap { id in
            if !oldItem.contains(where: { $0 == id }) {
                return id
            } else {
                return nil
            }
        }
    }
}

extension ChatCoordinator {
    @MainActor
    public func deleteItems(item: [ChatModel]) async -> Bool {
        let snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
        
        if !isClassType {
            return await deleteItemsApply(item)
        } else {
            await self.dataSource.apply(snapShot, animatingDifferences: false)
        }
        
        return false
    }
    
    func deleteItemsApply(_ item: [ChatModel]) async -> Bool {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: false) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reconfigureItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: false)
                continuation.resume(returning: true)
            }
        }
    }
}

extension ChatCoordinator {
    /// UICollectionView을 전체 reload 합니다.
    ///
    /// 현재 snapShot에 있는 items들을 모두 삭제하고 새 item들을 추가한 다음 애니메이션 없이 reload를 합니다.
    public func reloadWithoutAnimate(item: [ChatModel]) async {
        return await reloadWithoutAnimateApply(item)
    }
    private func reloadWithoutAnimateApply(_ item: [ChatModel]) async {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: false) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reloadItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: false)
                continuation.resume()
            }
        }
    }
    /// UICollectionView을 전체 reload 합니다.
    ///
    /// 현재 snapShot에 있는 items들을 모두 삭제하고 새 item들을 추가한 다음 애니메이션 있이 reload를 합니다.
    public func reloadWithAnimate(item: [ChatModel]) async {
        return await reloadWithAnimateApply(item)
    }
    
    private func reloadWithAnimateApply(_ item: [ChatModel]) async {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: true) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reloadItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: true)
                continuation.resume()
            }
        }
    }
    /// snapShot의 Cell을 애니메이션 없이 reload
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서  데이터가 달라진 item을 찾아 해당 Cell만 reloadItems을 애니메이션 없이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    public func reloadItemWithoutAnimate(item: [ChatModel]) async {
        if !isClassType {
            return await reloadItemWithoutAnimateApply(item)
        } else {
            let snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    
    private func reloadItemWithoutAnimateApply(_ item: [ChatModel]) async {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: false) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reloadItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: false)
                continuation.resume()
            }
        }
    }
    /// snapShot의 Cell을 애니메이션 있이 reload
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서  데이터가 달라진 item을 찾아 해당 Cell만 reloadItems을 애니메이션 있이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    public func reloadItemWithAnimate(item: [ChatModel]) async {
        if !isClassType {
            return await reloadItemWithAnimateApply(item)
        } else {
            let snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    
    private func reloadItemWithAnimateApply(_ item: [ChatModel]) async {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: true) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reloadItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: true)
                continuation.resume()
            }
        }
    }
}
// MARK: DiffableUpdateState - reconfigure
extension ChatCoordinator {
    /// reconfigure가 필요 없는 이유
    ///
    /// 이상하게 먼지 모르겠는데, ChatModel의 프로퍼티중 하나를 변경한 경우에 snapShot에 새로 갱신을 안해줘도 알아서 갱신되버린다.
    /// 그래서 필요 없는 기능이 되버렸다
    /// 그래서 만약 삭제 기능을 사용할 경우, reload만 해주면 된다.
    ///
    /// > Note: chatList가 Binding이든 아니든 snapShot 바로 갱신되버림
    /// 이유를 찾았따! ChatModel이 Class면 스냅샷에 바로 갱신되고 Struct면 아님
    /// 값 타입과 참조 타입의 차이
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    @available(*, deprecated, renamed: "reconfigureWithoutAnimating(item:)", message: "documentation 참조")
    @MainActor
    public func reconfigure(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
        
        if !isClassType {
            let itemList: [ChatModel.ID] = item.map { $0.id }
            
            let currentItem: [ChatModel.ID] = snapShot.itemIdentifiers
            
            let remainItem: [ChatModel.ID] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume itemList)
            
            snapShot.reconfigureItems(consume remainItem)
            
            await self.dataSource.apply(snapShot)
        } else {
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    /// snapShot의 Cell을 애니메이션 없이 재구성
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reconfigureItem을 애니메이션 없이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    @MainActor
    public func reconfigureWithoutAnimating(item: [ChatModel]) async {
        if !isClassType {
            await reconfigureWithoutAnimatingApply(item)
        } else {
            let snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    
    private func reconfigureWithoutAnimatingApply(_ item: [ChatModel]) async {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: false) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reconfigureItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: false)
                continuation.resume()
            }
        }
    }
    
    /// snapShot의 Cell을 애니메이션 있이 재구성
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reconfigureItem을 애니메이션 있이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    @MainActor
    public func reconfigureWithAnimating(item: [ChatModel]) async {
        if !isClassType {
            await reconfigureWithAnimatingApply(item)
        } else {
            let snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    
    private func reconfigureWithAnimatingApply(_ item: [ChatModel]) async {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let newItem: [ChatModel.ID] = item.map { $0.id }
            snapShot.deleteItems(snapShot.itemIdentifiers)
            snapShot.appendItems(newItem)
            
            self.dataSource.apply(snapShot, animatingDifferences: true) {
                var snapShot = self.dataSource.snapshot()
                snapShot.reconfigureItems(snapShot.itemIdentifiers)
                
                self.dataSource.apply(snapShot, animatingDifferences: true)
                continuation.resume()
            }
        }
    }
}

extension ChatCoordinator {
    public func refresh(item: [ChatModel]) async -> IndexPath {
        if !isClassType {
            return await refreshApply(item)
        } else {
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            snapShot.reloadItems(snapShot.itemIdentifiers)
            await self.dataSource.apply(snapShot, animatingDifferences: false)
        }
        
        return .init(item: 0, section: 0)
    }
    
    func refreshApply(_ item: [ChatModel]) async -> IndexPath {
        return await withCheckedContinuation { continuation in
            var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel.ID> = self.dataSource.snapshot()
            
            let itemList: [ChatModel.ID] = item.map { $0.id }
            let oldCount: Int = snapShot.itemIdentifiers.count
            snapShot.deleteItems(snapShot.itemIdentifiers)
            
            snapShot.appendItems(itemList, toSection: .main)
            
            self.dataSource.applySnapshotUsingReloadData(snapShot) {
                let count: Int = itemList.count - oldCount
                continuation.resume(returning: IndexPath(item: count, section: 0))
            }
        }
    }
}

extension ChatCoordinator {
    /// snapShot에 itemIdentifiers가 비어있는지 확인하는 기능
    ///
    /// - returns:snapShot의 itemIdentifiers가 0이하인 경우 true / 초과인 경우 false를 반환합니다.
    public func isEmpty() -> Bool {
        return self.dataSource.snapshot().itemIdentifiers.count <= 0
    }
    /// oldItem과 newItem을 비교해서 reconfigure를 시킬 item을 뽑아내는 기능
    ///
    /// newItem을 filter를 돌려서 oldItem에 포함안되는 chatModel들을 뽑아
    public func getReconfigureItem(oldItem: consuming [ChatModel.ID], newItem: [ChatModel.ID]) -> [ChatModel.ID] {
        let remainItems: [ChatModel.ID] = self.removeDuplicates(oldItem: consume oldItem, newItem: newItem)
        
        let matchingItems: [ChatModel.ID] = self.matchingItems(from: consume newItem, to: consume remainItems)
        
        return matchingItems
    }
    /// 두 파라미터를 비교해서 같은 아이템들을 찾아내는 기능
    ///
    /// filterModels을 고차하수 돌려서 baseModels의 아이템과 id가 일치한 ChatModel을 반환해준다.
    ///
    /// - returns: id가 일치한 ChatModel 배열 - [ChatModel]
    public func matchingItems(from baseModels: consuming [ChatModel.ID], to filterModels: consuming [ChatModel.ID]) -> [ChatModel.ID] {
        guard !baseModels.isEmpty && !filterModels.isEmpty else {
            return []
        }
        
        let matchingItemsInModel2: [ChatModel.ID] = filterModels.compactMap { item in
            if let index = baseModels.firstIndex(where: { $0 == item }) {
                return baseModels[safe: index]
            } else {
                return nil
            }
        }
        
        return matchingItemsInModel2
    }
    /// 두 파라미터를 비교해서 서로 다른 아이템들의 인덱스들을 찾아내는 기능
    ///
    /// filterModels을 고차함수 돌려서 baseModels와 데이터가 변한 아이템의 인덱스들을 찾아내서 던져준다
    ///
    /// - returns: 데이터가 변한 아이템의 인덱스들을 반환 - [Int]
    public func matchingIndex(from baseModels: consuming [ChatModel.ID], to filterModels: consuming [ChatModel.ID]) -> [Int] {
        guard !baseModels.isEmpty && !filterModels.isEmpty else {
            return []
        }
        
        let matchingIndex: [Int] = filterModels.enumerated().compactMap { index, item in
            if baseModels[safe: index] != item {
                return index
            } else {
                return nil
            }
        }
        
        return matchingIndex
    }
    
    public func getLastIndexPath() -> IndexPath? {
        if let lastId = self.dataSource.snapshot().itemIdentifiers.last {
            if let lastIndexPath = self.dataSource.indexPath(for: lastId) {
                return lastIndexPath
            }
        }
        
        return nil
    }
    
    public func getSnapShotItemCount() -> Int {
        return self.dataSource.snapshot().itemIdentifiers.count
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
