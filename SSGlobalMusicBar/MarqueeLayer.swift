//
//  MarqueeLayer.swift
//  LuooAudioPlayerController
//
//  Created by LawLincoln on 16/7/11.
//  Copyright © 2016年 SelfStudio. All rights reserved.
//

import UIKit

public final class MarqueeLayer: CALayer {

	fileprivate var animate = false
	var contentInset = UIEdgeInsets.zero
	fileprivate let text = CATextLayer()
	fileprivate var maxWidth: CGFloat = 0
	override init(layer: Any) { super.init(layer: layer) }
	required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
	fileprivate var gMask = CAGradientLayer()
	init(max width: CGFloat) {
		super.init()
		maxWidth = width
		text.anchorPoint = CGPoint.zero
		masksToBounds = true
		contentsScale = UIScreen.main.scale
		text.contentsScale = contentsScale
		contentInset = UIEdgeInsetsMake(0, 4, 0, 4)

		gMask.colors = [UIColor.clear.cgColor, UIColor.white.cgColor, UIColor.white.cgColor, UIColor.clear.cgColor]
		gMask.locations = [0, 0.05, 0.95, 1]
		gMask.anchorPoint = CGPoint.zero
		gMask.startPoint = CGPoint(x: 0, y: 0.5)
		gMask.endPoint = CGPoint(x: 1, y: 0.5)
		addSublayer(text)
	}

	func update(_ string: NSAttributedString, y: CGFloat) {
		var rectValue = CGRect.zero
		let size = CGSize(width: 9999, height: bounds.size.height + 20)
		let value = string.boundingRect(with: size, options: .usesFontLeading, context: nil)
		var textRect = CGRect(
			x: 0,
			y: contentInset.top,
			width: value.width,
			height: contentInset.top + value.height + contentInset.bottom)
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
			rectValue = CGRect(x: (sp.bounds.width - rectValue.width) / 2, y: y, width: rectValue.width, height: rectValue.height)
		}
		text.frame = textRect
		frame = rectValue
		text.string = string
		mask?.frame = bounds
		let start = CGPoint(x: contentInset.left, y: 0)
		let end = CGPoint(x: frame.width - textRect.maxX, y: 0)
		let max = CGPoint(x: maxWidth, y: rectValue.height)
		marquee(from: start, to: end, max: max)
	}

	fileprivate func marquee(from start: CGPoint, to end: CGPoint, max point: CGPoint) {
		removeAllAnimations()
		if end.x >= 0 || start == end {
			animate = false
			return
		}
		animate = true
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) { [weak self] in
			if self?.animate == false { return }
			let speed: CGFloat = 10 // 10 point per second
			let duration: TimeInterval = {
				let xDuration = abs(end.x) / speed
				let yDuration = abs(end.y) / speed
				return TimeInterval(max(xDuration, yDuration))
			}()
			let anime = CABasicAnimation(keyPath: "position")
			anime.duration = duration
			anime.toValue = NSValue(cgPoint: end)
			anime.fromValue = NSValue(cgPoint: start)
			anime.repeatCount = 999
			anime.autoreverses = true
			anime.isRemovedOnCompletion = false
			anime.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
			self?.text.add(anime, forKey: "position")
		}
	}
}

