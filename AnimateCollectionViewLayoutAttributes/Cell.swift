//
//  Utilities.swift
//  AnimateBetweenCollectionLayouts
//
//  Created by Zheng on 8/14/21.
//

import UIKit

class Cell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    /// https://stackoverflow.com/a/57249637/14351818
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.zPosition = CGFloat(layoutAttributes.zIndex) // or any zIndex you want to set
    }
}

