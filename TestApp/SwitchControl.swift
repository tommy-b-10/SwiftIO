//
//  SwitchControl.swift
//  SwiftIO
//
//  Created by Jonathan Wight on 1/9/16.
//  Copyright © 2016 schwa.io. All rights reserved.
//

import Cocoa

class SwitchControl: NSControl {

    override class func initialize() {
        exposeBinding("on")
    }

    var on: Bool = false {
        didSet {
            if oldValue == on {
                return
            }
            update(animated: true)
            if action != nil && target != nil {
                sendAction(action, to: target)
            }
        }
    }

    var offColor = NSColor.controlShadowColor
    var onColor = NSColor.keyboardFocusIndicatorColor

    fileprivate var update: ((Void) -> Void)!

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 20),
            widthAnchor.constraint(equalToConstant: 60)
        ])


        addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(SwitchControl.click(_:))))

        setup()
    }

    func setup() {

        // Background View

        let backgroundView = LayerView()
        backgroundView.backgroundColor = offColor
        backgroundView.cornerRadius = 2
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundView)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        // Thumb View

        let thumbView = LayerView()
        thumbView.backgroundColor = .white
        thumbView.borderColor = offColor
        thumbView.borderWidth = 1
        thumbView.cornerRadius = 2
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(thumbView)

        var thumbConstraint: NSLayoutConstraint! = thumbView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor)

        NSLayoutConstraint.activate([
            thumbConstraint,
            thumbView.widthAnchor.constraint(equalTo: backgroundView.widthAnchor, multiplier: 0.5),
            thumbView.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            thumbView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
        ])

        // Leading Guide

        let leadingGuide = NSLayoutGuide()
        backgroundView.addLayoutGuide(leadingGuide)
        NSLayoutConstraint.activate([
            leadingGuide.widthAnchor.constraint(equalTo: backgroundView.widthAnchor, multiplier: 0.5),
            leadingGuide.trailingAnchor.constraint(equalTo: thumbView.leadingAnchor),
            leadingGuide.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            leadingGuide.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
        ])

        // Leading Label

        let leadingLabel = label("ON")
        leadingLabel.textColor = .white
        leadingLabel.font = NSFont.systemFont(ofSize: 11)
        leadingLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(leadingLabel)

        NSLayoutConstraint.activate([
            leadingLabel.centerXAnchor.constraint(equalTo: leadingGuide.centerXAnchor),
            leadingLabel.centerYAnchor.constraint(equalTo: leadingGuide.centerYAnchor),
        ])

        // Trailing Guide

        let trailingGuide = NSLayoutGuide()
        backgroundView.addLayoutGuide(trailingGuide)
        NSLayoutConstraint.activate([
            trailingGuide.leadingAnchor.constraint(equalTo: thumbView.trailingAnchor),
            trailingGuide.widthAnchor.constraint(equalTo: backgroundView.widthAnchor, multiplier: 0.5),
            trailingGuide.topAnchor.constraint(equalTo: backgroundView.topAnchor),
            trailingGuide.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor),
        ])

        // Trailing Label

        let trailingLabel = label("OFF")
        trailingLabel.textColor = .white
        trailingLabel.font = NSFont.systemFont(ofSize: 11)
        trailingLabel.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.addSubview(trailingLabel)

        NSLayoutConstraint.activate([
            trailingLabel.centerXAnchor.constraint(equalTo: trailingGuide.centerXAnchor),
            trailingLabel.centerYAnchor.constraint(equalTo: trailingGuide.centerYAnchor),
        ])

        // Update Closure

        update = {
            let color = self.on ? self.onColor : self.offColor
            backgroundView.backgroundColor = color
            thumbView.borderColor = color

            thumbConstraint.isActive = false
            thumbConstraint = nil

            if self.on == false {
                thumbConstraint = thumbView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor)
            }
            else {
                thumbConstraint = thumbView.leadingAnchor.constraint(equalTo: backgroundView.centerXAnchor)
            }
            thumbConstraint.isActive = true
        }
    }

    func update(animated: Bool) {

        if animated == false {
            update()
        }
        else {
            NSAnimationContext.runAnimationGroup({ context -> Void in
                context.duration = 0.25
                context.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
                context.allowsImplicitAnimation = true
                self.update()
                self.layoutSubtreeIfNeeded()
                }) { () -> Void in
            }
        }
    }


    func click(_ gestureRecognizer: NSClickGestureRecognizer) {
        on = !on
    }


}
