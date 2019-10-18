
# SMPager
**SMPager** or SimplePager is a lightweight, memory-efficient implementation of UIScrollView written in Swift. It works with reusable views the same way as UIKit's  UITableView does.

---
![enter image description here](https://media.giphy.com/media/H7xeUycyRfgphI7sjZ/giphy.gif)
 
 ## Features
 
 - Renders any type of UIView. (UIImageView, UILabel, UIViewController view, etc.)
 - Uses the least amount of memory required to render the views.
 - Supports infinite scrolling.
 - Populates your UIViews using delegation.

 ## Installation
 SMPager is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:


 ```ruby
 pod 'SMPager'
 ```

## Example
In your ViewController initialize and add the pager to the superview.
```swift
import SMPager

class ViewController {
    let imageURLs = [
      "https://picsum.photos/id/177/500/900",
      "https://picsum.photos/id/886/500/900",
      "https://picsum.photos/id/362/500/900",
      "https://picsum.photos/id/569/500/900",
    ]

    lazy var pager: SMPager = {
        let pager = SMPager()
        pager.pagerDataSource = self
        pager.pagerDelegate = self
        pager.infiniteScrollingEnabled = true
        return pager
    }()

    func setupConstraints() {
        pager.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pager.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            pager.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            pager.topAnchor.constraint(equalTo: navBar.bottomAnchor),
            pager.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
    }
    
    // MARK: View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(pager)
        setupConstraints()
    }
}

```

Implement the SMPagerDelegate and SMPagerDataSource 
```swift
// MARK: SMPagerDelegate
extension ViewController: SMPagerDelegate {
    func pageChanged(page: Int) {
        pageControl.currentPage = page
    }
}

// MARK: SMPagerDataSource
extension ViewController: SMPagerDataSource {
    func numberOfViews() -> Int {
        return imageURLs.count
    }
    
    func viewForIndex(_ index: Int, reuseView: UIView?) -> UIView {
        let imageView: UIImageView
        if let reuseView = reuseView as? UIImageView {
            imageView = reuseView
        } else {
            imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
        }
        
        if let imageUrl = URL(string: imageURLs[index]) {
            imageView.kf.setImage(with: imageUrl)
        }
        
        return imageView
    }
}
```
## Documentation
### Properties
```swift
// Enables/disables the infinite scrolling mode. You can set this variable anytime without the need to call reloadData(). Default value is false.
var infiniteScrollingEnabled: Bool 
// Set the SMPagerDelegate. (see bellow)
var pagerDelegate: SMPagerDelegate?
// Set the SMPagerDataSource. (see bellow)
var pagerDataSource: SMPagerDataSource?
```
### Methods
```swift
// Moves to previous or next page. You can pass a boolean value if you want the transition between pages to be animated (default value is true).
func moveToPreviousPage(animated: Bool = true)
func moveToNextPage(animated: Bool = true)

// Moves to a specific page without animation.
func move(to page: Int)

// Reloads all the pager views.
func reloadData()
```

### SMPagerDelegate methods

```swift
// Called when a page is changed.
func pageChanged(page: Int)
```
### SMPagerDataSource methods

```swift
// Return the number of views to be rendered.
func numberOfViews() -> Int
// Return the view to be rendered for a specific index. reusedView is passed if it's available.
func viewForIndex(_ index: Int, reusedView: UIView?) -> UIView
```

## Author
Bill Panagiotopoulos, billp.dev@gmail.com

## License
SMPager is available under the MIT license. See the LICENSE file for more info.
