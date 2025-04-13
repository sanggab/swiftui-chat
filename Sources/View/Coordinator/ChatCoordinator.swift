//
//  ChatCoordinator.swift
//  GabChat
//
//  Created by 심상갑 on 4/6/25.
//

import SwiftUI

public protocol ItemProtocol: Hashable, Identifiable {
    
}

/// ChatCoordinator
///
/// UICollectionView와 관련된 요소(ex: delegate)를 처리하는 class
public final class ChatCoordinator<ContentView: View, ChatModel: ItemProtocol>: NSObject, UICollectionViewDelegate {
    
    public typealias ItemBuilderClosure = (before: ChatModel?, current: ChatModel)
    
    private var itemBuilder: (ItemBuilderClosure) -> ContentView
    
    private var isRefresh: (() -> Void)?
    
    private var dataSource: UICollectionViewDiffableDataSource<MockSection, ChatModel>!
    
    let isClassType: Bool
    
    public init(itemBuilder: @escaping (ItemBuilderClosure) -> ContentView,
                isRefresh: (() -> Void)?) {
        self.itemBuilder = itemBuilder
        self.isRefresh = isRefresh
        self.isClassType = ChatModel.self is AnyObject.Type
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
    
    public func setDataSource(view: UICollectionView) {
        self.dataSource = UICollectionViewDiffableDataSource<MockSection, ChatModel>(collectionView: view, cellProvider: { [weak self] collectionView, indexPath, ChatModel in
            
            guard let self else { return UICollectionViewCell() }
            
            let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "chatcell", for: indexPath)
            
            let beforeListModel: ChatModel? = self.beforeListModel(in: indexPath)
            
            cell.contentConfiguration = UIHostingConfiguration {
//                let _ = print("\(#function) indexPath: \(indexPath)")
                self.itemBuilder((beforeListModel, ChatModel))
            }
            .minSize(width: 0, height: 0)
            .margins(.all, 0)
            
            return cell
        })
    }
    
    private func beforeListModel(in index: IndexPath) -> ChatModel? {
        return self.dataSource.snapshot().itemIdentifiers[safe: index.item - 1]
    }
    
    public func check() {
        print("\(#function) self.dataSource.snapshot().itemIdentifiers: \(self.dataSource.snapshot().itemIdentifiers)")
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("\(#function) y: \(scrollView.contentOffset.y)")
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if let isRefreshing = scrollView.refreshControl?.isRefreshing, isRefreshing {
            self.isRefresh?()
            scrollView.refreshControl?.endRefreshing()
        }
    }
}

// MARK: DiffableUpdateState - onAppear
extension ChatCoordinator {
    @MainActor
    public func onAppear(item: [ChatModel]) async {
        if self.dataSource.snapshot().itemIdentifiers.count == 0 {
            await self.asyncSetData(item: item)
        }
    }
    
    @MainActor
    public func asyncSetData(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = .init()
        
        snapShot.appendSections([.main])
        
        snapShot.appendItems(item, toSection: .main)
        
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
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        snapShot.appendItems([consume item])
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
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let currentItem: [ChatModel] = snapShot.itemIdentifiers
        
        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume item)
        
        if !remainItem.isEmpty {
            snapShot.appendItems(remainItem)
            await self.dataSource.apply(snapShot)
            return true
        }
        
        return false
    }
    /// 두 파라미터를 비교해서 중복을 데이터를 데이터를 던져준다
    ///
    /// newItem에 filter을 돌려서 oldItem의 리스트에서 포함되지 않는 item들을 뽑아서 반환해준다.
    ///
    /// - returns: oldItem에 포함되지 않은 item들을 반환 - [ChatModel]
    public func removeDuplicates(oldItem: consuming [ChatModel], newItem: consuming [ChatModel]) -> [ChatModel] {
        return newItem.filter { item in
            if !oldItem.contains(item) {
                return true
            } else {
                return false
            }
        }
    }
}

extension ChatCoordinator {
    /// UICollectionView을 전체 reload 합니다.
    ///
    /// 현재 snapShot에 있는 items들을 모두 삭제하고 새 item들을 추가한 다음 애니메이션 없이 reload를 합니다.
    public func reloadWithoutAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        snapShot.deleteItems(snapShot.itemIdentifiers)
        snapShot.appendItems(item)
        
        snapShot.reloadItems(consume item)
        
        await self.dataSource.apply(snapShot, animatingDifferences: false)
    }
    /// UICollectionView을 전체 reload 합니다.
    ///
    /// 현재 snapShot에 있는 items들을 모두 삭제하고 새 item들을 추가한 다음 애니메이션 있이 reload를 합니다.
    public func reloadWithAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        snapShot.deleteItems(snapShot.itemIdentifiers)
        snapShot.appendItems(item)
        
        snapShot.reloadItems(consume item)
        
        await self.dataSource.apply(snapShot, animatingDifferences: true)
    }
    /// snapShot의 Cell을 애니메이션 없이 reload
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서  데이터가 달라진 item을 찾아 해당 Cell만 reloadItems을 애니메이션 없이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    public func reloadItemWithoutAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        if !isClassType {
            let reloadItem: [ChatModel] = self.removeDuplicates(oldItem: snapShot.itemIdentifiers, newItem: item)
            
            if !reloadItem.isEmpty {
                snapShot.deleteItems(snapShot.itemIdentifiers)
                
                snapShot.appendItems(consume item, toSection: .main)
                
                snapShot.reloadItems(consume reloadItem)
                
                await self.dataSource.apply(snapShot, animatingDifferences: false)
            }
        } else {
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    /// snapShot의 Cell을 애니메이션 있이 reload
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서  데이터가 달라진 item을 찾아 해당 Cell만 reloadItems을 애니메이션 있이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    public func reloadItemWithAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        if !isClassType {
            let reloadItem: [ChatModel] = self.removeDuplicates(oldItem: snapShot.itemIdentifiers, newItem: item)
            
            if !reloadItem.isEmpty {
                snapShot.deleteItems(snapShot.itemIdentifiers)
                
                snapShot.appendItems(consume item, toSection: .main)
                
                snapShot.reloadItems(consume reloadItem)
                
                await self.dataSource.apply(snapShot, animatingDifferences: true)
            }
        } else {
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
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
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        if !isClassType {
            let currentItem: [ChatModel] = snapShot.itemIdentifiers
            
            let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume item)
            
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
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        if !isClassType {
            let reconfigureItems: [ChatModel] = self.removeDuplicates(oldItem: snapShot.itemIdentifiers, newItem: item)
            
            if !reconfigureItems.isEmpty {
                snapShot.deleteItems(snapShot.itemIdentifiers)
                
                snapShot.appendItems(consume item, toSection: .main)
                
                snapShot.reconfigureItems(consume reconfigureItems)
                
                await self.dataSource.apply(snapShot, animatingDifferences: false)
            }
        } else {
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
        }
    }
    /// snapShot의 Cell을 애니메이션 있이 재구성
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서 데이터가 달라진 item을 찾아 해당 Cell만 reconfigureItem을 애니메이션 있이 실행한다.
    ///
    /// > Warning: 만약 ChatModel이 Class 타입인 경우, 전체 item을 다 reload 시킵니다.
    @MainActor
    public func reconfigureWithAnimating(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        if !isClassType {
            let reconfigureItems: [ChatModel] = self.removeDuplicates(oldItem: snapShot.itemIdentifiers, newItem: item)
            
            if !reconfigureItems.isEmpty {
                snapShot.deleteItems(snapShot.itemIdentifiers)
                
                snapShot.appendItems(consume item, toSection: .main)
                
                snapShot.reconfigureItems(consume reconfigureItems)
                
                await self.dataSource.apply(snapShot, animatingDifferences: true)
            }
        } else {
            await self.dataSource.applySnapshotUsingReloadData(snapShot)
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
    public func getReconfigureItem(oldItem: consuming [ChatModel], newItem: [ChatModel]) -> [ChatModel] {
        let remainItems: [ChatModel] = self.removeDuplicates(oldItem: consume oldItem, newItem: newItem)
        
        let matchingItems: [ChatModel] = self.matchingItems(from: consume newItem, to: consume remainItems)
        
        return matchingItems
    }
    /// 두 파라미터를 비교해서 같은 아이템들을 찾아내는 기능
    ///
    /// filterModels을 고차하수 돌려서 baseModels의 아이템과 id가 일치한 ChatModel을 반환해준다.
    ///
    /// - returns: id가 일치한 ChatModel 배열 - [ChatModel]
    public func matchingItems(from baseModels: consuming [ChatModel], to filterModels: consuming [ChatModel]) -> [ChatModel] {
        guard !baseModels.isEmpty && !filterModels.isEmpty else {
            return []
        }
        
        let matchingItemsInModel2: [ChatModel] = filterModels.compactMap { item in
            if let index = baseModels.firstIndex(where: { $0.id == item.id }) {
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
    public func matchingIndex(from baseModels: consuming [ChatModel], to filterModels: consuming [ChatModel]) -> [Int] {
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
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
