# Totoro - Swift Good Practices

![alt Don't make my life harder](http://i.imgur.com/T0gOgrX.png)

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

###Block Retain Cycle
Retaining cycles are one of the most dangerous mistakes programmers can make, as these cycles can lead to unexpected crashes and huge memory consumption. There are multiple ways to tackle well-known retain cycle issues.
Let's take a look at this code :

```
class PrettyThing {
    func doStuff(completion: (() -> Void)?) {
        completion?()
    }
}

class Controller: UIViewController {
    let myPrettyThing = PrettyThing()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myPrettyThing.doStuff {
            self.doSomething()
        }
    }
}
```
In our case, method doSomething() causes retaining because the closure is capturing self as a strong reference to it. 
Take 1 minute to look into how we handle this little boy in Obj C, first we will make a weak reference to the object(s) we wish to use in the closure.
`weak typeof(self) *weakSelf = self;`
And then we will continue with `weakSelf` in the closure.

Well, here in Swift, the logic is gonna be the same, our first attemption is to make a `weak` copy of self
```
    override func viewDidLoad() {
    super.viewDidLoad()
    
    myPrettyThing.doStuff { [weak self] in
        self?.doSomething()
    }
}
```
You should pay a particular attention to why I use `weak` not `unowned` here. If you ever read through the Apple documentations, they say thay `unowned` reference is non-optional, which means you don't have to unwrapp it. It is generally safer for you to use `weak`, because using unowned assumes the object will never be nil. This may lead to your app crashing if the object has actually been deallocated before being used in your closure. 
Okay, the syntax above looks okay, but what if we can do this in a Swifty way? For the sake of robust code, let's all find a way to handle this Swiftily. Swift 2.0 introduced a new statement, guard, to simplify a code structure and to finally get rid of scary pyramids of `if` statements. Embracing the power of guards inside closures can rapidly enhance our lives and set a smart convention in programming, also guard guarantees the early exit - don't we all love it?

```
override func viewDidLoad() {
    super.viewDidLoad()
    
    myPrettyThing.doStuff { [weak self] in
        guard let aSelf = self else {
            return 
        }
        
        aSelf.doSomething()
    }
}
```
The guard statement was used to protect self, not to be nil, and if so a code won’t continue in the closure. Using a local variable `aSelf` will ensure that there will be no retain cycle.

A syntax sugar in the end - wouldn’t it be great to use just self instead of aSelf? Yes, it would, my argue is that I don't want to create a new name. Using back quotes together with a guard statement can lead to the code below:

```
override func viewDidLoad() {
    super.viewDidLoad()
    
    myPrettyThing.doStuff { [weak self] in
        guard let `self` = self else {
            return 
        }
        
        self.doSomething()
    }
}
```
If you are confusing about the use of backtick here, please check this [Lexical Structure](https://developer.apple.com/library/ios/documentation/Swift/Conceptual/Swift_Programming_Language/LexicalStructure.html). Because `self` is a reserved keyword, so if we wish to use it as an identifier, all we do is to simply wrap it with backtick `

```
To use a reserved word as an identifier, put a backtick (`) before and after it. For example, class is not a valid identifier, but `class` is valid. The backticks are not considered part of the identifier; `x` and x have the same meaning.
```
