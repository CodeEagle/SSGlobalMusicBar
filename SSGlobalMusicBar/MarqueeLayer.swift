//
//  MarqueeLayer.swift
//  LuooAudioPlayerController
//
//  Created by LawLincoln on 16/7/11.
//  Copyright © 2016年 SelfStudio. All rights reserved.
//

import UIKit

public final class MarqueeLayer: CALayer {

	private var animate = false
	var contentInset = UIEdgeInsetsZero
	private let text = CATextLayer()
	private var maxWidth: CGFloat = 0
	override init(layer: AnyObject) { super.init(layer: layer) }
	required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
	private var gMask = CAGradientLayer()
	init(max width: CGFloat) {
		super.init()
		maxWidth = width
		text.anchorPoint = CGPointZero
		masksToBounds = true
		contentsScale = UIScreen.mainScreen().scale
		text.contentsScale = contentsScale
		contentInset = UIEdgeInsetsMake(0, 4, 0, 4)

		gMask.colors = [UIColor.clearColor().CGColor, UIColor.whiteColor().CGColor, UIColor.whiteColor().CGColor, UIColor.clearColor().CGColor]
		gMask.locations = [0, 0.05, 0.95, 1]
		gMask.anchorPoint = CGPointZero
		gMask.startPoint = CGPointMake(0, 0.5)
		gMask.endPoint = CGPointMake(1, 0.5)
		addSublayer(text)
	}

	func update(string: NSAttributedString, y: CGFloat) {
		var rectValue = CGRectZero
		let size = CGSizeMake(9999, bounds.size.height + 20)
		let value = string.boundingRectWithSize(size, options: .UsesFontLeading, context: nil)
		var textRect = CGRectMake(
			0,
			contentInset.top,
			value.width,
			contentInset.top + value.height + contentInset.bottom)
		if maxWidth > value.width {
			rectValue = textRect
			mask = nil
		} else {
			mask = gMask
			textRect.origin.x = contentInset.left
			textRect.size.width += contentInset.right
			rectValue.size.height = textRect.height
			rectValue.size.width = maxWidth
		}
		if let sp = superlayer {
			rectValue = CGRectMake((sp.bounds.width - rectValue.width) / 2, y, rectValue.width, rectValue.height)
		}
		text.frame = textRect
		frame = rectValue
		text.string = string
		mask?.frame = bounds
		let start = CGPointMake(contentInset.left, 0)
		let end = CGPointMake(frame.width - CGRectGetMaxX(textRect), 0)
		let max = CGPointMake(maxWidth, CGRectGetHeight(rectValue))
		marquee(from: start, to: end, max: max)
	}

	private func marquee(from start: CGPoint, to end: CGPoint, max point: CGPoint) {
		removeAllAnimations()
		if end.x >= 0 || start == end {
			animate = false
			return
		}
		animate = true
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { [weak self] in
			if self?.animate == false { return }
			let speed: CGFloat = 10 // 10 point per second
			let duration: NSTimeInterval = {
				let xDuration = abs(end.x) / speed
				let yDuration = abs(end.y) / speed
				return NSTimeInterval(max(xDuration, yDuration))
			}()
			let anime = CABasicAnimation(keyPath: "position")
			anime.duration = duration
			anime.toValue = NSValue(CGPoint: end)
			anime.fromValue = NSValue(CGPoint: start)
			anime.repeatCount = 999
			anime.autoreverses = true
			anime.removedOnCompletion = false
			anime.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
			self?.text.addAnimation(anime, forKey: "position")
		}
	}
}

