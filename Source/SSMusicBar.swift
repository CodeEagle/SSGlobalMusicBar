//
//  SSMusicBar.swift
//  Pods
//
//  Created by LawLincoln on 16/4/19.
//
//

import UIKit
import MarqueeLabelSwift

//MARK:- SSMusicBar
public final class SSMusicBar: UIToolbar {

	public var visible = false

	public convenience init() {
		self.init(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 40))
	}

	override public init(frame: CGRect) {
		super.init(frame: frame)
		setup()
	}

	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setup()
	}

	// MARK: public
	public var title: String? = "" {
		didSet { updateTitle() }
	}

	public var subtitle: String? = "" {
		didSet { updateSubtitle() }
	}

	public lazy var progress: CGFloat = 0
	public private(set) lazy var leftButton = UIButton()
	public private(set) lazy var rightButton = UIButton()

	public var titleTextAttributes: [String: AnyObject]? {
		didSet { updateTitle() }
	}
	public var subtitleTextAttributes: [String: AnyObject]? {
		didSet { updateSubtitle() }
	}
	public var tapBlock: dispatch_block_t?

	public lazy var progressView = UIProgressView(progressViewStyle: .Default)

	// MARK:- private
	private lazy var _titleLabel: MarqueeLabel = self.marqueeLabel()
	private lazy var _subtitleLabel: MarqueeLabel = self.marqueeLabel()
	private lazy var _leftTotalMargin: CGFloat = 0
	private lazy var _rightTotalMargin: CGFloat = 0
	private lazy var _titleView: UIView = {
		let view = UIView()
		view.userInteractionEnabled = false
		return view
	}()
}

//MARK: Setup
extension SSMusicBar {

	private func setup() {
		dealTitleView()
		dealProgressView()
		addTap()
	}

	private func dealTitleView() {
		_titleView.frame = bounds
		_titleView.addSubview(_titleLabel)
		_titleView.addSubview(_subtitleLabel)
		_titleLabel.userInteractionEnabled = false
		_subtitleLabel.userInteractionEnabled = false
		_titleLabel.translatesAutoresizingMaskIntoConstraints = false
		_subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
		_titleView.translatesAutoresizingMaskIntoConstraints = false
		leftButton.translatesAutoresizingMaskIntoConstraints = false
		rightButton.translatesAutoresizingMaskIntoConstraints = false
		let height = (bounds.height - 4) / 2
		_titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[_titleLabel]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleLabel": _titleLabel]))

		_titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[_subtitleLabel]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_subtitleLabel": _subtitleLabel]))
		_titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-4-[_titleLabel(\(height))]-0-[_subtitleLabel(\(height))]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleLabel": _titleLabel, "_subtitleLabel": _subtitleLabel]))

		addSubview(_titleView)
		addSubview(leftButton)
		addSubview(rightButton)

		let margin = 8
		let buttonHeight = Int(bounds.height - CGFloat(margin) * 2)
		let width = 320 - 10 - (margin + buttonHeight) * 2
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-\(margin)-[leftButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftButton": leftButton]))

		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-\(margin)-[rightButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["rightButton": rightButton]))

		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[_titleView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleView": _titleView]))

		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-\(margin)-[leftButton(\(buttonHeight))]-5-[_titleView(>=\(width))]-5-[rightButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftButton": leftButton, "_titleView": _titleView, "rightButton": rightButton]))

	}

	private func dealProgressView() {
		addSubview(progressView)
		progressView.translatesAutoresizingMaskIntoConstraints = false
		// align progressView from the left and right
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[progressView]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["progressView": progressView]))

		// align progressView from the bottom
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[progressView(1)]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["progressView": progressView]))
	}

	private func addTap() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(SSMusicBar.didTap))
		addGestureRecognizer(tap)
	}

	@objc private func didTap() {
		tapBlock?()
	}

}
//MARK: Setter/Getter
extension SSMusicBar {

	public func marqueeLabel() -> MarqueeLabel {
		let label = MarqueeLabel()
		label.leadingBuffer = 5
		label.trailingBuffer = 15
		label.animationDelay = 1.5
		label.type = .Continuous
		return label
	}

	public func defaultAttributed(forTitle: Bool) -> [String: AnyObject] {
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .Center
		let defaultBarStyle = barStyle == .Default

		let attributes = forTitle ? titleTextAttributes : subtitleTextAttributes
		let userColor = attributes?[NSForegroundColorAttributeName] as? UIColor

		let color = defaultBarStyle ? (userColor ?? UIColor.blackColor()) : UIColor.whiteColor()

		let defaultAttributes: [String: AnyObject] = [
			NSParagraphStyleAttributeName: paragraph,
			NSFontAttributeName: UIFont.systemFontOfSize(12),
			NSForegroundColorAttributeName: color
		]

		guard let dict = attributes else { return defaultAttributes }
		var org = defaultAttributes
		for (key, value) in dict {
			org[key] = value
		}
		return org
	}

	// MARK: private
	private func updateTitle() {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			guard let value = self.title else { return }
			let attr = self.defaultAttributed(true)
			self._titleLabel.attributedText = NSAttributedString(string: value, attributes: attr)
			self._titleLabel.resetLabel()
			value.isEmpty ? self._titleLabel.pauseLabel() : self._titleLabel.unpauseLabel()
			guard let aligment = self.titleTextAttributes?[NSParagraphStyleAttributeName] as? NSParagraphStyle else { return }
			self._titleLabel.textAlignment = aligment.alignment
		})
	}

	private func updateSubtitle() {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			guard let value = self.subtitle else { return }
			let attr = self.defaultAttributed(false)
			self._subtitleLabel.attributedText = NSAttributedString(string: value, attributes: attr)
			self._subtitleLabel.resetLabel()
			value.isEmpty ? self._subtitleLabel.pauseLabel() : self._subtitleLabel.unpauseLabel()
			guard let aligment = self.subtitleTextAttributes?[NSParagraphStyleAttributeName] as? NSParagraphStyle else { return }
			self._subtitleLabel.textAlignment = aligment.alignment
		})
	}
}
