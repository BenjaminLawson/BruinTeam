import UIKit

class LabeledSlider: UISlider {
    let names: [String]
    var labels = [UILabel]()
    var tickDistance: CGFloat {
        return (bounds.size.width) / (CGFloat(names.count) - 1.0)
    }
    
    let labelVerticalOffset: CGFloat = -15.0
    
    convenience init(names: [String]) {
        let width = CGFloat(names.count * 36) + 10
        let frame = CGRect(x: 0.0, y: 0.0, width: width, height: 40.0)
        self.init(names: names, frame: frame)
    }
    
    init(names: [String], frame: CGRect) {
        self.names = names
        
        super.init(frame: frame)
        
        self.minimumValue = 0.0
        self.maximumValue = Float(self.names.count - 1)
        self.value = minimumValue
        self.isContinuous = false
        self.minimumTrackTintColor = .gray
        self.maximumTrackTintColor = self.minimumTrackTintColor
        
        layoutLabels()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func layoutLabels() {
        for label in labels { label.removeFromSuperview() }
        labels.removeAll()
        
        let nLabels = names.count
        if nLabels > 0 {
            for (i, name) in names.enumerated() {
                let label = UILabel()
                labels.append(label)
                
                label.text = name
                label.textAlignment = .center
                label.font = UIFont.systemFont(ofSize: 12.0, weight: .bold)
                label.sizeToFit()

                var rect = label.frame
                rect.origin.x = midXFor(value: Float(i)) - (rect.width/2.0)
                rect.origin.y = bounds.midY - rect.size.height + labelVerticalOffset
                label.frame = rect
                
                addSubview(label)
            }
        }
    }
    
    func rectFor(value: Float) -> CGRect {
        return thumbRect(forBounds: bounds, trackRect: trackRect(forBounds: bounds), value: value)
    }
 
    
    func midXFor(value: Float) -> CGFloat {
        return rectFor(value: value).midX
    }

    
    override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        // round value changes before actions are received
        value = Float(Int(round(value)))
        super.sendAction(action, to: target, for: event)
    }
}
