//
//  SMPager.swift
//  SMPager
//
//  Created by Bill Panagiotopoulos on 17/10/2019.
//
//  The MIT License (MIT)
//
//  Copyright (c) 2019 Bill Panagiotopoulos.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//  The name and characters used in the demo of this software are property of their
//  respective owners.

import UIKit

/// Delegation protocol that informs the delegate about the page changed event
public protocol SMPagerDelegate: class {
    func pageChanged(page: Int)
}

/// Delegation protocol that informs the component about the view count and the actual views to be displayed for each index
public protocol SMPagerDataSource: class {
    func numberOfViews() -> Int
    func viewForIndex(_ index: Int, reusedView: UIView?) -> UIView
}

/// Type representation of scroll direction
fileprivate enum InfiniteScrollViewDirection: String {
    case left
    case right
    case none
}

/// SMPager is a child of UIScrollView
open class SMPager: UIScrollView {
    // MARK: Public Properties
    weak public var pagerDelegate: SMPagerDelegate?
    weak public var pagerDataSource: SMPagerDataSource?

    fileprivate(set) public var currentIndex: Int = 0

    public var infiniteScrollingEnabled: Bool = false {
        didSet {
            reloadData()
        }
    }

    // MARK: Private Properties
    fileprivate var initialized = false
    fileprivate var pageChangeAnimationFinished = true
    fileprivate var lastXOffsetBeforePageChange: CGFloat = 0
    fileprivate var lastComponentSize: CGSize = .zero
    fileprivate var lastXOffset: CGFloat = 0
    fileprivate var lastXOffsetDiff: CGFloat = 0.0
    fileprivate var scrollDirection: InfiniteScrollViewDirection = .none
    fileprivate var lastFrameIndex = 0
    fileprivate let animationDuration = 0.3
    fileprivate var frameHeightConstraint: NSLayoutConstraint!
    fileprivate var frameWidthConstraint: NSLayoutConstraint!
    
    // Convenient variable for knowing the Integer representation of the next or previous page, used for calculations.
    fileprivate var pageChangeOffsets: [InfiniteScrollViewDirection: Int] = [
        .left: -1,
        .right: 1,
        .none: 0
    ]
    // This array is used as a "Window" which holds only the visible views.
    // Imagine you have 5 views: [view1] ([view2] [view3] [view4]) [view5] -> only the views in parentheses are rendered.
    fileprivate var frameViews: [Int: UIView] = [:]
    
    // Returns a boolean that indicates if the page is changed, meaning that the scrolling offset
    // is exactly divided with the pager width.
    fileprivate var isPageChanged: Bool {
        // Calculate page changed for infinite scrolling
        if infiniteScrollingEnabled {
            return contentOffset.x.truncatingRemainder(dividingBy: bounds.width) == 0.0
        }
        
        // Check for page change from left to right
        if frameIndex > lastFrameIndex && contentOffset.x.truncatingRemainder(dividingBy: bounds.width) >= 0.0 {
            return true
        }
        // Check for page change from right to left
        else if scrollDirection == .left && contentOffset.x.truncatingRemainder(dividingBy: bounds.width)-abs(self.lastXOffsetDiff) <= 0.0 {
            return true
        }
        return false
    }
    
    // Returns the current position of the frames (it can be 0, 1 or 2)
    fileprivate var frameIndex: Int {
        return Int(contentOffset.x / bounds.width)
    }
    
    fileprivate var maxFrameNumber: Int {
        guard let numberOfViews = self.pagerDataSource?.numberOfViews() else {
            return -1
        }
        return numberOfViews-1 > 1 ? 2 : numberOfViews-1
    }
    
    // Calculates the next page pased on the current x position.
    fileprivate var nextCalculatedPageIndex: Int {
        guard let numberOfViews = pagerDataSource?.numberOfViews() else {
            fatalError("numberOfViews() delegate method not implemented.")
        }

        var newPageIndex = currentIndex
        
        if isPageChanged && scrollDirection != .none {
            newPageIndex += pageChangeOffsets[scrollDirection]!
            
            // Check for upper/lower bounds to create a circular mechanism
            if newPageIndex == pagerDataSource?.numberOfViews() && scrollDirection == .right {
                newPageIndex = 0
            }
            else if newPageIndex == -1  && scrollDirection == .left {
                newPageIndex = numberOfViews-1
            }
        }
        return newPageIndex
    }

    // MARK: Private methods
    // Component initialization.
    // This method is called only once, upon display of pager.
    fileprivate func initializeComponent() {
        bounces = false
        isPagingEnabled = true
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false

        // Disable contentInsetAdjustmentBehavior for iOS 11 and later because it causes problems in landscape orientation.
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        }
        
        reloadData()
    }
    
    // MARK: View Lifecycle
    override open func layoutSubviews() {
        super.layoutSubviews()

        // Initialization code
        if !initialized {
            initializeComponent()
            initialized = true
            return
        }
        updateScrollDirection()
        
        // Detect orientation change
        if lastComponentSize != frame.size {
           self.componentSizeChanged(withSize: self.frame.size)
        }
        
        // Ιf the number of views are 2 then handle them differently
        if infiniteScrollingEnabled {
            handleInfiniteDidScroll()
        } else {
            handleDidScroll()
        }
        lastComponentSize = frame.size
    }
    
    open override func updateConstraints() {
        super.updateConstraints()
        
        let sortedFrameViews = frameViews.keys.sorted().map { frameViews[$0]! }
        
        sortedFrameViews.forEach { $0.removeConstraints($0.constraints) }
        
        var previousFrameView: UIView?
        sortedFrameViews.enumerated().forEach { (index, frame) in
            guard frame.superview != nil else {
                return
            }
            
            if index == 0 {
                frameWidthConstraint = frame.widthAnchor.constraint(equalToConstant: self.frame.size.width)
                frameHeightConstraint = frame.heightAnchor.constraint(equalToConstant: self.frame.size.height)
                
                NSLayoutConstraint.activate([
                    frame.leftAnchor.constraint(equalTo: self.leftAnchor),
                    frameWidthConstraint,
                    frameHeightConstraint
                ])
            }
            if let previousFrameView = previousFrameView, previousFrameView != frame {
                NSLayoutConstraint.activate([
                    frame.leftAnchor.constraint(equalTo: previousFrameView.rightAnchor),
                    frame.heightAnchor.constraint(equalTo: previousFrameView.heightAnchor),
                    frame.widthAnchor.constraint(equalTo: previousFrameView.widthAnchor),
                ])
            }
            
            NSLayoutConstraint.activate([
                frame.topAnchor.constraint(equalTo: topAnchor)
            ])
            
            
            previousFrameView = frame
        }
    }
}

// MARK: Public methods
extension SMPager {
     /// Moves to previous page
     /// - Parameters:
     ///     - animated: animate when moving to previous page.
    public func moveToPreviousPage(animated: Bool = true) {
        guard pageChangeAnimationFinished else {
            return
        }
        pageChangeAnimationFinished = false
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            self.scrollRectToVisible(CGRect.init(x: self.bounds.width * CGFloat(self.frameIndex-1), y: 0, width: self.bounds.width, height: self.bounds.height), animated: false)
        }, completion: { _ in
            self.pageChangeAnimationFinished = true
        })
    }
    
    /// Moves to next page
    /// - Parameters:
    ///     - animated: animate when moving to next page.
    public func moveToNextPage(animated: Bool = true) {
        guard pageChangeAnimationFinished else {
            return
        }
        pageChangeAnimationFinished = false
        UIView.animate(withDuration: animated ? animationDuration : 0.0, animations: {
            self.scrollRectToVisible(CGRect.init(x: self.bounds.width * CGFloat(self.frameIndex+1), y: 0, width: self.bounds.width, height: self.bounds.height), animated: false)
        }, completion: { _ in
            self.pageChangeAnimationFinished = true
        })
    }
    
    /// Moves to a spesific page
    /// - parameters:
    ///   - page: The page to move to (starting from zero)
    public func moveTo(page: Int) {
        currentIndex = page
        reloadData()
    }
    
    ///
    /// Reloads the SMPager by removing all the subviews 
    ///
    public func reloadData() {
        superview?.layoutIfNeeded()
        subviews.forEach({ $0.removeFromSuperview() })
        
        let viewsToBeRendered: [UIView]
        
        if infiniteScrollingEnabled {
            bounces = false
            viewsToBeRendered = viewsForInfinitePager()
        } else {
            viewsToBeRendered = viewsForPager()
        }
            
        for (index, view) in viewsToBeRendered.enumerated() {
            setView(view, toFrameAtIndex: index)
        }
        
        if infiniteScrollingEnabled {
            handleInfiniteDidScroll()
        } else {
            handleDidScroll()
        }
        
        updateConstraints()
    }
}

// MARK: Private Helpers
extension SMPager {
    fileprivate func setView(_ view: UIView, toFrameAtIndex index: Int) {
        guard index >= 0 && index <= 2 else {
            return
        }
        
        removeView(fromFrameAtIndex: index)
        if let _ = view.superview {
            view.removeFromSuperview()
        }
        
        view.clipsToBounds = true
        
        // Add only if not in view hierarchy
        if frameViews[index] == nil {
            addSubview(view)
        }
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        frameViews[index] = view
    }
    
    fileprivate func removeView(fromFrameAtIndex index: Int) {
        guard index >= 0 && index <= 2 else {
            return
        }
        
        if let existingView = frameViews[index] {
            existingView.removeFromSuperview()
            frameViews[index] = nil
        }
    }
    
    fileprivate func moveFrame(fromPosition: Int, toPosition position: Int) {
        if let view = frameViews[fromPosition] {
            setView(view, toFrameAtIndex: position)
            frameViews[fromPosition] = nil
        }
    }
    
    fileprivate func scrollToFrame(_ frame: Int) {
        guard let numberOfViews = pagerDataSource?.numberOfViews(), numberOfViews > 1 else {
            return
        }
        
        contentOffset = CGPoint(x: bounds.width * CGFloat(frame), y: 0)
        lastXOffset = bounds.width
        lastFrameIndex = frame
    }
    
    fileprivate func viewsForInfinitePager() -> [UIView] {
        guard let numberOfViews = pagerDataSource?.numberOfViews(), let viewForIndex = pagerDataSource?.viewForIndex, numberOfViews > 0 else {
            return []
        }
        
        var viewsToBeRendered = [UIView]()
        
        if numberOfViews > 1 {
            let leftIndex = currentIndex == 0 ? numberOfViews-1 : currentIndex-1
            let rightIndex = currentIndex == numberOfViews-1 ? 0 : currentIndex+1
            
            viewsToBeRendered = [
                viewForIndex(leftIndex, nil),
                viewForIndex(currentIndex, nil),
                viewForIndex(rightIndex, nil)
            ]
            
            contentSize = CGSize(width: bounds.width * 3, height: bounds.height)
            scrollToFrame(1)
        } else {
            viewsToBeRendered = [
                viewForIndex(currentIndex, nil),
            ]
            contentOffset.x = 0
            contentSize = CGSize(width: bounds.width, height: bounds.height)
        }
        
        return viewsToBeRendered
    }
    
    fileprivate func viewsForPager() -> [UIView] {
        guard let numberOfViews = pagerDataSource?.numberOfViews(), let viewForIndex = pagerDataSource?.viewForIndex, numberOfViews > 0 else {
            return []
        }
        
        var viewsToBeRendered = [UIView]()
        
        if numberOfViews > 1 {
            var indexSet = IndexSet()
            var frameIndex: Int
            if currentIndex == 0 {
                (0...maxFrameNumber).forEach({ indexSet.insert($0) })
                frameIndex = 0
            }
            else if currentIndex == numberOfViews-1 {
                (currentIndex-maxFrameNumber...currentIndex).forEach({ indexSet.insert($0) })
                frameIndex = maxFrameNumber
            }
            else {
                (currentIndex-1...currentIndex+1).forEach({ indexSet.insert($0) })
                frameIndex = 1
            }
            
            viewsToBeRendered = indexSet.map { viewForIndex($0, nil) }
            
            contentSize = CGSize(width: bounds.width * CGFloat(maxFrameNumber+1), height: bounds.height)
                        
            scrollToFrame(frameIndex)
        } else {
            viewsToBeRendered = [
                viewForIndex(currentIndex, nil),
            ]
            contentOffset.x = 0
            contentSize = CGSize(width: bounds.width, height: bounds.height)
        }
        
        return viewsToBeRendered
    }
    
    fileprivate func isScrolledToPage(_ page: Int, direction: InfiniteScrollViewDirection) -> Bool {
        switch direction {
        case .left:
            return contentOffset.x <= frame.width && lastFrameIndex == 2 && scrollDirection == .left
        case .right:
            return contentOffset.x >= frame.width && lastFrameIndex == 0 && scrollDirection == .right
        case .none:
            return false
        }
    }
        
    fileprivate func updateScrollDirection() {
        if lastXOffset < contentOffset.x {
            scrollDirection = .right
        } else if lastXOffset > contentOffset.x {
            scrollDirection = .left
        } else {
            scrollDirection = .none
        }

        lastXOffsetDiff = lastXOffset - contentOffset.x
        lastXOffset = contentOffset.x
    }
    
    fileprivate func handleInfiniteDidScroll() {
        guard let viewForIndex = pagerDataSource?.viewForIndex else {
            return
        }
        
        if isPageChanged && scrollDirection != .none && lastFrameIndex != frameIndex {
            currentIndex = nextCalculatedPageIndex
            
            if frameIndex == 2 {
                let viewToBeReused = frameViews[0]
                moveFrame(fromPosition: 1, toPosition: 0)
                moveFrame(fromPosition: 2, toPosition: 1)
                setView(viewForIndex(nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 2)
            }
            else if frameIndex == 0 {
                let viewToBeReused = frameViews[2]
                moveFrame(fromPosition: 1, toPosition: 2)
                moveFrame(fromPosition: 0, toPosition: 1)
                setView(viewForIndex(nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 0)
            }
            
            updateConstraints()
            
            lastFrameIndex = frameIndex
            scrollToFrame(1)
            
            pagerDelegate?.pageChanged(page: currentIndex)
        }
    }
    
    fileprivate func handleDidScroll() {
        guard initialized, let viewForIndex = pagerDataSource?.viewForIndex, let numberOfViews = pagerDataSource?.numberOfViews() else {
            return
        }
        
        if isScrolledToPage(numberOfViews-2, direction: .left) {
            pagerDelegate?.pageChanged(page: numberOfViews-2)
        }
        
        if isPageChanged && scrollDirection != .none && lastFrameIndex != frameIndex {
            currentIndex = nextCalculatedPageIndex
            
             // Special case when numberOfViews <= 2
            guard numberOfViews > 2 else {
                // Handle special case when number of views are less than 3
                lastFrameIndex = frameIndex
                pagerDelegate?.pageChanged(page: frameIndex)
                bounces = true
                return
            }
            
            // Scrolling from left to right
            if frameIndex == maxFrameNumber {
                // Force set the correct current index when the scrolling position is in the first 3 frames
                if currentIndex <= 2 {
                    currentIndex = 2
                }
                
                // Enable bouncing when scrolling position is in the last 3 frames
                bounces = currentIndex == numberOfViews-1
                
                // Rearrange views if needed
                if currentIndex < numberOfViews-1 {
                    let viewToBeReused = frameViews[0]
                    moveFrame(fromPosition: 1, toPosition: 0)
                    moveFrame(fromPosition: 2, toPosition: 1)
                    setView(viewForIndex(nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 2)
                    scrollToFrame(1)
                    updateConstraints()
                }
            }
            // Scrolling from right to left
            else if frameIndex == 0 {
                if currentIndex > 0 {
                    // Force set the correct current index when scrolling too fast from right to left
                    if currentIndex > numberOfViews-3 {
                        pagerDelegate?.pageChanged(page: currentIndex)
                        currentIndex = numberOfViews-3
                    }
                    
                    // Rearrange views
                    let viewToBeReused = frameViews[2]
                    moveFrame(fromPosition: 1, toPosition: 2)
                    moveFrame(fromPosition: 0, toPosition: 1)
                    setView(viewForIndex(nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 0)
                    scrollToFrame(1)
                    updateConstraints()
                }
                
                // Enable bouncing when scrolling position when page is 0
                bounces = currentIndex == 0
            }
            
            lastFrameIndex = frameIndex
            pagerDelegate?.pageChanged(page: currentIndex)
        }
        // Enable bouncing for the first/last pages
        if isScrolledToPage(0, direction: .left) || isScrolledToPage(numberOfViews-1, direction: .right) {
            bounces = true
        } else if !isPageChanged && frameIndex > 0 && frameIndex < 2 && numberOfViews > 2 {
            // Disable bouncing between page scrolling
            bounces = false
        }
    }
    
    fileprivate func componentSizeChanged(withSize newSize: CGSize) {
        frameHeightConstraint.constant = newSize.height
        frameWidthConstraint.constant = newSize.width
       
        contentSize.width = newSize.width * CGFloat(frameViews.count)
        contentSize.height = newSize.height
        
        scrollToFrame(lastFrameIndex)
    }
}
