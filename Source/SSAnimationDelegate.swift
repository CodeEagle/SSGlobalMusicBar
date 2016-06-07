//
//  SSAnimationDelegate.swift
//  Pods
//
//  Created by LawLincoln on 16/4/20.
//
//

import UIKit

//MARK:- SSAnimationDelegate
final class SSAnimationDelegate: NSObject {

	private var _detailViewController: UIViewController?
	private var _presentInteractor: SSDragInteractiveTransition?
	private var _dismissInteractor: SSDragInteractiveTransition?

	private weak var _target: SSMusicBarShowableProtocol?
	private weak var _commonView: SSMusicBar!
	private weak var _tabBar: UITabBar!

	private lazy var _manualPrsenting = false
	private lazy var _initialY: CGFloat = 0

	private var _disableInteractivePlayerTransitioning: Bool {
		let a = _presentInteractor?.transitioning ?? false
		let b = _dismissInteractor?.transitioning ?? false
		return a || b
	}

	deinit { NSNotificationCenter.defaultCenter().removeObserver(self) }

	init(target: SSMusicBarShowableProtocol?, drag view: SSMusicBar, initialY: CGFloat, tabBar: UITabBar?) {
		super.init()
		_target = target
		_commonView = view
		_commonView.tapBlock = { [weak self] in
			self?.showDetail()
		}
		_tabBar = tabBar
		_initialY = initialY
		confgurePresentInteractor()
		NSNotificationCenter.defaultCenter().addObserverForName(MusicBarControlsEvent.ManualDismiss.rawValue, object: nil, queue: NSOperationQueue.mainQueue()) { [weak self](_) in
			self?.dismissDetail()
		}
	}

	private func confgurePresentInteractor() {
		guard let value = _target else { return }
		_presentInteractor = SSDragInteractiveTransition(Drag: _commonView, type: .Present, viewController: value.playerShowsInController, musicBar: _commonView)
		_presentInteractor?.configureToPresentControllerWhenNeeds = {
			[weak self]() -> UIViewController? in
			guard let sself = self else { return nil }
			let detail = sself._target?.playerDetailViewController
			sself.configureDetail(detail)
			return sself._detailViewController
		}
		_presentInteractor?.doneOrCancelClosure = {
			[weak self] in
			self?._detailViewController = nil
		}
	}

	private func configureDismiss() -> SSDragInteractiveTransition? {
		guard let detail = _detailViewController else { return nil }
		let dismissInteractor = SSDragInteractiveTransition(Drag: detail.view, type: .Dismiss, viewController: detail, musicBar: _commonView)
		dismissInteractor.doneOrCancelClosure = {
			[weak self] in
			self?._detailViewController = nil
		}
		return dismissInteractor
	}

	private func configureDetail(vc: UIViewController?) {
		_detailViewController = vc
		_detailViewController?.transitioningDelegate = self
		_detailViewController?.modalPresentationStyle = .FullScreen
	}

	private func showDetail() {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
			guard let next = self._target?.playerDetailViewController else { return }
			self._manualPrsenting = true
			self.configureDetail(next)
			self._dismissInteractor = self.configureDismiss()
			dispatch_async(dispatch_get_main_queue(), { () -> Void in
				self._target?.playerShowsInController.presentViewController(next, animated: true, completion: {
					[weak self] in
					self?._detailViewController = nil
					self?._manualPrsenting = false
				})
			})
		})
	}

	private func dismissDetail() {
		_dismissInteractor?.dismissDetail()
	}
}
extension SSAnimationDelegate: UIViewControllerTransitioningDelegate {

	// MARK: Dismiss
	func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SSDragAnimator(type: .Dismiss, iitialY: _initialY, commonView: _commonView, tabBar: _tabBar)
	}

	func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		if _disableInteractivePlayerTransitioning { return nil }
		return _dismissInteractor
	}

	// MARK: Present
	func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SSDragAnimator(type: .Present, iitialY: _initialY, commonView: _commonView, tabBar: _tabBar)
	}

	func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		if _disableInteractivePlayerTransitioning || _manualPrsenting { return nil }
		_dismissInteractor = configureDismiss()
		return _presentInteractor
	}
}