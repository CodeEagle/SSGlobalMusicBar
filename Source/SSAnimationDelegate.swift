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

	fileprivate var _detailViewController: UIViewController?
	fileprivate var _presentInteractor: SSDragInteractiveTransition?
	fileprivate var _dismissInteractor: SSDragInteractiveTransition?

	fileprivate weak var _target: SSMusicBarShowableProtocol?
	fileprivate weak var _commonView: SSMusicBar!
	fileprivate weak var _tabBar: UITabBar!

	fileprivate lazy var _manualPrsenting = false
	fileprivate lazy var _initialY: CGFloat = 0

	fileprivate var _disableInteractivePlayerTransitioning: Bool {
		let a = _presentInteractor?.transitioning ?? false
		let b = _dismissInteractor?.transitioning ?? false
		return a || b
	}

	deinit { NotificationCenter.default.removeObserver(self) }

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
		NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: MusicBarControlsEvent.ManualDismiss.rawValue), object: nil, queue: OperationQueue.main) { [weak self](_) in
			self?.dismissDetail()
		}
	}

	fileprivate func confgurePresentInteractor() {
		guard let value = _target else { return }
		_presentInteractor = SSDragInteractiveTransition(Drag: _commonView, type: .present, viewController: value.playerShowsInController, musicBar: _commonView)
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

	fileprivate func configureDismiss() -> SSDragInteractiveTransition? {
		guard let detail = _detailViewController else { return nil }
		let dismissInteractor = SSDragInteractiveTransition(Drag: detail.view, type: .dismiss, viewController: detail, musicBar: _commonView)
		dismissInteractor.doneOrCancelClosure = {
			[weak self] in
			self?._detailViewController = nil
		}
		return dismissInteractor
	}

	fileprivate func configureDetail(_ vc: UIViewController?) {
		_detailViewController = vc
		_detailViewController?.transitioningDelegate = self
		_detailViewController?.modalPresentationStyle = .fullScreen
	}

	fileprivate func showDetail() {
        
        
		DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: { () -> Void in
			guard let next = self._target?.playerDetailViewController else { return }
			self._manualPrsenting = true
			self.configureDetail(next)
			self._dismissInteractor = self.configureDismiss()
			DispatchQueue.main.async(execute: { () -> Void in
				self._target?.playerShowsInController.present(next, animated: true, completion: {
					[weak self] in
					self?._detailViewController = nil
					self?._manualPrsenting = false
				})
			})
		})
	}

	fileprivate func dismissDetail() {
		_dismissInteractor?.dismissDetail()
	}
}
extension SSAnimationDelegate: UIViewControllerTransitioningDelegate {

	// MARK: Dismiss
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SSDragAnimator(type: .dismiss, iitialY: self._initialY, commonView: self._commonView, tabBar: self._tabBar)
	}

	func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		if self._disableInteractivePlayerTransitioning { return nil }
		return self._dismissInteractor
	}

	// MARK: Present
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return SSDragAnimator(type: .present, iitialY: self._initialY, commonView: self._commonView, tabBar: self._tabBar)
	}

	func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
		if self._disableInteractivePlayerTransitioning || self._manualPrsenting { return nil }
		_dismissInteractor = configureDismiss()
		return self._presentInteractor
	}
}
