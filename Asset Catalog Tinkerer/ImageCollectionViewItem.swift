//
//  ImageCollectionViewItem.swift
//  Asset Catalog Tinkerer
//
//  Created by Guilherme Rambo on 27/03/16.
//  Copyright © 2016 Guilherme Rambo. All rights reserved.
//

import Cocoa

extension NSTextField {
    
    class func makeLabel() -> NSTextField {
        let l = NSTextField(frame: .zero)
        
        l.translatesAutoresizingMaskIntoConstraints = false
        l.isBordered = false
        l.isBezeled = false
        l.isEditable = false
        l.isSelectable = false
        l.drawsBackground = false
        l.textColor = .labelColor
        
        return l
    }
    
}

class ImageCollectionViewItem: NSCollectionViewItem {

    private struct Constants {
        static let brightImageThreshold: CGFloat = 0.8
    }
    
    var image: [String: NSObject]? {
        didSet {
            updateUI()
        }
    }
    
    fileprivate struct Colors {
        static let background = NSColor(calibratedWhite: 0.9, alpha: 1.0)
        static let brightImageBackground = NSColor(calibratedWhite: 0.9, alpha: 1)
        static let border = NSColor(calibratedWhite: 0.9, alpha: 1.0)
        static var selectedBackground: NSColor {
            if #available(macOS 10.14, *) {
                return NSColor.controlAccentColor
            } else {
                return NSColor(calibratedRed:0, green:0.496, blue:1, alpha:1)
            }
        }
        static var selectedBorder: NSColor {
            if #available(macOS 10.14, *) {
                return NSColor.controlAccentColor.shadow(withLevel: 0.3)!
            } else {
                return NSColor(calibratedRed:0.019, green:0.316, blue:0.687, alpha:1)
            }
        }
        static var text: NSColor {
            if #available(macOS 10.14, *) {
                return NSColor.controlAccentColor
            } else {
                return NSColor(calibratedRed:0, green:0.496, blue:1, alpha:1)
            }
        }
        static let selectedText = NSColor.white
    }
    
    private var optimalBackgroundColor: NSColor = Colors.background
    
    override var isSelected: Bool {
        didSet {
            view.layer?.backgroundColor = isSelected ? Colors.selectedBackground.cgColor : optimalBackgroundColor.cgColor
            view.layer?.borderColor = isSelected ? Colors.selectedBorder.cgColor : Colors.border.cgColor
            nameLabel.textColor = isSelected ? Colors.selectedText : Colors.text
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildUI()
        updateUI()
    }
    
    fileprivate lazy var catalogImageView: NSImageView = {
        let iv = NSImageView(frame: NSZeroRect)
        
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.imageFrameStyle = .none
        iv.imageScaling = .scaleProportionallyDown
        iv.imageAlignment = .alignCenter
        
        return iv
    }()
    
    fileprivate lazy var nameLabel: NSTextField = {
        let l = NSTextField.makeLabel()
        
        l.font = NSFont.systemFont(ofSize: 11.0, weight: .medium)
        l.textColor = Colors.text
        l.lineBreakMode = .byTruncatingMiddle
        
        return l
    }()

    fileprivate lazy var typeView: NSTextField = {
        let l = NSTextField.makeLabel()

        l.font = NSFont.systemFont(ofSize: 11.0, weight: .bold)
        l.textColor = Colors.selectedText
        l.backgroundColor = .gray
        l.drawsBackground = true

        return l
    }()
    
    fileprivate lazy var brightnessDebugLabel: NSTextField = {
        let l = NSTextField.makeLabel()
        
        l.font = NSFont.systemFont(ofSize: 11.0, weight: .medium)
        l.isHidden = !Preferences.shared[.debugImageBrightness]
        
        return l
    }()
    
    fileprivate func buildUI() {
        defer { installBrightnessDebugLabelIfNeeded() }
        
        guard catalogImageView.superview == nil else { return }
        
        view.wantsLayer = true
        view.layer = CALayer()
        
        catalogImageView.frame = view.bounds
        view.addSubview(catalogImageView)
        
        catalogImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        catalogImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        catalogImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        catalogImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        view.layer!.borderWidth = 1.0
        view.layer!.borderColor = Colors.border.cgColor
        view.layer!.cornerRadius = 4.0
        
        view.addSubview(nameLabel)
        nameLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -2.0).isActive = true
        nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        nameLabel.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 1.0, constant: -12.0).isActive = true

        view.addSubview(typeView)
        typeView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0.0).isActive = true
        typeView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0.0).isActive = true
    }
    
    private func installBrightnessDebugLabelIfNeeded() {
        guard Preferences.shared[.debugImageBrightness], brightnessDebugLabel.superview == nil  else { return }
        
        view.addSubview(brightnessDebugLabel)
        brightnessDebugLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 2.0).isActive = true
        brightnessDebugLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4.0).isActive = true
    }
    
    fileprivate func updateUI() {
        guard let imageData = image , isViewLoaded else { return }
        guard let image = imageData["thumbnail"] as? NSImage else { return }
        let name = imageData["name"] as! String
        let filename = imageData["filename"] as? String

        let brightness = image.averageBrightness()
        
        catalogImageView.image = image
        nameLabel.stringValue = name
        view.toolTip = filename

        if imageData["png"] != nil {
            typeView.stringValue = "PNG"
            typeView.backgroundColor = .systemBlue
        } else if imageData["pdf"] != nil {
            typeView.stringValue = "PDF"
            typeView.backgroundColor = .systemRed
        } else if imageData["color"] != nil {
            typeView.stringValue = "Color"
            typeView.backgroundColor = .systemPurple
        } else {
            typeView.stringValue = "?"
            typeView.backgroundColor = .systemGray

        }
        
        if Preferences.shared[.debugImageBrightness] {
            brightnessDebugLabel.stringValue = String(format: "B: %.1f", brightness)
        }
        
        if brightness >= Constants.brightImageThreshold {
            optimalBackgroundColor = Colors.brightImageBackground
        } else {
            optimalBackgroundColor = Colors.background
        }
        
        view.layer?.backgroundColor = optimalBackgroundColor.cgColor
    }
    
}
