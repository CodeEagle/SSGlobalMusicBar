//
//  UIViewController+SSMusicBar.swift
//  Pods
//
//  Created by LawLincoln on 16/4/20.
//
//

import UIKit
//MARK:- Constant
public enum SSMusicBarConstant: CGFloat {
	case MusicBarHeight = 40
}
//MARK:- MusicBarControlsEvent
public enum MusicBarControlsEvent: String {
	case Play = "Play"
	case Pause = "Pause"
	case More = "More"
	case ManualDismiss = "ManualDismiss"
}
//MARK:- MusicBarManager
private final class MusicBarManager {

	private(set) weak var target: SSMusicBarShowableProtocol?

	deinit { unregisterMonitor() }

	init(object: SSMusicBarShowableProtocol) {
		target = object
		setPopupItemButtons()
	}

	var canShowMusicBar = false {
		didSet { canShowMusicBar ? setup() : unregisterMonitor() }
	}

	private(set) lazy var musicBar: SSMusicBar = SSMusicBar()

	private(set) weak var tabBar: UITabBar?
	private lazy var tabBarInSameView = false

	private var delegate: SSAnimationDelegate?

	private var Notifier: NSNotificationCenter { return NSNotificationCenter.defaultCenter() }

	// MARK:- Private

	private func unregisterMonitor() {
		musicBar.removeConstraints(musicBar.constraints)
		var frame = musicBar.frame
		frame.origin.y += frame.size.height
		musicBar.frame = frame
		Notifier.removeObserver(self)
	}

	private func setup() {
		addObserver()
		setupDelegate()
	}

	private func addObserver() {
		guard let requester = target else { return }

		target?.initConfigurationForMusicBar(musicBar)

		var ss_playing = false

		if (requester.playerPlayingState == .Playing || requester.playerPlayingState == .Buffering) && requester.playerPlayingId != nil {
			showMusicBar()
		}

		defaultMusicBarInfo()
		Notifier.addObserverForName(requester.playerIndexDidChangeKey, object: nil, queue: nil) { [weak self](_) -> Void in
			if UIApplication.sharedApplication().applicationState == .Background { return }
			self?.defaultMusicBarInfo()
		}

		Notifier.addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self](_) in
			self?.defaultMusicBarInfo()
			// 修复被中断之后回来的状态不对的问题
			let playing = self?.target?.playerPlayingState == .Playing
			ss_playing = playing
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self?.resetMusicBarButtonForPlaying(playing)
			})
		}

		Notifier.addObserverForName(requester.playerProgressChangeKey, object: nil, queue: nil) { [weak self](note) -> Void in
			guard let sself = self else { return }
			if UIApplication.sharedApplication().applicationState == .Background { return }
			sself.showMusicBar()
			if let value = note.object as? Float {
				let val = value.isNaN ? 0 : value
				sself.updateMusicBar(progress: val)
			}
			let playing = sself.target?.playerPlayingState == .Playing
			if ss_playing != playing {
				ss_playing = playing
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					self?.resetMusicBarButtonForPlaying(playing)
				})
			}
		}

		Notifier.addObserverForName(requester.playerPlayingStateChangeKey, object: nil, queue: nil) { [weak self](note) -> Void in
			guard let sself = self else { return }
			if UIApplication.sharedApplication().applicationState == .Background { return }
			if !sself.musicBar.visible { return }
			if let playing = note.object as? Bool {
				ss_playing = playing
				dispatch_async(dispatch_get_main_queue(), { () -> Void in
					self?.resetMusicBarButtonForPlaying(playing)
				})
			}
		}
	}

	private func setupDelegate() {
		if let requester = self.target {

			if let tabBarController = target?.playerShowsInController as? UITabBarController {
				tabBar = tabBarController.tabBar
				tabBarInSameView = true
			}
			func loopParentVC(vc: UIViewController?) {
				guard let parentVC = vc?.parentViewController else { return }
				if tabBar == nil {
					if let tabBarController = parentVC as? UITabBarController {
						tabBar = tabBarController.tabBar
					} else {
						loopParentVC(parentVC)
					}
				}
			}
			loopParentVC(target?.playerShowsInController)
			var y: CGFloat = 0
			if let bar = tabBar {
				y = CGRectGetHeight(bar.frame)
			}
			delegate = SSAnimationDelegate(target: target, drag: musicBar, initialY: y, tabBar: tabBar)
		}
	}

	private func showMusicBar() {
		if !canShowMusicBar { return }
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self]() -> Void in
			self?.execute()
		}
	}

	private func execute() {
		if musicBar.superview != nil { return }
		guard let viewController = target?.playerShowsInController else { return }
		let contentView: UIView? = viewController.view

		let h = UIScreen.mainScreen().bounds.height
		let w = UIScreen.mainScreen().bounds.width

		musicBar.frame = CGRectMake(0, h, w, SSMusicBarConstant.MusicBarHeight.rawValue)
		if let bar = tabBar {
			contentView?.insertSubview(musicBar, belowSubview: bar)
		} else {
			contentView?.addSubview(musicBar)
		}
		musicBar.translatesAutoresizingMaskIntoConstraints = false
		contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[musicBar]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar]))
		let height = SSMusicBarConstant.MusicBarHeight.rawValue
		if let bar = tabBar {
			if tabBarInSameView {
				let constraint = NSLayoutConstraint.constraintsWithVisualFormat("V:[musicBar(\(height))]-0-[bar]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar, "bar": bar])
				contentView?.addConstraints(constraint)
			} else {
				let constraint = NSLayoutConstraint.constraintsWithVisualFormat("V:[musicBar(\(height))]-\(bar.frame.size.height)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar])
				contentView?.addConstraints(constraint)
			}
		} else {
			contentView?.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[musicBar(\(height))]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar]))
		}

		UIView.animateWithDuration(0.2,
			delay: 0,
			usingSpringWithDamping: 0.8,
			initialSpringVelocity: 10,
			options: UIViewAnimationOptions.CurveEaseIn,
			animations: { contentView?.layoutIfNeeded() },
			completion: nil)
	}

	private func defaultMusicBarInfo() {
		let song = target?.playerCurrentSongName
		let artist = target?.playerCurrentSongArtistName
		let progress = target?.playerCurrentSongProgress
		updateMusicBar((song, artist), progress: progress)
	}

	private func updateMusicBar(info: (songName: String?, artist: String?)? = nil, progress: Float?) {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			if let value = info {
				self.musicBar.title = value.songName ?? ""
				self.musicBar.subtitle = value.artist ?? ""
			}
			if let p = progress {
				let value = p.isNaN ? 0 : p
				self.musicBar.progressView.progress = value
			}
		})
	}

	private func setPopupItemButtons() {

		musicBar.leftButton.addTarget(self, action: #selector(MusicBarManager.toggle(_:)), forControlEvents: .TouchUpInside)

		musicBar.rightButton.addTarget(self, action: #selector(MusicBarManager.more), forControlEvents: .TouchUpInside)

		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.musicBar.leftButton.setImage(self.target?.playerControlPauseImage, forState: .Selected)
			self.musicBar.leftButton.setImage(self.target?.playerControlPlayImage, forState: .Normal)
			self.musicBar.rightButton.setImage(self.target?.playerControlMoreImage, forState: .Normal)
		})
	}

	private func resetMusicBarButtonForPlaying(isPlaying: Bool = true) {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			self.musicBar.leftButton.selected = isPlaying
		})
	}

	@objc private func toggle(button: UIButton) {
		var name = MusicBarControlsEvent.Play.rawValue
		if button.selected {
			name = MusicBarControlsEvent.Pause.rawValue
		}
		Notifier.postNotificationName(name, object: nil)
		button.selected = !button.selected
	}

	@objc private func more() {
		Notifier.postNotificationName(MusicBarControlsEvent.More.rawValue, object: nil)
	}
}
//MARK:- PlayerStatus
public enum PlayerStatus: UInt {
	case Playing, Paused, Idle, Finished, Buffering, Error
}
//MARK:- SSMusicDetailViewProtocol
public protocol SSMusicDetailViewProtocol {
	var controller: UIViewController { get }
	var dimissDone: dispatch_block_t { get }
	init()
}

//MARK:- SSMusicBarShowableProtocol
public protocol SSMusicBarShowableProtocol: class {

	var playerIndexDidChangeKey: String { get }
	var playerProgressChangeKey: String { get }
	var playerPlayingStateChangeKey: String { get }
	var playerPlayingState: PlayerStatus { get }
	var playerPlayingId: String? { get }
	var playerPlayingIndex: Int { get }
	var playerCurrentSongName: String { get }
	var playerCurrentSongArtistName: String { get }
	var playerCurrentSongProgress: Float { get }
	var playerControlPlayImage: UIImage? { get }
	var playerControlPauseImage: UIImage? { get }
	var playerControlMoreImage: UIImage? { get }
	var playerShowsInController: UIViewController { get }
	var playerDetailViewController: UIViewController { get }
	func initConfigurationForMusicBar(bar: SSMusicBar)
}

//MARK:- Extension SSMusicBarShowableProtocol
public extension SSMusicBarShowableProtocol {

	private var manager: MusicBarManager {
		get {
			let man = MusicBarManager(object: self)
			if let value = objc_getAssociatedObject(self, &AssociatedKeys.MusicBarManager) as? MusicBarManager {
				return value
			}
			objc_setAssociatedObject(self, &AssociatedKeys.MusicBarManager, man, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return man
		}
		set(val) { objc_setAssociatedObject(self, &AssociatedKeys.MusicBarManager, val, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}

	public var ss_enableShowMusicBar: Bool {
		get { return manager.canShowMusicBar }
		set(show) { manager.canShowMusicBar = show }
	}

	public var ss_musicBar: SSMusicBar { return manager.musicBar }
	public var ss_tabBar: UITabBar? { return manager.tabBar }
}

private struct AssociatedKeys {
	static var MusicBarManager = "MusicBarManager"
}
