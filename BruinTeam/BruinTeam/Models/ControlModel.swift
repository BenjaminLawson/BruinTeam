enum ControlType {
    case toggle
    case segmentedControl
    case button
    case slider
}

struct Control {
    let controlType: ControlType
    let title: String
    let possibleValues: Any?
    
    init(controlType: ControlType, title: String, possibleValues: Any?) {
        self.title = title
        self.controlType = controlType
        self.possibleValues = possibleValues
    }
}
