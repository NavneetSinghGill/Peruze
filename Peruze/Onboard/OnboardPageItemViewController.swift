//
//  OnboardPageItemViewController.swift
//  Peruse
//
//  Created by Phillip Trent on 5/23/15.
//  Copyright (c) 2015 Phillip Trent. All rights reserved.
//

import UIKit
import AVFoundation

class OnboardPageItemViewController: UIViewController {
  
  private struct Constants {
    static let PlayerVCTitleName = "PlayerController"
  }
  
  // MARK: - Variables
  // MARK: Outlets
  @IBOutlet var contentImageView: UIImageView?
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var captionLabel: UILabel!
  @IBOutlet weak var playerView: UIView!
  // MARK: Local
  private var player: AVPlayer?
  private var playerLayer: AVPlayerLayer?
  var itemIndex = 0
  var movieName: String?
  var titleText = "" { didSet { if let tLabel = titleLabel { tLabel.text = titleText } } }
  var captionText = "" { didSet { if let cLabel = captionLabel { cLabel.text = captionText } } }
  var imageName = "" {
    didSet {
      if let imageView = contentImageView {
        imageView.image = ((imageName == "") ? nil : UIImage(named: imageName))
      }
    }
  }
  
  // MARK: - View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    if movieName != nil { setupPlayer() }
    contentImageView!.image = UIImage(named: imageName)
    titleLabel.text = titleText
    captionLabel.text = captionText
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let pLayer = playerLayer {
      if pLayer.superlayer != nil {
        pLayer.removeFromSuperlayer()
      }
      pLayer.frame = CGRectMake(0, 0, playerView.frame.width, playerView.frame.height)
      playerView.layer.addSublayer(pLayer)
    }
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    playerView.alpha = 0.0
    player?.seekToTime(CMTimeMakeWithSeconds(0, 5))
    player?.play()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    if movieName != nil {
      UIView.animateWithDuration(1, delay: 0.1, options: nil,
        animations: { self.playerView.alpha = 1.0 }, completion: nil)
    }
  }
  
  // MARK: - Setup
  private func setupPlayer() {
    //create the player
    let moviePath = NSBundle.mainBundle().pathForResource(movieName!, ofType: "m4v")
    let movieURL = NSURL(fileURLWithPath: moviePath!)
    player = AVPlayer(URL: movieURL)
    playerLayer = AVPlayerLayer(player: player)
    playerLayer!.backgroundColor = UIColor.clearColor().CGColor
  }
}
