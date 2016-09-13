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
	case musicBarHeight = 40
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

	fileprivate(set) weak var target: SSMusicBarShowableProtocol?

	deinit { unregisterMonitor() }

	init(object: SSMusicBarShowableProtocol) {
		target = object
		setPopupItemButtons()
	}

	var canShowMusicBar = false {
		didSet { canShowMusicBar ? setup() : unregisterMonitor() }
	}

	fileprivate(set) lazy var musicBar: SSMusicBar = SSMusicBar()

	fileprivate(set) weak var tabBar: UITabBar?
	fileprivate lazy var tabBarInSameView = false

	fileprivate var delegate: SSAnimationDelegate?

	fileprivate var Notifier: NotificationCenter { return NotificationCenter.default }

	// MARK:- Private

	fileprivate func unregisterMonitor() {
		musicBar.removeConstraints(musicBar.constraints)
		var frame = musicBar.frame
		frame.origin.y += frame.size.height
		musicBar.frame = frame
		Notifier.removeObserver(self)
	}

	fileprivate func setup() {
		addObserver()
		setupDelegate()
	}

	fileprivate func addObserver() {
		guard let requester = target else { return }

		target?.initConfigurationForMusicBar(musicBar)

		var ss_playing = false

		if (requester.playerPlayingState == .playing || requester.playerPlayingState == .buffering) && requester.playerPlayingId != nil {
			showMusicBar()
		}

		defaultMusicBarInfo()
		Notifier.addObserver(forName: NSNotification.Name(rawValue: requester.playerIndexDidChangeKey), object: nil, queue: nil) { [weak self](_) -> Void in
			if UIApplication.shared.applicationState == .background { return }
			self?.defaultMusicBarInfo()
		}

		Notifier.addObserver(forName: NSNotification.Name(rawValue: requester.playerPlayingInfoUpateKey), object: nil, queue: OperationQueue.main) { [weak self](_) in
			if UIApplication.shared.applicationState == .background { return }
			self?.defaultMusicBarInfo()
		}

		Notifier.addObserver(forName: NSNotification.Name.UIApplicationDidBecomeActive, object: nil, queue: OperationQueue.main) { [weak self](_) in
			self?.defaultMusicBarInfo()
			// 修复被中断之后回来的状态不对的问题
			let playing = self?.target?.playerPlayingState == .playing
			ss_playing = playing
			DispatchQueue.main.async(execute: { () -> Void in
				self?.resetMusicBarButtonForPlaying(playing)
			})
		}

		Notifier.addObserver(forName: NSNotification.Name(rawValue: requester.playerProgressChangeKey), object: nil, queue: nil) { [weak self](note) -> Void in
			guard let sself = self else { return }
			if UIApplication.shared.applicationState == .background { return }
			sself.showMusicBar()
			if let value = note.object as? Float {
				let val = value.isNaN ? 0 : value
				sself.updateMusicBar(progress: val)
			}
			let playing = sself.target?.playerPlayingState == .playing
			if ss_playing != playing {
				ss_playing = playing
				DispatchQueue.main.async(execute: { () -> Void in
					self?.resetMusicBarButtonForPlaying(playing)
				})
			}
		}

		Notifier.addObserver(forName: NSNotification.Name(rawValue: requester.playerPlayingStateChangeKey), object: nil, queue: nil) { [weak self](note) -> Void in
			guard let sself = self else { return }
			if UIApplication.shared.applicationState == .background { return }
			if !sself.musicBar.visible { return }
			if let playing = note.object as? Bool {
				ss_playing = playing
				DispatchQueue.main.async(execute: { () -> Void in
					self?.resetMusicBarButtonForPlaying(playing)
				})
			}
		}
	}

	fileprivate func setupDelegate() {
		if let requester = self.target {

			if let tabBarController = target?.playerShowsInController as? UITabBarController {
				tabBar = tabBarController.tabBar
				tabBarInSameView = true
			}
			func loopParentVC(_ vc: UIViewController?) {
				guard let parentVC = vc?.parent else { return }
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
				y = bar.frame.height
			}
			delegate = SSAnimationDelegate(target: target, drag: musicBar, initialY: y, tabBar: tabBar)
		}
	}

	fileprivate func showMusicBar() {
		if !canShowMusicBar { return }
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [weak self]() -> Void in
			self?.execute()
		}
	}

	fileprivate func execute() {
		if musicBar.superview != nil { return }
		guard let viewController = target?.playerShowsInController else { return }
		let contentView: UIView? = viewController.view

		let h = UIScreen.main.bounds.height
		let w = UIScreen.main.bounds.width

		musicBar.frame = CGRect(x: 0, y: h, width: w, height: SSMusicBarConstant.musicBarHeight.rawValue)
		if let bar = tabBar {
			contentView?.insertSubview(musicBar, belowSubview: bar)
		} else {
			contentView?.addSubview(musicBar)
		}
		musicBar.translatesAutoresizingMaskIntoConstraints = false
		contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[musicBar]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar]))
		let height = SSMusicBarConstant.musicBarHeight.rawValue
		if let bar = tabBar {
			if tabBarInSameView {
				let constraint = NSLayoutConstraint.constraints(withVisualFormat: "V:[musicBar(\(height))]-0-[bar]", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar, "bar": bar])
				contentView?.addConstraints(constraint)
			} else {
				let constraint = NSLayoutConstraint.constraints(withVisualFormat: "V:[musicBar(\(height))]-\(bar.frame.size.height)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar])
				contentView?.addConstraints(constraint)
			}
		} else {
			contentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[musicBar(\(height))]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["musicBar": musicBar]))
		}

		UIView.animate(withDuration: 0.2,
			delay: 0,
			usingSpringWithDamping: 0.8,
			initialSpringVelocity: 10,
			options: UIViewAnimationOptions.curveEaseIn,
			animations: { contentView?.layoutIfNeeded() },
			completion: nil)
	}

	fileprivate func defaultMusicBarInfo() {
		let song = target?.playerCurrentSongName
		let artist = target?.playerCurrentSongArtistName
		let progress = target?.playerCurrentSongProgress
		updateMusicBar((song, artist), progress: progress)
	}

	fileprivate func updateMusicBar(_ info: (songName: String?, artist: String?)? = nil, progress: Float?) {
		DispatchQueue.main.async(execute: { () -> Void in
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

	fileprivate func setPopupItemButtons() {

		musicBar.leftButton.addTarget(self, action: #selector(MusicBarManager.toggle(_:)), for: .touchUpInside)

		musicBar.rightButton.addTarget(self, action: #selector(MusicBarManager.more), for: .touchUpInside)

		DispatchQueue.main.async(execute: { () -> Void in
			self.musicBar.leftButton.setImage(self.target?.playerControlPauseImage, for: .selected)
			self.musicBar.leftButton.setImage(self.target?.playerControlPlayImage, for: UIControlState())
			self.musicBar.rightButton.setImage(self.target?.playerControlMoreImage, for: UIControlState())
		})
	}

	fileprivate func resetMusicBarButtonForPlaying(_ isPlaying: Bool = true) {
		DispatchQueue.main.async(execute: { () -> Void in
			self.musicBar.leftButton.isSelected = isPlaying
		})
	}

	@objc fileprivate func toggle(_ button: UIButton) {
		var name = MusicBarControlsEvent.Play.rawValue
		if button.isSelected {
			name = MusicBarControlsEvent.Pause.rawValue
		}
		Notifier.post(name: Notification.Name(rawValue: name), object: nil)
		button.isSelected = !button.isSelected
	}

	@objc fileprivate func more() {
		Notifier.post(name: Notification.Name(rawValue: MusicBarControlsEvent.More.rawValue), object: nil)
	}
}
//MARK:- PlayerStatus
public enum PlayerStatus: UInt {
	case playing, paused, idle, finished, buffering, error
}
//MARK:- SSMusicDetailViewProtocol
public protocol SSMusicDetailViewProtocol {
	var controller: UIViewController { get }
	var dimissDone: ()->() { get }
	init()
}

//MARK:- SSMusicBarShowableProtocol
public protocol SSMusicBarShowableProtocol: class {

	var playerIndexDidChangeKey: String { get }
	var playerProgressChangeKey: String { get }
	var playerPlayingStateChangeKey: String { get }
	var playerPlayingInfoUpateKey: String { get }
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
	func initConfigurationForMusicBar(_ bar: SSMusicBar)
}

//MARK:- Extension SSMusicBarShowableProtocol
public extension SSMusicBarShowableProtocol {

	fileprivate var manager: MusicBarManager {
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
