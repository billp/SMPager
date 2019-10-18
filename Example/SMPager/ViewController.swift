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

    let imageURLs = [
      "https://picsum.photos/id/177/500/900",
      "https://picsum.photos/id/886/500/900",
      "https://picsum.photos/id/362/500/900",
      "https://picsum.photos/id/569/500/900",
      "https://picsum.photos/id/758/500/900",
      "https://picsum.photos/id/704/500/900",
      "https://picsum.photos/id/294/500/900",
      "https://picsum.photos/id/507/500/900",
      "https://picsum.photos/id/596/500/900",
      "https://picsum.photos/id/930/500/900",
    ]
    
    lazy var pager: SMPager = {
        let pager = SMPager()
        pager.pagerDataSource = self
        pager.pagerDelegate = self
        pager.infiniteScrollingEnabled = false
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        view.addSubview(pager)
        setupConstraints()
        view.bringSubviewToFront(pageControl)
        
        pageControl.numberOfPages = imageURLs.count
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController {
    @IBAction func previousAction(_ sender: Any) {
        pager.moveToPreviousPage()
    }
    @IBAction func nextAction(_ sender: Any) {
        pager.moveToNextPage()
    }
}

extension ViewController: SMPagerDelegate {
    func pageChanged(page: Int) {
        pageControl.currentPage = page
    }
}

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
