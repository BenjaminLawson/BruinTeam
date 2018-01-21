struct Controls {
    static let controls: [Control] = [
        Control(uid: 0, controlType: .segmentedControl, title: "best editor", possibleValues: ["Emacs", "Vim", "Sublime Text"]),
        Control(uid: 1, controlType: .toggle, title: "caffeine", possibleValues: nil),
        Control(uid: 2, controlType: .button, title: "bruin bear paw", possibleValues: "Rub"),
        Control(uid: 3, controlType: .button, title: "Boelter 3400", possibleValues: "Find"),
        Control(uid: 4, controlType: .button, title: "CS M117", possibleValues: "Enroll in"),
        Control(uid: 5, controlType: .button, title: "Eggert late policy", possibleValues: "praise"),
        Control(uid: 6, controlType: .toggle, title: "stupid bugs", possibleValues: nil),
        Control(uid: 7, controlType: .button, title: "C++", possibleValues: "Compile"),
        Control(uid: 8, controlType: .button, title: "all nighter", possibleValues: "pull"),
        Control(uid: 9, controlType: .toggle, title: "pass time", possibleValues: nil),
        Control(uid: 10, controlType: .segmentedControl, title: "hours of sleep", possibleValues: ["0", "2", "4","8"]),
        Control(uid: 11, controlType: .button, title: "Discussion", possibleValues: "Skip"),
        Control(uid: 12, controlType: .button, title: "Diffutils", possibleValues: "git clone"),
        Control(uid: 13, controlType: .button, title: "career fair", possibleValues: "attend"),
        Control(uid: 14, controlType: .segmentedControl, title: "career fair line", possibleValues: ["1hr", "2hr", "3hr"]),
        Control(uid: 15, controlType: .button, title: "easy GE", possibleValues: "drop")
    ]
    
    static func typeOf(control uid: Int) -> ControlType {
        return Controls.controls[uid].controlType
    }
}
