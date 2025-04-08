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
    
    private var dataSource: UICollectionViewDiffableDataSource<MockSection, ChatModel>!
    
    public init(itemBuilder: @escaping (ItemBuilderClosure) -> ContentView) {
        self.itemBuilder = itemBuilder
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
                let _ = print("\(#function) indexPath: \(indexPath)")
                self.itemBuilder((beforeListModel, ChatModel))
            }
            .minSize(width: 0, height: 0)
            .margins(.all, 0)
            
            return cell
        })
    }
    
    private func beforeListModel(in index: IndexPath) -> ChatModel? {
        return self.dataSource.itemIdentifier(for: index)
    }
    
    public func check() {
        print("\(#function) self.dataSource.snapshot().itemIdentifiers: \(self.dataSource.snapshot().itemIdentifiers)")
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
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
        
        await self.dataSource.apply(snapShot)
    }
}

// MARK: DiffableUpdateState - appendItem
extension ChatCoordinator {
    @MainActor
    public func appendItem(item: [ChatModel]) async -> Bool {
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
    
    public func removeDuplicates(oldItem: consuming [ChatModel], newItem: consuming [ChatModel]) -> [ChatModel] {
        print("상갑 logEvent \(#function) newItem: \(newItem)")
        print("상갑 logEvent \(#function) oldItem: \(oldItem)")
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
    public func reloadWithoutAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let currentItem: [ChatModel] = snapShot.itemIdentifiers
        
        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume item)
        print("\(#function) remainItem: \(remainItem)")
        
//        await self.dataSource.apply(snapShot, animatingDifferences: false)
    }
    
    public func reloadWithAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let currentItem: [ChatModel] = snapShot.itemIdentifiers
        
        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume item)
        print("\(#function) remainItem: \(remainItem)")
        
//        await self.dataSource.apply(snapShot, animatingDifferences: true)
    }
    
    public func reloadItemWithoutAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let currentItem: [ChatModel] = snapShot.itemIdentifiers
        
        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: item)
        print("\(#function) remainItem: \(remainItem)")
        
        if !remainItem.isEmpty {
            snapShot.deleteItems(snapShot.itemIdentifiers)
            
            snapShot.appendItems(consume item, toSection: .main)
            
            snapShot.reloadItems(consume remainItem)
            
            await self.dataSource.apply(snapShot, animatingDifferences: false)
        }
    }
    
    public func reloadItemWithAnimate(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let currentItem: [ChatModel] = snapShot.itemIdentifiers
        
        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: item)
        print("\(#function) remainItem: \(remainItem)")
        
        if !remainItem.isEmpty {
            snapShot.deleteItems(snapShot.itemIdentifiers)
            
            snapShot.appendItems(consume item, toSection: .main)
            
            snapShot.reloadItems(consume remainItem)
            
            await self.dataSource.apply(snapShot, animatingDifferences: true)
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
    @available(*, deprecated, renamed: "reconfigureWithoutAnimating(item:)", message: "documentation 참조")
    public func reconfigure(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let currentItem: [ChatModel] = snapShot.itemIdentifiers
        
        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume item)
        
        snapShot.reconfigureItems(remainItem)
        
        await self.dataSource.apply(snapShot)
    }
    /// 애니메이션 없이 Cell을 재구성
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서 id값이 일치하지만 데이터가 달라진 item을 찾아 해당 Cell만 reconfigureItem을 애니메이션 없이 실행한다.
    public func reconfigureWithoutAnimating(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let matchingItems: [ChatModel] = self.getReconfigureItem(oldItem: snapShot.itemIdentifiers, newItem: item)
        
        if !matchingItems.isEmpty {
            snapShot.deleteItems(snapShot.itemIdentifiers)
            
            snapShot.appendItems(consume item, toSection: .main)
            
            snapShot.reconfigureItems(consume matchingItems)
            
            await self.dataSource.apply(snapShot, animatingDifferences: false)
        }
    }
    /// 애니메이션 없이 Cell을 재구성
    ///
    /// 파라미터의 item하고 snapShot의 item을 비교해서 id값이 일치하지만 데이터가 달라진 item을 찾아 해당 Cell만 reconfigureItem을 애니메이션 있이 실행한다.
    public func reconfigureWithAnimating(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        let matchingItems: [ChatModel] = self.getReconfigureItem(oldItem: snapShot.itemIdentifiers, newItem: item)
        
        if !matchingItems.isEmpty {
            snapShot.deleteItems(snapShot.itemIdentifiers)
            
            snapShot.appendItems(consume item, toSection: .main)
            
            snapShot.reconfigureItems(consume matchingItems)
            
            await self.dataSource.apply(snapShot, animatingDifferences: true)
        }
    }
}

extension ChatCoordinator {
    public func isEmpty() -> Bool {
        return self.dataSource.snapshot().itemIdentifiers.count <= 0
    }
    
    public func getReconfigureItem(oldItem: consuming [ChatModel], newItem: [ChatModel]) -> [ChatModel] {
        let remainItems: [ChatModel] = self.removeDuplicates(oldItem: consume oldItem, newItem: newItem)
        
        let matchingItems: [ChatModel] = self.matchingItems(from: consume newItem, to: consume remainItems)
        
        return matchingItems
    }
    
    public func matchingItems(from baseModels: consuming [ChatModel], to filterModels: consuming [ChatModel]) -> [ChatModel] {
        guard !baseModels.isEmpty && !filterModels.isEmpty else {
            return []
        }
        
        let matchingItemsInModel2 = filterModels.compactMap { item in
            if let index = baseModels.firstIndex(where: { $0.id == item.id }) {
                return baseModels[safe: index]
            } else {
                return nil
            }
        }
        
        return matchingItemsInModel2
    }
}

extension Collection {
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
