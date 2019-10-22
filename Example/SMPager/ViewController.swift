//
//  ViewController.swift
//  SMPager
//
//  Created by Vasilis Panagiotopoulos on 10/17/2019.
//  Copyright (c) 2019 Vasilis Panagiotopoulos. All rights reserved.
//

import UIKit
import SMPager
import Kingfisher

class ViewController: UIViewController {
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var infiniteBarButtonItem: UIBarButtonItem!
    
    let imageURLs = [
      "https://picsum.photos/id/177/500/900",
      "https://picsum.photos/id/886/500/900",
      "https://picsum.photos/id/362/500/900",
      "https://picsum.photos/id/569/500/900",
      "https://picsum.photos/id/432/500/900",
      "https://picsum.photos/id/289/500/900",
      "https://picsum.photos/id/834/500/900",
    ]
    
    lazy var pager: SMPager = {
        let pager = SMPager()
        pager.pagerDataSource = self
        pager.pagerDelegate = self
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
        // Do any additional setup after loading the view, typically from a nib.
        
        view.addSubview(pager)
        setupConstraints()
        view.bringSubviewToFront(pageControl)
        
        pageControl.numberOfPages = imageURLs.count
        infiniteBarButtonItem.customView?.isUserInteractionEnabled = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: Actions
extension ViewController {
    @IBAction func previousAction(_ sender: Any) {
        pager.moveToPreviousPage()
    }
    @IBAction func nextAction(_ sender: Any) {
        pager.moveToNextPage()
    }
    @IBAction func infiniteSwitchValueChanged(_ sender: UISwitch) {
        pager.infiniteScrollingEnabled = sender.isOn
    }
}

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
    
    func viewForIndex(_ index: Int, reusedView: UIView?) -> UIView {
        let imageView: UIImageView
        if let reusedView = reusedView as? UIImageView {
            imageView = reusedView
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
