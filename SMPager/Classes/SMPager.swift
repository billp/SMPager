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
    func viewForIndex(_ index: Int, reuseView: UIView?) -> UIView
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
    public var infiniteScrollingEnabled: Bool = true {
        didSet {
            reloadData()
        }
    }

    // MARK: Private Properties
    fileprivate var _initialized = false
    fileprivate var _pageChangeAnimationFinished = true
    fileprivate var _lastXOffsetBeforePageChange: CGFloat = 0
    fileprivate var _orientationChanged: Bool = false
    fileprivate var _lastComponentSize: CGSize = .zero
    fileprivate var _currentIndex: Int = 0
    fileprivate var _lastXOffset: CGFloat = 0
    fileprivate var _scrollDirection: InfiniteScrollViewDirection = .none
    fileprivate var _lastFrameIndex = 0
    fileprivate let _animationDuration = 0.3

    // Convenient variable for knowing the Integer representation of the next or previous page, used for calculations.
    fileprivate var _pageChangeOffsets: [InfiniteScrollViewDirection: Int] = [
        .left: -1,
        .right: 1,
        .none: 0
    ]
    // This array is used as a "Window" which holds only the visible views.
    // Imagine you have 5 views: [view1] ([view2] [view3] [view4]) [view5] -> only the views in parentheses are rendered.
    fileprivate var _frameViews: [Int: UIView] = [:]
    
    // Returns a boolean that indicates if the page is changed, meaning that the scrolling offset
    // is exactly divided with the pager width.
    fileprivate var _isPageChanged: Bool {
        return contentOffset.x.truncatingRemainder(dividingBy: bounds.width) == 0.0
    }
    
    // Returns the current position of the frames (it can be 0, 1 or 2)
    fileprivate var _frameIndex: Int {
        return Int(contentOffset.x / bounds.width)
    }
    
    fileprivate var _maxFrameNumber: Int {
        guard let numberOfViews = self.pagerDataSource?.numberOfViews() else {
            return -1
        }
        return numberOfViews-1 > 1 ? 2 : numberOfViews-1
    }
    
    // Calculates the next page pased on the current x position.
    fileprivate var _nextCalculatedPageIndex: Int {
        guard let numberOfViews = pagerDataSource?.numberOfViews() else {
            fatalError("numberOfViews() delegate method not implemented.")
        }

        var newPageIndex = _currentIndex
        
        if _isPageChanged && _scrollDirection != .none {
            newPageIndex += _pageChangeOffsets[_scrollDirection]!
            
            // Check for upper/lower bounds to create a circular mechanism
            if newPageIndex == pagerDataSource?.numberOfViews() && _scrollDirection == .right {
                newPageIndex = 0
            }
            else if newPageIndex == -1  && _scrollDirection == .left {
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
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        reloadData()
    }
    
    // MARK: View Lifecycle
    override open func layoutSubviews() {
        super.layoutSubviews()

        // Initialization code
        if !_initialized {
            initializeComponent()
            _initialized = true
            return
        }
        updateScrollDirection()
        
        // Ιf the number of views are 2 then handle them differently
        if infiniteScrollingEnabled {
            handleInfiniteDidScroll()
        } else {
            handleDidScroll()
        }
    }
}

// MARK: Public methods
extension SMPager {
     /// Moves to previous page
     /// - Parameters:
     ///     - animated: animate when previous to next page.
    public func moveToPreviousPage(animated: Bool = true) {
        guard _pageChangeAnimationFinished else {
            return
        }
        _pageChangeAnimationFinished = false
        UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
            self.scrollRectToVisible(CGRect.init(x: 0, y: 0, width: self.bounds.width, height: self.bounds.height), animated: false)
        }, completion: { _ in
            self._pageChangeAnimationFinished = true
        })
    }
    
    /// Moves to next page
    /// - Parameters:
    ///     - animated: animate when moving to next page.
    public func moveToNextPage(animated: Bool = true) {
        guard _pageChangeAnimationFinished else {
            return
        }
        _pageChangeAnimationFinished = false
        UIView.animate(withDuration: animated ? _animationDuration : 0.0, animations: {
            self.scrollRectToVisible(CGRect.init(x: self.bounds.width*2, y: 0, width: self.bounds.width, height: self.bounds.height), animated: false)
        }, completion: { _ in
            self._pageChangeAnimationFinished = true
        })
    }
    
    /// Moves to a spesific page
    /// - parameters:
    ///   - page: The page to move to (starting from zero)
    public func moveTo(page: Int) {
        _currentIndex = page
        reloadData()
    }
    
    /**
     * Reloads the SMPager
     */
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
        
        view.frame = CGRect(x: CGFloat(index) * bounds.width, y: 0, width: bounds.width, height: bounds.height)
        view.clipsToBounds = true
        
        // Add only if not in view hierarchy
        if _frameViews[index] == nil {
            addSubview(view)
        }
        
        _frameViews[index] = view
    }
    
    fileprivate func removeView(fromFrameAtIndex index: Int) {
        guard index >= 0 && index <= 2 else {
            return
        }
        
        if let existingView = _frameViews[index] {
            existingView.removeFromSuperview()
            _frameViews[index] = nil
        }
    }
    
    fileprivate func moveFrame(fromPosition: Int, toPosition position: Int) {
        if let view = _frameViews[fromPosition] {
            setView(view, toFrameAtIndex: position)
            _frameViews[fromPosition] = nil
        }
    }
    
    fileprivate func moveToFrame(_ frame: Int) {
        guard let numberOfViews = pagerDataSource?.numberOfViews(), numberOfViews > 1 else {
            return
        }
        
        contentOffset = CGPoint(x: bounds.width * CGFloat(frame), y: 0)
        _lastXOffset = bounds.width
        _lastFrameIndex = frame
    }
    
    fileprivate func viewsForInfinitePager() -> [UIView] {
        guard let numberOfViews = pagerDataSource?.numberOfViews(), let viewForIndex = pagerDataSource?.viewForIndex, numberOfViews > 0 else {
            return []
        }
        
        var viewsToBeRendered = [UIView]()
        
        if numberOfViews > 1 {
            let leftIndex = _currentIndex == 0 ? numberOfViews-1 : _currentIndex-1
            let rightIndex = _currentIndex == numberOfViews-1 ? 0 : _currentIndex+1
            
            viewsToBeRendered = [
                viewForIndex(leftIndex, nil),
                viewForIndex(_currentIndex, nil),
                viewForIndex(rightIndex, nil)
            ]
            
            contentSize = CGSize(width: bounds.width * 3, height: bounds.height)
            moveToFrame(1)
        } else {
            viewsToBeRendered = [
                viewForIndex(_currentIndex, nil),
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
            if _currentIndex == 0 {
                (0..._maxFrameNumber).forEach({ indexSet.insert($0) })
                frameIndex = 0
            }
            else if _currentIndex == numberOfViews-1 {
                (_currentIndex-_maxFrameNumber..._currentIndex).forEach({ indexSet.insert($0) })
                frameIndex = _maxFrameNumber
            }
            else {
                (_currentIndex-1..._currentIndex+1).forEach({ indexSet.insert($0) })
                frameIndex = 1
            }
            
            viewsToBeRendered = indexSet.map { viewForIndex($0, nil) }
            
            contentSize = CGSize(width: bounds.width * CGFloat(_maxFrameNumber+1), height: bounds.height)
                        
            moveToFrame(frameIndex)
        } else {
            viewsToBeRendered = [
                viewForIndex(_currentIndex, nil),
            ]
            contentOffset.x = 0
            contentSize = CGSize(width: bounds.width, height: bounds.height)
        }
        
        return viewsToBeRendered
    }
    
    fileprivate func updateScrollDirection() {
        if _lastXOffset < contentOffset.x {
            _scrollDirection = .right
        } else if _lastXOffset > contentOffset.x {
            _scrollDirection = .left
        } else {
            _scrollDirection = .none
        }

        _lastXOffset = contentOffset.x
    }
    
    fileprivate func handleInfiniteDidScroll() {
        guard let viewForIndex = pagerDataSource?.viewForIndex else {
            return
        }
        
        if _isPageChanged && _scrollDirection != .none && _lastFrameIndex != _frameIndex {
            _currentIndex = _nextCalculatedPageIndex
            
            if _frameIndex == 2 {
                let viewToBeReused = _frameViews[0]
                moveFrame(fromPosition: 1, toPosition: 0)
                moveFrame(fromPosition: 2, toPosition: 1)
                setView(viewForIndex(_nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 2)
            }
            else if _frameIndex == 0 {
                let viewToBeReused = _frameViews[2]
                moveFrame(fromPosition: 1, toPosition: 2)
                moveFrame(fromPosition: 0, toPosition: 1)
                setView(viewForIndex(_nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 0)
            }
            
            _lastFrameIndex = _frameIndex
            moveToFrame(1)
            
            pagerDelegate?.pageChanged(page: _currentIndex)
        }
    }
    
    fileprivate func handleDidScroll() {
        guard _initialized, let viewForIndex = pagerDataSource?.viewForIndex, let numberOfViews = pagerDataSource?.numberOfViews() else {
            return
        }
        
        if _isPageChanged && _scrollDirection != .none && _lastFrameIndex != _frameIndex {
            _currentIndex = _nextCalculatedPageIndex
            
            guard numberOfViews > 2 else {
                _lastFrameIndex = _frameIndex
                pagerDelegate?.pageChanged(page: _frameIndex)
                bounces = true
                return
            }
            
            if _frameIndex == _maxFrameNumber {
                if _currentIndex <= 2 {
                    _currentIndex = 2
                }
                
                bounces = _currentIndex == numberOfViews-1
                
                if _currentIndex < numberOfViews-1 {
                    let viewToBeReused = _frameViews[0]
                    moveFrame(fromPosition: 1, toPosition: 0)
                    moveFrame(fromPosition: 2, toPosition: 1)
                    setView(viewForIndex(_nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 2)
                    moveToFrame(1)
                }
            }
            else if _frameIndex == 0 {
                if _currentIndex > 0 {
                    if _currentIndex >= numberOfViews-3 {
                        _currentIndex = numberOfViews-3
                    }
                    
                    let viewToBeReused = _frameViews[2]
                    moveFrame(fromPosition: 1, toPosition: 2)
                    moveFrame(fromPosition: 0, toPosition: 1)
                    setView(viewForIndex(_nextCalculatedPageIndex, viewToBeReused), toFrameAtIndex: 0)
                    moveToFrame(1)
                }
                
                bounces = _currentIndex == 0
            }
            
            _lastFrameIndex = _frameIndex
            pagerDelegate?.pageChanged(page: _currentIndex)
        }
        
        if !_isPageChanged && _frameIndex > 0 && _frameIndex < 2 && numberOfViews > 2 {
            bounces = false
        }
        else if _isPageChanged && (_frameIndex == 0 || _frameIndex == _maxFrameNumber) {
            bounces = true
        }
    }
}

// MARK: Observers
extension SMPager {
    @objc fileprivate func orientationChanged(_ notification: Notification) {
        if (_lastComponentSize != bounds.size) {
            reloadData()
        }
        _lastComponentSize = bounds.size
    }
}
