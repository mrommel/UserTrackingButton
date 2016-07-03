//
//  UserTrackingButton.swift
//  UserTrackingButton
//
//  Created by Mikko Välimäki on 15-12-04.
//  Copyright © 2015 Mikko Välimäki. All rights reserved.
//

import Foundation
import MapKit

let animationDuration = 0.2

@IBDesignable public class UserTrackingButton : UIControl, MKMapViewDelegate {
    
    private var locationButton: UIButton = UIButton()
    private var locationOffButton: UIButton = UIButton()
    private var trackingActivityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    private var viewState: ViewState = .Initial

    enum ViewState {
        case Initial
        case RetrievingLocation
        case TrackingLocationOff
        case TrackingLocation
    }
    
    @IBOutlet public var mapView: MKMapView?
    
    required public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.addTarget(self, action: #selector(UserTrackingButton.pressed), forControlEvents: .TouchUpInside)

        self.addButton(self.locationButton, withImage: getImage("TrackingLocationMask"))
        self.addButton(self.locationOffButton, withImage: getImage("TrackingLocationOffMask"))
        
        self.locationOffButton.hidden = true
        self.locationButton.hidden = true
        self.trackingActivityIndicator.stopAnimating()

        self.trackingActivityIndicator.hidesWhenStopped = true
        self.trackingActivityIndicator.hidden = true
        self.trackingActivityIndicator.userInteractionEnabled = false
        self.trackingActivityIndicator.exclusiveTouch = false
        self.trackingActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.trackingActivityIndicator)
        self.addConstraints([
            NSLayoutConstraint(item: self.trackingActivityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.trackingActivityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0),
            ])
        
        self.layer.cornerRadius = 4
        self.clipsToBounds = true
        
        self.transitionToState(.TrackingLocationOff, animated: false)
    }
    
    public override func intrinsicContentSize() -> CGSize {
        return self.locationButton.intrinsicContentSize()
    }
    
    public override func tintColorDidChange() {
        self.trackingActivityIndicator.tintColor = self.tintColor
    }
    
    public func updateState(animated: Bool) {
        if let mapView = self.mapView {
            updateState(forMapView: mapView, animated: animated)
        }
    }
    
    internal func pressed(sender: UIButton!) {
        let userTrackingMode: MKUserTrackingMode
        switch mapView?.userTrackingMode {
        case .Some(MKUserTrackingMode.Follow):
            userTrackingMode = MKUserTrackingMode.None
        default:
            userTrackingMode = MKUserTrackingMode.Follow
        }

        mapView?.setUserTrackingMode(userTrackingMode, animated: true)
    }
    
    private func updateState(forMapView mapView: MKMapView, animated: Bool) {
        let state: ViewState
        if mapView.userTrackingMode == .None {
            state = .TrackingLocationOff
        } else if mapView.userLocation.location == nil || mapView.userLocation.location?.horizontalAccuracy >= kCLLocationAccuracyHundredMeters {
            state = .RetrievingLocation
        } else {
            state = .TrackingLocation
        }
        transitionToState(state, animated: animated)
    }
    
    // MARK: Helpers
    
    private func addButton(button: UIButton, withImage image: UIImage?) {
        button.addTarget(self, action: #selector(UserTrackingButton.pressed), forControlEvents: .TouchUpInside)
        button.setImage(image?.imageWithRenderingMode(.AlwaysTemplate), forState: .Normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(button)
        
        self.addConstraints([
            NSLayoutConstraint(
                item: button,
                attribute: .Leading,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Leading,
                multiplier: 1,
                constant: 0),
            NSLayoutConstraint(
                item: button,
                attribute: .Trailing,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Trailing,
                multiplier: 1,
                constant: 0),
            NSLayoutConstraint(
                item: button,
                attribute: .Top,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Top,
                multiplier: 1,
                constant: 0),
            NSLayoutConstraint(
                item: button,
                attribute: .Bottom,
                relatedBy: .Equal,
                toItem: self,
                attribute: .Bottom,
                multiplier: 1,
                constant: 0),
            ])
    }
    
    private func transitionToState(state: ViewState, animated: Bool) {
        
        switch state {
        case .RetrievingLocation:
            self.hide(locationOffButton, animated: animated)
            self.hide(locationButton, animated: animated) {
                self.trackingActivityIndicator.hidden = false
                self.trackingActivityIndicator.startAnimating()
            }
        case .TrackingLocation:
            self.trackingActivityIndicator.stopAnimating()
            self.hide(locationOffButton, animated: animated)
            self.show(locationButton, animated: animated)
        case .TrackingLocationOff:
            self.trackingActivityIndicator.stopAnimating()
            self.hide(locationButton, animated: animated)
            self.show(locationOffButton, animated: animated)
        default:
            break
        }
        
        self.viewState = state
    }
    
    private func getImage(named: String) -> UIImage? {
        return UIImage(named: named, inBundle: NSBundle(forClass: self.dynamicType), compatibleWithTraitCollection: nil)
    }
    
    // MARK: Interface Builder
    
    public override func prepareForInterfaceBuilder() {
        self.transitionToState(.TrackingLocationOff, animated: false)
    }
    
    // MARK: Button visibility
    
    private class func setHidden(button: UIButton, hidden: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        guard button.hidden != hidden else {
            completion?()
            return
        }
        
        if button.hidden {
            button.alpha = 0.0
            button.hidden = false
        }
        
        let anim: () -> Void = {
            button.alpha = hidden ? 0.0 : 1.0
        }
        
        let compl: ((Bool) -> Void) = { _ in
            button.hidden = hidden
            completion?()
        }
        
        if animated {
            UIView.animateWithDuration(0.2, animations: anim, completion: compl)
        } else {
            anim()
            compl(true)
        }
    }
    
    private func hide(button: UIButton, animated: Bool, completion: (() -> Void)? = nil) {
        UserTrackingButton.setHidden(button, hidden: true, animated: animated, completion: completion)
    }
    
    private func show(button: UIButton, animated: Bool, completion: (() -> Void)? = nil) {
        button.superview?.bringSubviewToFront(self)
        UserTrackingButton.setHidden(button, hidden: false, animated: animated, completion: completion)
    }
}
