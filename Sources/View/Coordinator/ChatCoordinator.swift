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
public final class ChatCoordinator<ContentView: View, ChatModel: Hashable>: NSObject, UICollectionViewDelegate {
    
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
            print("\(#function) indexPath: \(indexPath)")
            guard let self else { return UICollectionViewCell() }
            
            let cell: UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "chatcell", for: indexPath)
            
            let beforeListModel: ChatModel? = self.beforeListModel(in: indexPath)
            
            cell.contentConfiguration = UIHostingConfiguration {
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
    
//    public func setData(item: [ChatModel]) {
//        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = .init()
//        
//        snapShot.appendSections([.main])
//        
//        snapShot.appendItems(item, toSection: .main)
//        
//        self.dataSource.apply(snapShot)
//    }
//    
//    public func appendItem(item: [ChatModel]) {
//        var snapShot = self.dataSource.snapshot()
//        
//        snapShot.appendItems(item, toSection: .main)
//        
//        self.dataSource.applySnapshotUsingReloadData(snapShot)
//    }
    
//    public func reloadData() {
//        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
//        snapShot.reloadItems(snapShot.itemIdentifiers)
//        self.dataSource.applySnapshotUsingReloadData(snapShot)
//    }
//    
//    public func reconfigureItems() {
//        var snapShot = self.dataSource.snapshot()
//        snapShot.reconfigureItems(snapShot.itemIdentifiers)
//        
//        self.dataSource.apply(snapShot, animatingDifferences: false)
//    }
//    
//    public func newItem(item: [ChatModel]) {
//        var snapShot = self.dataSource.snapshot()
//        let previousItem = snapShot.itemIdentifiers
//        
//        snapShot.deleteItems(previousItem)
//        snapShot.appendItems(item)
//        
//        self.dataSource.apply(snapShot, animatingDifferences: false)
//    }
    
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
        return newItem.filter({ !oldItem.contains($0)} )
    }
}

extension ChatCoordinator {
    public func reconfigure(item: [ChatModel]) async {
        var snapShot: NSDiffableDataSourceSnapshot<MockSection, ChatModel> = self.dataSource.snapshot()
        
        snapShot.deleteItems(snapShot.itemIdentifiers)
        
        snapShot.appendItems(item)
        
        await self.dataSource.apply(snapShot)
        
//        item.forEach {
//            print("\(#function) item: \($0)")
//            
//        }
//        
//        print("\(#function) same: \(item == snapShot.itemIdentifiers)")
//        
//        snapShot.itemIdentifiers.forEach {
//            print("itemIdentifiers \($0)")
//        }
        
//        let currentItem: [ChatModel] = snapShot.itemIdentifiers
//        
//        let remainItem: [ChatModel] = self.removeDuplicates(oldItem: consume currentItem, newItem: consume item)
//        
//        print("\(#function) remainItem: \(remainItem)")
//        
//        snapShot.reconfigureItems(remainItem)
//        
//        await self.dataSource.apply(snapShot)
    }
}

extension ChatCoordinator {
    public func isEmpty() -> Bool {
        return self.dataSource.snapshot().itemIdentifiers.count <= 0
    }
}
