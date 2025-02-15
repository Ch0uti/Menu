// MenuItemView.swift

import SnapKit
import UIKit

public protocol MenuItemView {
  var highlighted: Bool { get set }

  var highlightPosition: CGPoint { get set }

  var didHighlight: () -> Void { get set }

  // Not used. This is used for scrolling to the item
  var initialFocusedRect: CGRect? { get }

  // Not used.
  var updateLayout: () -> Void { get set }

  // Not used.
  func startSelectionAnimation(completion: @escaping () -> Void)
}

extension MenuItemView {
  public func startSelectionAnimation(completion _: @escaping () -> Void) {}

  public var initialFocusedRect: CGRect? { return nil }
}

// MARK: - Separator

class SeparatorMenuItemView: UIView, MenuItemView, MenuThemeable {
  private let separatorLine = UIView()

  init() {
    super.init(frame: .zero)

    addSubview(separatorLine)

    separatorLine.snp.makeConstraints {
      make in

      make.left.right.equalToSuperview()
      make.height.equalTo(1)
      make.top.bottom.equalToSuperview().inset(2)
    }
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Menu Item View

  var highlighted: Bool = false

  var highlightPosition: CGPoint = .zero

  var didHighlight: () -> Void = {}

  var updateLayout: () -> Void = {}

  // MARK: - Themeable

  func applyTheme(_ theme: MenuTheme) {
    separatorLine.backgroundColor = theme.separatorColor
  }
}

// MARK: - Standard Menu Item

extension String {
  var renderedShortcut: String {
    switch self {
    case " ":
      return "Space"
    case "\u{8}":
      return "⌫"
    default:
      return self
    }
  }
}

extension ShortcutMenuItem.Shortcut {
  var labels: [UILabel] {
    let symbols = modifiers.symbols + [key]

    return symbols.map {
      let label = UILabel()
      label.text = $0.renderedShortcut
      label.textAlignment = .right

      if $0 == key {
        label.textAlignment = .left
        label.snp.makeConstraints {
          make in

          make.width.greaterThanOrEqualTo(label.snp.height)
        }
      }

      return label
    }
  }
}

public class ShortcutMenuItemView: UIView, MenuItemView, MenuThemeable {
  private let nameLabel = UILabel()
  private let shortcutStack = UIView()

  private var shortcutLabels: [UILabel] {
    return shortcutStack.subviews.compactMap { $0 as? UILabel }
  }

  public init(item: ShortcutMenuItem) {
    super.init(frame: .zero)

    nameLabel.text = item.name

    addSubview(nameLabel)

    nameLabel.textColor = .black

    nameLabel.snp.makeConstraints { make in
      make.top.bottom.equalToSuperview().inset(4)
      make.left.equalToSuperview().offset(10)
      make.right.lessThanOrEqualToSuperview().offset(-10)
    }

    if let shortcut = item.shortcut, ShortcutMenuItem.displayShortcuts {
      addSubview(shortcutStack)

      nameLabel.snp.makeConstraints { make in
        make.right.lessThanOrEqualTo(shortcutStack.snp.left).offset(-12)
      }

      shortcutStack.snp.makeConstraints { make in
        make.top.bottom.equalToSuperview().inset(2)
        make.right.equalToSuperview().inset(6)
      }

      shortcutStack.setContentHuggingPriority(.required, for: .horizontal)

      let labels = shortcut.labels

      for (index, label) in labels.enumerated() {
        shortcutStack.addSubview(label)

        label.snp.makeConstraints { make in
          make.top.bottom.equalToSuperview()

          if index == 0 {
            make.left.equalToSuperview()
          } else if index < labels.count - 1 {
            make.left.equalTo(labels[index - 1].snp.right).offset(1.0 / UIScreen.main.scale)
          }

          if index == labels.count - 1 {
            if index > 0 {
              make.left.equalTo(labels[index - 1].snp.right).offset(2)
            }
            make.right.equalToSuperview()
          }
        }
      }
    }
  }

  public required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func startSelectionAnimation(completion: @escaping () -> Void) {
    updateHighlightState(false)

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      [weak self] in
      self?.updateHighlightState(true)

      completion()
    }
  }

  // MARK: - Menu Item View

  public var highlighted: Bool = false {
    didSet {
      updateHighlightState(highlighted)

      if highlighted == true, oldValue == false {
        didHighlight()
      }
    }
  }

  public var highlightPosition: CGPoint = .zero

  public var didHighlight: () -> Void = {}

  public var updateLayout: () -> Void = {}

  // MARK: - Themeable Helpers

  private var highlightedBackgroundColor: UIColor = .clear

  private func updateHighlightState(_ highlighted: Bool) {
    nameLabel.isHighlighted = highlighted
    shortcutLabels.forEach { $0.isHighlighted = highlighted }

    backgroundColor = highlighted ? highlightedBackgroundColor : .clear
  }

  // MARK: - Themeable

  public func applyTheme(_ theme: MenuTheme) {
    nameLabel.font = theme.font
    nameLabel.textColor = theme.contentTextColor
    nameLabel.highlightedTextColor = theme.highlightedTextColor

    highlightedBackgroundColor = theme.highlightedBackgroundColor

    shortcutLabels.forEach {
      label in

      label.font = theme.font
      label.textColor = theme.contentTextColor
      label.highlightedTextColor = theme.highlightedTextColor
    }

    updateHighlightState(highlighted)
  }
}
