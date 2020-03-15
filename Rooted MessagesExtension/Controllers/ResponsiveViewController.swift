//
//  ResponsiveViewController.swift
//  Rooted MessagesExtension
//
//  Created by Michael Westbrooks on 2/26/20.
//  Copyright © 2020 RedRooster Technologies Inc. All rights reserved.
//

import Foundation
import UIKit

enum LayoutOption {
  case list
  case horizontalList
}

class ResponsiveViewController: BaseAppViewController {

  private var mainCollectionViewController: UICollectionView?
  private var cells = [RootedCollectionViewModel]()
  var layoutOption: LayoutOption = .horizontalList {
    didSet {
      setupLayout(with: view.bounds.size)
    }
  }

  func setup(collectionView: UICollectionView,
             cells: [RootedCollectionViewModel]) {
    if mainCollectionViewController == nil {
      mainCollectionViewController = collectionView
      mainCollectionViewController?.delegate = self
      mainCollectionViewController?.dataSource = self
      mainCollectionViewController?.register(UINib(nibName: "CustomHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "CustomHeader")
      mainCollectionViewController?.register(UINib(nibName: "EmptyHeader", bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "EmptyHeader")

      mainCollectionViewController?.emptyDataSetView { view in
        view.titleLabelString(NSAttributedString(string: "No Events"))
          .detailLabelString(NSAttributedString(string: "When you create or receive an event invite, it will show up here."))
          .image(UIImage(named: "empty"))
          .dataSetBackgroundColor(UIColor.white)
          .shouldDisplay(true)
          .shouldFadeIn(true)
          .isTouchAllowed(true)
          .isScrollAllowed(true)
          .didTapDataButton {
            // Do something
          }
          .didTapContentView {
            // Do something
        }
      }
      registerCells(with: [RootedCollectionViewCell.identifier])
    }

    reloadTable(with: cells)
  }

  private func reloadTable(with data: [RootedCollectionViewModel]) {
    cells.removeAll()
    cells = data
    mainCollectionViewController?.reloadData()
    loadSections()
  }

  func registerCells(with identifiers: [String]) {
    for identifier in identifiers {
      registerCell(with: identifier)
    }
  }

  func registerCell(with identifier: String) {
    mainCollectionViewController?.register(UINib(nibName: identifier, bundle: nil), forCellWithReuseIdentifier: identifier)
  }

  func setupLayout(with containerSize: CGSize) {
    guard let maincollectionviewcontroller = mainCollectionViewController, let flowLayout = maincollectionviewcontroller.collectionViewLayout as? UICollectionViewFlowLayout else {
      return
    }

    switch layoutOption {
    case .horizontalList:

      maincollectionviewcontroller.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
      flowLayout.headerReferenceSize = .zero
      flowLayout.minimumInteritemSpacing = 0
      flowLayout.minimumLineSpacing = 0
      flowLayout.itemSize = CGSize(width: 250, height: 150)
      flowLayout.scrollDirection = .horizontal

    case .list:

//      flowLayout.headerReferenceSize = CGSize(width:  self.view.bounds.width, height: kListViewSectionSize)
      flowLayout.minimumInteritemSpacing = 0
      flowLayout.minimumLineSpacing = 0
      flowLayout.itemSize = CGSize(width: self.view.bounds.width, height: 200)
      flowLayout.sectionInset = UIEdgeInsets(top: 0.0, left: 0, bottom: 0.0, right: 0)
      flowLayout.scrollDirection = .vertical
    }

    mainCollectionViewController?.reloadData()
  }

  private func loadSections() {
    for cell in cells {
      switch cell.section {
      case .sent:
        break
      case .incoming:
        for cell in cell.cells {
//          if let folder = cell.data as? SFFolder, let properties = folder.properties, let layerID = properties.id  {
//            let isPlottedValue: Bool = mapContext.retrieveContextContainer(layerID) != nil
//            let _ = self.setProperties(boolean: isPlottedValue,
//                                       onViewModel: cell)
//          }
        }
        break
      case .today:
        for cell in cell.cells {

        }
        break
      case .tomorrow:
        for cell in cell.cells {
          //          if let folder = cell.data as? SFFolder, let properties = folder.properties, let layerID = properties.id  {
          //            let isPlottedValue: Bool = mapContext.retrieveContextContainer(layerID) != nil
          //            let _ = self.setProperties(boolean: isPlottedValue,
          //                                       onViewModel: cell)
          //          }
        }
        break
      case .none:
        for cell in cell.cells {

        }
        break
      case .custom(_):
        for cell in cell.cells {

        }
        break
      }
    }
  }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension ResponsiveViewController: UICollectionViewDataSource, UICollectionViewDelegate {

  func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return cells.count
  }

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    let listViewCells = cells[section]
    return listViewCells.cells.count
  }

  func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
    switch kind {
    case UICollectionView.elementKindSectionHeader:
      let listViewCells = cells[indexPath.section]
      if listViewCells.cells.count > 0 {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CustomHeader", for: indexPath) as! CustomHeader
        if layoutOption == .horizontalList {
          headerView.configure(title: listViewCells.section.title + ":")
        } else {
          headerView.configure(title: listViewCells.section.title)
        }
        return headerView
      } else {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EmptyHeader", for: indexPath) as! EmptyHeader
        return headerView
      }
    default:
      let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "EmptyHeader", for: indexPath) as! EmptyHeader
      return headerView
    }
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let listViewCells = cells[indexPath.section]
    let item = listViewCells.cells[indexPath.row]
    return configureCell(data: item, collectionView: collectionView, indexPath: indexPath)
  }

  fileprivate func configureCell(data: RootedCellViewModel, collectionView: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: data.configurableCellType.reuseIdentifier, for: indexPath) as? RootedCollectionViewCell else { return UICollectionViewCell() }
    cell.configure(viewModel: data, layout: self.layoutOption)
    return cell
  }

  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    let listViewCells = cells[indexPath.section]
    guard let item = listViewCells.cells[indexPath.row].data else { return }
    let destination = InviteDetailsVC.setupViewController(meeting: item)
    NavigationCoordinator.performExpandedNavigation(from: self) {
      self.present(destination, animated: true, completion: nil)
    }
  }
}
