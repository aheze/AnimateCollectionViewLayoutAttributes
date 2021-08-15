//
//  ViewController.swift
//  AnimateBetweenCollectionLayouts
//
//  Created by Zheng on 6/20/21.
//

import UIKit

class ViewController: UIViewController {
    
    var data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
    
    var isExpanded = false
    lazy var listLayout = FlowLayout(layoutType: .list)
    lazy var stripLayout = FlowLayout(layoutType: .strip)
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBAction func toggleExpandPressed(_ sender: Any) {
        
        // See change in layout better
        collectionView.layer.speed = 0.7
        isExpanded.toggle()
        if isExpanded {
            listLayout.reset()
            listLayout.animating = true
            collectionView.setCollectionViewLayout(listLayout, animated: true) { (completed) in
                if completed{
                    self.listLayout.animating = false
                }
            }
        } else {
            stripLayout.reset()
            stripLayout.animating = true
            collectionView.setCollectionViewLayout(stripLayout, animated: true) { (completed) in
                if completed{
                    self.stripLayout.animating = false
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = stripLayout /// start with the strip layout
        collectionView.dataSource = self
        collectionViewHeightConstraint.constant = 300
    }
}

/// sample data source
extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ID", for: indexPath) as! Cell
        cell.label.text = "\(data[indexPath.item])"
        cell.contentView.layer.borderWidth = 5
        cell.contentView.layer.borderColor = UIColor.red.cgColor
        return cell
    }
}

