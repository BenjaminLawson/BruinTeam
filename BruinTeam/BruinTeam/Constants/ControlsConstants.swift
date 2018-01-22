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
        Control(uid: 10, controlType: .slider, title: "hours of sleep", possibleValues: ["0", "2", "4","8"]),
        Control(uid: 11, controlType: .button, title: "discussion", possibleValues: "Skip"),
        Control(uid: 12, controlType: .button, title: "Diffutils", possibleValues: "git clone"),
        Control(uid: 13, controlType: .button, title: "career fair", possibleValues: "attend"),
        Control(uid: 14, controlType: .segmentedControl, title: "career fair line length", possibleValues: ["100m", "400m", "1km"]),
        Control(uid: 15, controlType: .button, title: "hard GE", possibleValues: "drop"),
        Control(uid: 16, controlType: .button, title: "flyers", possibleValues: "dodge"),
        Control(uid: 17, controlType: .slider, title: "relative course difficulty", possibleValues: ["low", "medium", "high"]),
        Control(uid: 18, controlType: .slider, title: "textbook price", possibleValues: ["$40", "$100", "$275"]),
        Control(uid: 19, controlType: .segmentedControl, title: "textbook quality", possibleValues: ["harmful", "okay", "good"]),
        Control(uid: 20, controlType: .segmentedControl, title: "expected grade", possibleValues: ["B","C", "D", "F", "NP"]),
        Control(uid: 21, controlType: .button, title: "assigned reading", possibleValues: "read"),
        Control(uid: 22, controlType: .button, title: "assigned reading", possibleValues: "ignore"),
        Control(uid: 23, controlType: .button, title: "Piazza", possibleValues: "post on"),
        Control(uid: 24, controlType: .toggle, title: "fire alarm", possibleValues: nil),
        Control(uid: 25, controlType: .button, title: "the gym", possibleValues: "hit"),
        Control(uid: 26, controlType: .segmentedControl, title: "ucla memes", possibleValues: ["🔥","🍌", "🏈", "🍺", "🤔"]),
        Control(uid: 27, controlType: .slider, title: "affordable housing", possibleValues: ["⛺️", "🏚", "🚗","🛶"]),
        Control(uid: 28, controlType: .segmentedControl, title: "Feast menu item", possibleValues: ["🍙","🍚", "🍘", "🥟", "🍜"]),
        Control(uid: 29, controlType: .segmentedControl, title: "BPlate menu item", possibleValues: ["🍄","☘️", "🥦", "🥗", "🥩"]),
        Control(uid: 30, controlType: .slider, title: "current health", possibleValues: ["🤮","🤧", "😷", "🤒", "🤕"])
        
    ]
    
    static func typeOf(control uid: Int) -> ControlType {
        return Controls.controls[uid].controlType
    }
}
