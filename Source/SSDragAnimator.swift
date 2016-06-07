//
//  SSDragAnimator.swift
//  Pods
//
//  Created by LawLincoln on 16/4/20.
//
//

import UIKit

//MARK:- ModalAnimatedTransitioningType
enum ModalAnimatedTransitioningType { case Present, Dismiss }

//MARK:- SSDragAnimator
final class SSDragAnimator: NSObject {

	private let AnimationDuration: NSTimeInterval = 0.4

	private let _type: ModalAnimatedTransitioningType
	private let _initialY: CGFloat
	private weak var _commonView: SSMusicBar?
	private weak var _tabBar: UITabBar?

	init(type: ModalAnimatedTransitioningType, iitialY: CGFloat, commonView: SSMusicBar, tabBar: UITabBar?) {
		_type = type
		_initialY = iitialY
		_commonView = commonView
		_tabBar = tabBar
		super.init()
	}
}
// MARK: - UIViewControllerAnimatedTransitioning
extension SSDragAnimator: UIViewControllerAnimatedTransitioning {

	func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
		return AnimationDuration
	}

	func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
		guard let to = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey),
			from = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) else { return }
		switch _type {
		case .Present: animatePresentingInContext(transitionContext, toVC: to, fromVC: from)
		case .Dismiss: animateDismissingInContext(transitionContext, toVC: to, fromVC: from)
		}
	}
}
//MARK:- private
private extension SSDragAnimator {

	func animatePresentingInContext(transitionContext: UIViewControllerContextTransitioning, toVC: UIViewController, fromVC: UIViewController) {

		let fromVCRect = transitionContext.initialFrameForViewController(fromVC)
		var toVCRect = fromVCRect
		toVCRect.origin.y = toVCRect.size.height - _initialY
		toVC.view.frame = toVCRect
		let container = transitionContext.containerView()
		let imageView = snapshotCommonView()
		toVC.view?.addSubview(imageView)
		container?.addSubview(fromVC.view)
		container?.addSubview(toVC.view)
		let v = snapshotTabbar()
		v?.alpha = 1
		if let tabbar = v {
			container?.addSubview(tabbar)
		}
		UIView.animateWithDuration(AnimationDuration, animations: { () -> Void in
			toVC.view.frame = fromVCRect
			imageView.alpha = 0.0
			v?.alpha = 0
			}, completion: { (finished: Bool) -> Void in
			imageView.removeFromSuperview()
			v?.removeFromSuperview()
			if transitionContext.transitionWasCancelled() {
				transitionContext.completeTransition(false)
			} else {
				transitionContext.completeTransition(true)
			}
		})
	}

	func animateDismissingInContext(transitionContext: UIViewControllerContextTransitioning, toVC: UIViewController, fromVC: UIViewController) {
		var fromVCRect: CGRect = transitionContext.initialFrameForViewController(fromVC)
		fromVCRect.origin.y = fromVCRect.size.height - _initialY
		let imageView = snapshotCommonView()
		fromVC.view?.addSubview(imageView)
		let container = transitionContext.containerView()
		container?.addSubview(toVC.view)
		container?.addSubview(fromVC.view)
		imageView.alpha = 0.0
		let v = snapshotTabbar()
		v?.alpha = 0
		if let tabbar = v {
			container?.addSubview(tabbar)
		}

		UIView.animateWithDuration(AnimationDuration, animations: { () -> Void in
			fromVC.view.frame = fromVCRect
			imageView.alpha = 1
			v?.alpha = 1
			}, completion: { (finished: Bool) -> Void in
			imageView.removeFromSuperview()
			v?.removeFromSuperview()
			if transitionContext.transitionWasCancelled() {
				transitionContext.completeTransition(false)
				toVC.view?.removeFromSuperview()
			} else {
				transitionContext.completeTransition(true)
			}
		})
	}

	func snapshotCommonView() -> UIView {
		guard let value = _commonView else { return UIView() }
		let h = value.frame.height
		let imageView = UIImageView(frame: CGRectMake(0, -h, value.frame.width, h))
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			guard let image = self._commonView?.snapShot() else { return }
			imageView.image = image
		})
		return imageView
	}

	func snapshotTabbar() -> UIView? {
		guard let value = _tabBar else { return nil }
		let h = value.frame.height
		let y = UIScreen.mainScreen().bounds.height - h
		let imageView = UIImageView(frame: CGRectMake(0, y, value.frame.width, h))
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			let image = value.snapShot()
			imageView.image = image
		})
		return imageView
	}
}

extension UIView {

	func snapShot() -> UIImage {
		UIGraphicsBeginImageContextWithOptions(bounds.size, opaque, 0)
		layer.renderInContext(UIGraphicsGetCurrentContext()!)
		let snap = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return snap
	}
}
