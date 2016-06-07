//
//  SSDragInteractiveTransition.swift
//  Pods
//
//  Created by LawLincoln on 16/4/20.
//
//

import UIKit

final class SSDragInteractiveTransition: UIPercentDrivenInteractiveTransition {

	var configureToPresentControllerWhenNeeds: (() -> UIViewController?)?
	var doneOrCancelClosure: dispatch_block_t?

	lazy var transitioning = false

	private weak var _toPresentController: UIViewController?
	private weak var _viewController: UIViewController?
	private weak var _musicBar: SSMusicBar?
	private var _type: ModalAnimatedTransitioningType

	private lazy var _shouldDismiss = false
	private lazy var _shouldComplete = false

	init(Drag view: UIView, type: ModalAnimatedTransitioningType, viewController: UIViewController?, musicBar: SSMusicBar?) {
		_type = type
		super.init()
		_viewController = viewController
		_musicBar = musicBar
		let pan = UIPanGestureRecognizer(target: self, action: #selector(SSDragInteractiveTransition.onPan(_:)))
		view.addGestureRecognizer(pan)
		completionCurve = .EaseInOut
	}

	@objc private func onPan(pan: UIPanGestureRecognizer) {
		let translation: CGPoint = pan.translationInView(pan.view?.superview)
		let velocity: CGPoint = pan.velocityInView(pan.view?.superview)
		switch pan.state {
		case .Began:
			_musicBar?.visible = false
			if _type == .Dismiss {
				_shouldDismiss = velocity.y > 0
				if !_shouldDismiss { return }
				completionCurve = .EaseOut
				_viewController?.dismissViewControllerAnimated(true, completion: nil)
			} else {
				if _toPresentController == nil {
					_toPresentController = configureToPresentControllerWhenNeeds?()
				}
				guard let value = _toPresentController else { return }
				completionCurve = .EaseIn
				_viewController?.showDetailViewController(value, sender: nil)
			}
		case .Changed:
			if !_shouldDismiss && _type == .Dismiss { return }
			transitioning = true
			let screenHeight: CGFloat = UIScreen.mainScreen().bounds.size.height - 50.0
			let DragAmount: CGFloat = _toPresentController == nil ? screenHeight : -screenHeight
			let Threshold: CGFloat = 0.3
			var percent: CGFloat = translation.y / DragAmount
			percent = fmax(percent, 0.0)
			percent = fmin(percent, 1.0)
			updateInteractiveTransition(percent)
			_shouldComplete = percent > Threshold

		case .Cancelled, .Ended:
			if !_shouldDismiss && _type == .Dismiss { return }
			completionSpeed = 1 - percentComplete
			if pan.state == .Cancelled || !_shouldComplete {
				cancelInteractiveTransition()
				if _type == .Present {
					_musicBar?.visible = true
					doneOrCancelClosure?()
				}
			} else {
				finishInteractiveTransition()
				if _type == .Dismiss {
					_musicBar?.visible = true
					doneOrCancelClosure?()
				}
			}
			transitioning = false
		default: break
		}
	}

	func dismissDetail() {
//		if _type == .Present { return }
		_viewController?.dismissViewControllerAnimated(true, completion: nil)
		updateInteractiveTransition(0.8)
		finishInteractiveTransition()
	}
}
