# SMPager
**SMPager** or SimplePager is a lightweight, memory-efficient implementation of UIScrollView written in Swift, that works with reusable views the same way as UIKit's  UITableView implementation does.
![enter image description here](https://media.giphy.com/media/H7xeUycyRfgphI7sjZ/giphy.gif)
 
 ## Features
 
 - Renders any type of UIView. (UIImageView, UILabel, UIViewController views etc.)
 - Uses the least amount of memory required to render the views.
 - Supports infinite scrolling.
 - Populates your Views using delegation.

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

Implement the delegate methods of the SMPager
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

## Installation
SMPager is available through [CocoaPods](https://cocoapods.org). To install it, simply add the following line to your Podfile:


```ruby
pod 'SMPager'
```

## Author
Vasilis Panagiotopoulos, billp.dev@gmail.com

## License
SMPager is available under the MIT license. See the LICENSE file for more info.
