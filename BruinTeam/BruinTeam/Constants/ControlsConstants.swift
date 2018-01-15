struct Controls {
    static let controls: [Control] = [
        Control(uid: 0, controlType: .segmentedControl, title: "Best editor", possibleValues: ["Emacs", "Vim", "Sublime Text"]),
        Control(uid: 1, controlType: .toggle, title: "Caffeine", possibleValues: nil),
        Control(uid: 2, controlType: .button, title: "Bruin bear paw", possibleValues: "Rub"),
        Control(uid: 3, controlType: .button, title: "Boelter 3400", possibleValues: "Find"),
        Control(uid: 4, controlType: .button, title: "CS M117", possibleValues: "Enroll in"),
        Control(uid: 5, controlType: .button, title: "Eggert late policy", possibleValues: "Abuse"),
        Control(uid: 6, controlType: .toggle, title: "Stupid Bugs", possibleValues: nil)
    ]
}
