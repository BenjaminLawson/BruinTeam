import Foundation

enum ControlType {
    case toggle
    case segmentedControl
    case button
    case slider
}

// TODO: prepositions for instruction generation?
class Control {
    let uid: Int
    let controlType: ControlType
    let title: String
    let possibleValues: Any?
    
    init(uid: Int, controlType: ControlType, title: String, possibleValues: Any?) {
        self.uid = uid
        self.title = title
        self.controlType = controlType
        self.possibleValues = possibleValues
    }
}
