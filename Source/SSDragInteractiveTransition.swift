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
	var doneOrCancelClosure: (() -> ())?

	lazy var transitioning = false

	fileprivate weak var _toPresentController: UIViewController?
	fileprivate weak var _viewController: UIViewController?
	fileprivate weak var _musicBar: SSMusicBar?
	fileprivate var _type: ModalAnimatedTransitioningType

	fileprivate lazy var _shouldDismiss = false
	fileprivate lazy var _shouldComplete = false

	init(Drag view: UIView, type: ModalAnimatedTransitioningType, viewController: UIViewController?, musicBar: SSMusicBar?) {
		_type = type
		super.init()
		_viewController = viewController
		_musicBar = musicBar
		let pan = UIPanGestureRecognizer(target: self, action: #selector(SSDragInteractiveTransition.onPan(_:)))
		view.addGestureRecognizer(pan)
		completionCurve = .easeInOut
	}

	@objc fileprivate func onPan(_ pan: UIPanGestureRecognizer) {
		let translation: CGPoint = pan.translation(in: pan.view?.superview)
		let velocity: CGPoint = pan.velocity(in: pan.view?.superview)
		switch pan.state {
		case .began:
			_musicBar?.visible = false
			if _type == .dismiss {
				_shouldDismiss = velocity.y > 0
				if !_shouldDismiss { return }
				completionCurve = .easeOut
				_viewController?.dismiss(animated: true, completion: nil)
			} else {
				if _toPresentController == nil {
					_toPresentController = configureToPresentControllerWhenNeeds?()
				}
				guard let value = _toPresentController else { return }
				completionCurve = .easeIn
				_viewController?.showDetailViewController(value, sender: nil)
			}
		case .changed:
			if !_shouldDismiss && _type == .dismiss { return }
			transitioning = true
			let screenHeight: CGFloat = UIScreen.main.bounds.size.height - 50.0
			let DragAmount: CGFloat = _toPresentController == nil ? screenHeight : -screenHeight
			let Threshold: CGFloat = 0.3
			var percent: CGFloat = translation.y / DragAmount
			percent = fmax(percent, 0.0)
			percent = fmin(percent, 1.0)
			update(percent)
			_shouldComplete = percent > Threshold

		case .cancelled, .ended:
			if !_shouldDismiss && _type == .dismiss { return }
			completionSpeed = 1 - percentComplete
			if pan.state == .cancelled || !_shouldComplete {
				cancel()
				if _type == .present {
					_musicBar?.visible = true
					doneOrCancelClosure?()
				}
			} else {
				finish()
				if _type == .dismiss {
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
		_viewController?.dismiss(animated: true, completion: nil)
		update(0.8)
		finish()
	}
}
