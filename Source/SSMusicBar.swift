//
//  SSMusicBar.swift
//  Pods
//
//  Created by LawLincoln on 16/4/19.
//
//

import UIKit

//MARK:- SSMusicBar
public final class SSMusicBar: UIToolbar {

	public var visible = false

	public convenience init() {
		self.init(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, SSMusicBar.barHeight))
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
	private lazy var _titleLabel: MarqueeLayer = self.marqueeLabel()
	private lazy var _subtitleLabel: MarqueeLayer = self.marqueeLabel()
	private lazy var _leftTotalMargin: CGFloat = 0
	private lazy var _rightTotalMargin: CGFloat = 0
	private lazy var _titleView: UIView = {
		let view = UIView()
		view.userInteractionEnabled = false
		return view
	}()

	static var barHeight: CGFloat { return 40 }
	static var marqueeMaxWidth: CGFloat {
		let bounds = UIScreen.mainScreen().bounds
		let margin: CGFloat = 8
		let buttonHeight = barHeight - CGFloat(margin) * 2
		return bounds.width - 10 - (margin + buttonHeight) * 2
	}
}

//MARK: Setup
extension SSMusicBar {

	private func setup() {
		dealTitleView()
		dealProgressView()
		addTap()
	}

	private func dealTitleView() {

		_titleView.layer.addSublayer(_titleLabel)
		_titleView.layer.addSublayer(_subtitleLabel)
		_titleView.translatesAutoresizingMaskIntoConstraints = false
		leftButton.translatesAutoresizingMaskIntoConstraints = false
		rightButton.translatesAutoresizingMaskIntoConstraints = false
//		_titleView.backgroundColor = UIColor.greenColor()
//		_titleLabel.backgroundColor = UIColor.orangeColor().CGColor
//		_subtitleLabel.backgroundColor = UIColor.orangeColor().CGColor
//		let height = (bounds.height - 4) / 2
//		_titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[_titleLabel]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleLabel": _titleLabel]))
//
//		_titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[_subtitleLabel]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_subtitleLabel": _subtitleLabel]))
//		_titleView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-4-[_titleLabel(\(height))]-0-[_subtitleLabel(\(height))]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleLabel": _titleLabel, "_subtitleLabel": _subtitleLabel]))

		addSubview(_titleView)
		addSubview(leftButton)
		addSubview(rightButton)

		let margin = 8
		let buttonHeight = Int(bounds.height - CGFloat(margin) * 2)
		let width = Int(SSMusicBar.marqueeMaxWidth)
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-\(margin)-[leftButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftButton": leftButton]))

		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-\(margin)-[rightButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["rightButton": rightButton]))

		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[_titleView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleView": _titleView]))
		addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-\(margin)-[leftButton(\(buttonHeight))]-5-[_titleView(\(width))]-5-[rightButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftButton": leftButton, "_titleView": _titleView, "rightButton": rightButton]))
		let x = CGFloat(margin + buttonHeight + 5)
		_titleView.frame = CGRectMake(x, 0, SSMusicBar.marqueeMaxWidth, SSMusicBar.barHeight)
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

	public func marqueeLabel() -> MarqueeLayer {
		let label = MarqueeLayer(max: SSMusicBar.marqueeMaxWidth)
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
			self._titleLabel.update(NSAttributedString(string: value, attributes: attr), y: 4)
		})
	}

	private func updateSubtitle() {
		dispatch_async(dispatch_get_main_queue(), { () -> Void in
			guard let value = self.subtitle else { return }
			let attr = self.defaultAttributed(false)
			self._subtitleLabel.update(NSAttributedString(string: value, attributes: attr), y: (SSMusicBar.barHeight) / 2 + 2)
		})
	}
}
