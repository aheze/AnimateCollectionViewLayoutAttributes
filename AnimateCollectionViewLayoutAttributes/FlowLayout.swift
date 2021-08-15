//
//  FlowLayout.swift
//  AnimateBetweenCollectionLayouts
//
//  Created by Zheng on 6/24/21.
//

import UIKit

enum LayoutType {
    case strip
    case list
}

/**
 Enum to hold the type of layout transition
 */
fileprivate enum LayoutTransition{
    case fromStripToList
    case fromListToStrip
}

class FlowLayout: UICollectionViewFlowLayout {
    
    var animating: Bool = false
    var preparedOnce: Bool = false
    var layoutType: LayoutType
    var layoutAttributes = [UICollectionViewLayoutAttributes]() /// store the frame of each item
    var contentSize = CGSize.zero /// the scrollable content size of the collection view
    override var collectionViewContentSize: CGSize { return contentSize } /// pass scrollable content size back to the collection view
    
    /**
     Fix content offset jumping
     */
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard animating else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }

        switch(layoutType){
        case .list: return transformCurrentContentOffset(.fromStripToList)
        case .strip: return transformCurrentContentOffset(.fromListToStrip)
        }
    }
    
    /// pass attributes to the collection view flow layout
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.item]
    }
    
    // MARK: - Problem is here
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        /// edge cells don't shrink, but the animation is perfect
        // return layoutAttributes.filter { rect.intersects($0.frame) } /// try deleting this line
        
        /// edge cells shrink (yay!), but the animation glitches out
        return shrinkingEdgeCellAttributes(in: rect)
    }
    
    /// makes the edge cells slowly shrink as you scroll
    func shrinkingEdgeCellAttributes(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }

        var rectAttributes: [UICollectionViewLayoutAttributes] = []
        /// rect of the visible collection view cells
        let ogVisibleRect: CGRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        var visibleRect: CGRect
        
        print("Content Offset", collectionView.contentOffset)
        
        if animating{
            if layoutType == .strip{
                visibleRect = transformVisibleRectToOppositeLayout(.fromListToStrip, ogVisibleRect)
            }
            else{
                visibleRect = transformVisibleRectToOppositeLayout(.fromStripToList, ogVisibleRect)
            }
            
            rectAttributes = layoutAttributes
        }
        else{
            visibleRect = ogVisibleRect
            rectAttributes = layoutAttributes.filter { rect.intersects($0.frame) }
        }

        let leadingCutoff: CGFloat = 50 /// once a cell reaches here, start shrinking it
        let trailingCutoff: CGFloat
        let paddingInsets: UIEdgeInsets /// apply shrinking even when cell has passed the screen's bounds

        if layoutType == .strip {
            trailingCutoff = CGFloat(collectionView.bounds.width - leadingCutoff)
            paddingInsets = UIEdgeInsets(top: 0, left: -50, bottom: 0, right: -50)
        } else {
            trailingCutoff = CGFloat(collectionView.bounds.height - leadingCutoff)
            paddingInsets = UIEdgeInsets(top: -50, left: 0, bottom: -50, right: 0)
        }
        
        // Reset transform
        for attributes in rectAttributes{
            attributes.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
        }

        for attributes in rectAttributes where visibleRect.inset(by: paddingInsets).contains(attributes.center) {
            /// center of each cell, converted to a point inside `visibleRect`
            let center = layoutType == .strip
                ? attributes.center.x - visibleRect.origin.x
                : attributes.center.y - visibleRect.origin.y

            var offset: CGFloat?
            if center <= leadingCutoff {
                offset = leadingCutoff - center /// distance from the cutoff, 0 if exactly on cutoff
            } else if center >= trailingCutoff {
                offset = center - trailingCutoff
            }

            if let offset = offset {
                let scale = 1 - (pow(offset, 1.1) / 200) /// gradually shrink the cell
                attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
            }
        }
        return rectAttributes
    }
    
    /// initialize with a LayoutType
    init(layoutType: LayoutType) {
        self.layoutType = layoutType
        super.init()
    }
    
    /// make the layout (strip vs list) here
    override func prepare() { /// configure the cells' frames
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        // FIX redundant prepare calls
        guard !preparedOnce else { return }
        preparedOnce = true
        layoutAttributes = []
        
        var offset: CGFloat = 0 /// origin for each cell
        let cellSize = layoutType == .strip ? CGSize(width: 100, height: 50) : CGSize(width: collectionView.frame.width, height: 50)
        
        for itemIndex in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: itemIndex, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            let origin: CGPoint
            let addedOffset: CGFloat
            if layoutType == .strip {
                origin = CGPoint(x: offset, y: 0)
                addedOffset = cellSize.width
            } else {
                origin = CGPoint(x: 0, y: offset)
                addedOffset = cellSize.height
            }
            
            attributes.frame = CGRect(origin: origin, size: cellSize)
            layoutAttributes.append(attributes)
            offset += addedOffset
        }
        
        self.contentSize = layoutType == .strip /// set the collection view's `collectionViewContentSize`
            ? CGSize(width: offset, height: cellSize.height) /// if strip, height is fixed
            : CGSize(width: cellSize.width, height: offset) /// if list, width is fixed
    }
    
    /// boilerplate code
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
    func reset(){
        preparedOnce = false
    }
}

// MARK: Helper Methods

extension FlowLayout{
    
    
    private func transformVisibleRectToOppositeLayout(_ transition: LayoutTransition, _ source: CGRect) -> CGRect{
        let transformedContentOffset = transformCurrentContentOffset(transition)
        return CGRect(origin: transformedContentOffset, size: source.size)
    }
    
    /**
     Transforms this layouts content offset, to the other layout
     as specified in the layout transition parameter.
     */
    private func transformCurrentContentOffset(_ transition: LayoutTransition) -> CGPoint{
        
        let stripItemWidth: CGFloat = 100.0
        let listItemHeight: CGFloat = 50.0
        
        switch(transition){
        case .fromStripToList:
            let numberOfItems = collectionView!.contentOffset.x / stripItemWidth  // from strip
            var newPoint = CGPoint(x: 0, y: numberOfItems * CGFloat(listItemHeight)) // to list

            if (newPoint.y + collectionView!.frame.height) >= contentSize.height{
                newPoint = CGPoint(x: 0, y: contentSize.height - collectionView!.frame.height)
            }

            return newPoint

        case .fromListToStrip:
            let numberOfItems = collectionView!.contentOffset.y / listItemHeight // from list
            var newPoint = CGPoint(x: numberOfItems * CGFloat(stripItemWidth), y: 0) // to strip

            if (newPoint.x + collectionView!.frame.width) >= contentSize.width{
                newPoint = CGPoint(x: contentSize.width - collectionView!.frame.width, y: 0)
            }

            return newPoint
        }
    }
    
}
