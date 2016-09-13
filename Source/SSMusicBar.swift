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
		self.init(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: SSMusicBar.barHeight))
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
	public fileprivate(set) lazy var leftButton = UIButton()
	public fileprivate(set) lazy var rightButton = UIButton()

	public var titleTextAttributes: [String: AnyObject]? {
		didSet { updateTitle() }
	}
	public var subtitleTextAttributes: [String: AnyObject]? {
		didSet { updateSubtitle() }
	}
	public var tapBlock: (() -> ())?

	public lazy var progressView = UIProgressView(progressViewStyle: .default)

	// MARK:- private
	fileprivate lazy var _titleLabel: MarqueeLayer = self.marqueeLabel()
	fileprivate lazy var _subtitleLabel: MarqueeLayer = self.marqueeLabel()
	fileprivate lazy var _leftTotalMargin: CGFloat = 0
	fileprivate lazy var _rightTotalMargin: CGFloat = 0
	fileprivate lazy var _titleView: UIView = {
		let view = UIView()
		view.isUserInteractionEnabled = false
		return view
	}()

	static var barHeight: CGFloat { return 40 }
	static var marqueeMaxWidth: CGFloat {
		let bounds = UIScreen.main.bounds
		let margin: CGFloat = 8
		let buttonHeight = barHeight - CGFloat(margin) * 2
		return bounds.width - 10 - (margin + buttonHeight) * 2
	}
}

//MARK: Setup
extension SSMusicBar {

	fileprivate func setup() {
		dealTitleView()
		dealProgressView()
		addTap()
	}

	fileprivate func dealTitleView() {

		_titleView.layer.addSublayer(_titleLabel)
		_titleView.layer.addSublayer(_subtitleLabel)
		_titleView.translatesAutoresizingMaskIntoConstraints = false
		leftButton.translatesAutoresizingMaskIntoConstraints = false
		rightButton.translatesAutoresizingMaskIntoConstraints = false

		addSubview(_titleView)
		addSubview(leftButton)
		addSubview(rightButton)

		let margin = 8
		let buttonHeight = Int(bounds.height - CGFloat(margin) * 2)
		let width = Int(SSMusicBar.marqueeMaxWidth)
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(margin)-[leftButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftButton": leftButton]))

		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(margin)-[rightButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["rightButton": rightButton]))

		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[_titleView]-0-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["_titleView": _titleView]))
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(margin)-[leftButton(\(buttonHeight))]-5-[_titleView(\(width))]-5-[rightButton(\(buttonHeight))]-\(margin)-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["leftButton": leftButton, "_titleView": _titleView, "rightButton": rightButton]))
		let x = CGFloat(margin + buttonHeight + 5)
		_titleView.frame = CGRect(x: x, y: 0, width: SSMusicBar.marqueeMaxWidth, height: SSMusicBar.barHeight)
	}

	fileprivate func dealProgressView() {
		addSubview(progressView)
		progressView.translatesAutoresizingMaskIntoConstraints = false
		// align progressView from the left and right
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[progressView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["progressView": progressView]))

		// align progressView from the bottom
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[progressView(1)]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["progressView": progressView]))
	}

	fileprivate func addTap() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(SSMusicBar.didTap))
		addGestureRecognizer(tap)
	}

	@objc fileprivate func didTap() {
		tapBlock?()
	}

}
//MARK: Setter/Getter
extension SSMusicBar {

	public func marqueeLabel() -> MarqueeLayer {
		let label = MarqueeLayer(max: SSMusicBar.marqueeMaxWidth)
		return label
	}

	public func defaultAttributed(_ forTitle: Bool) -> [String: AnyObject] {
		let paragraph = NSMutableParagraphStyle()
		paragraph.alignment = .center
		let defaultBarStyle = barStyle == .default

		let attributes = forTitle ? titleTextAttributes : subtitleTextAttributes
		let userColor = attributes?[NSForegroundColorAttributeName] as? UIColor

		let color = defaultBarStyle ? (userColor ?? UIColor.black) : UIColor.white

		let defaultAttributes: [String: AnyObject] = [
			NSParagraphStyleAttributeName: paragraph,
			NSFontAttributeName: UIFont.systemFont(ofSize: 12),
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
	fileprivate func updateTitle() {
		DispatchQueue.main.async(execute: { () -> Void in
			guard let value = self.title else { return }
			let attr = self.defaultAttributed(true)
			self._titleLabel.update(NSAttributedString(string: value, attributes: attr), y: 4)
		})
	}

	fileprivate func updateSubtitle() {
		DispatchQueue.main.async(execute: { () -> Void in
			guard let value = self.subtitle else { return }
			let attr = self.defaultAttributed(false)
			self._subtitleLabel.update(NSAttributedString(string: value, attributes: attr), y: (SSMusicBar.barHeight) / 2 + 2)
		})
	}
}
