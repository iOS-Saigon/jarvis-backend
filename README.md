# Totoro - Swift Good Practices

This is my proposal good practices to the upcoming Startup Weekend iOS Saigon Group Project - Mai Mai.
Because being a programmer is not only about selling out the products but also about qualifying the source code.

###Language
Please use US English spelling to match with Apple's API. For example, consider using `color` instead of `colour`.

###White spaces
* Use spaces for tabs and 4 spaces per tab (Change the default in `Xcode` -> `Preferences` -> `Text Editing` -> `Indentation`)
* End file with a new line.
* Make liberal use of vertical whitespaces to divide code into logical chunks - improve the readibility. However, the maximum number of vertical whitespaces should be 1.
* No trailing spaces.
* Not even leading indentations on empty lines.
* Do not introduce unnecessary empty lines. Let's keep the code base clean and nice.
* The closing brace for `guard` statements should be followed by an empty line.
```
guard let someValue = someValue else {
    return
}

//do something with someValue
```
* Call to `super` shouls be followed by an empty line, unless it is the end of the code block.

###Naming Convention
* All names should make sense in the context of use.
* Type names (classes, structures, enums and protocols) should be `upper camel case`.
* Methods, variables and constants name should be `lower camel case`.
* Avoid use abbreviations and acronyms. Extremely common abbreviations such as URL are fine. Following the Apple Design Guidelines, abbreviations and initialisms that appear in all uppercase should be uniformly uppercase or lowercase (i.e `URLString`,`urlString` instead of `uRlString`).
* Class prefix is not needed in Swift, unless of course interfacing with Objective C.
* Following Apple's API Design Guidelines, protocols names that describe what something is should be a noun. Examples: `Collection`. Protocols names that describe an ability should end in -ing, -able, or -ible. Examples: `Equatable`, `Resizing`.
* Prefer function names to be in active voice, followed with parameters in context of use.
* Prefer having function/init methods named parameters for all arguments unless the context is super clear.

```
enum Weekday {
    case Monday, Tuesday, Wednesday, Thursday, Friday
}

let itemsCount = 100

struct PrettyThing {
    var name : String
    var price : Double
}

class PrettyThingsCollectionViewController {
    func getPrettyThingsList() {...}
}
```

###Comments

* Comments should not be used to disable code. DO NOT comment out code, delete unused code without fear or favor. We don't wish to pollute our source code, do we?
* Use comments to explain why a particular piece of code does something. Comments must be kept up-to-date or deleted.
* Avoid block comments inline with code, as the code should be as self-documenting as possible.

###Constants
* Constants used within type definitions should be declared static within a type.
* Avoid declaring a constant at global level except for singleton.
* Constant's name should be written in `upperCamelCase`
* Use struct to declare a set of constants not to be used for switching.

```
class SomeClass {
    static let ConstantValue = 3
}

struct Endpoints {
    static let EndpointA = "endpoint A"
    static let EndpointB = "endpoint B"
}
```

###Interface Builder
Let's not use Storyboards at any costs. The only thing I would keep is `LaunchScreen.storyboard` for the app to look proper on every screen sizes. Why?

Thanks Zalora for enlightening me how mean storyboard is, and thanks to Zhenling's inspirational article [Say NO to Storyboard](https://medium.com/@tsaizhenling/say-no-to-storyboards-3048538ec359#.s3pfr8hz9), I will summarize them up here :
* Storyboards will likely introduce merge conflicts due to their complex XML structure, if you are working in a team and have 2+ person touching storyboard at the same time. And believe me, fixing merge conflicts is a pain in the ass.
* Storyboard is not flexible. If you want to go with autolayout, then you will have to go with autolayout for every views in the storyboards. Why can't we not go with autoresizing selectively on some simple views? Life is too short to complicate things.
* I know some of you might love using segues, but for me, segue is a bitch. Why? Because magic strings. Why? Because we cannot use designated initializers and avoid introducing mutable state to your properties when not needed (which annoys me more than it should)

Don't get me wrong. I love the idea of setting up UI visually, which can be done using `xib`. If I can set some UI properties using IB, then I will use IB. Let's avoid building the UI programmatically as much as possible.
