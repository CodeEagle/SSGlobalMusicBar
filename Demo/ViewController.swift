//
//  ViewController.swift
//  Demo
//
//  Created by LawLincoln on 16/8/5.
//  Copyright © 2016年 CocoaPods. All rights reserved.
//

import UIKit
import SSGlobalMusicBar

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		ss_enableShowMusicBar = true
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

}

extension ViewController: SSMusicBarShowableProtocol {
	var playerIndexDidChangeKey: String { return "a" }
	var playerProgressChangeKey: String { return "b" }
	var playerPlayingStateChangeKey: String { return "c" }
	var playerPlayingInfoUpateKey: String { return "d" }
	var playerPlayingState: PlayerStatus { return .Playing }
	var playerPlayingId: String? { return "1" }
	var playerPlayingIndex: Int { return 0 }
	var playerCurrentSongName: String { return "faceline" }
	var playerCurrentSongArtistName: String { return "胖虎乐队" }
	var playerCurrentSongProgress: Float { return 0.5 }
	var playerControlPlayImage: UIImage? { return nil }
	var playerControlPauseImage: UIImage? { return nil }
	var playerControlMoreImage: UIImage? { return nil }
	var playerShowsInController: UIViewController { return self }
	var playerDetailViewController: UIViewController {
		let vc = UIViewController(nibName: nil, bundle: nil)
		vc.view.backgroundColor = UIColor.whiteColor()
		return vc
	}
	func initConfigurationForMusicBar(bar: SSMusicBar) {

	}
}