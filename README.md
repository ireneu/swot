# swot

`swot` is an Operational Transformation implementation in Swift.

Operational Transformation, often called OT, is a method that enables real-time collaboration on documents. It powers platforms like *Google Docs*. More information can be found on [here](https://www.wikiwand.com/en/Operational_transformation).

## Usage

```swift
// Applying a changeset
let documentT = "I'm at home"
let changesetA = Changeset(operations: [
    Keep(value: 7),
    Remove(value: 4),
    Add(value: "the beach"),
])
let documentS = try changesetA.apply(to: documentT)
// "I'm at home" -> "I'm at the beach"

// Composing changesets
let changesetB = Changeset(operations: [
    Add(value: "We're"),
    Remove(value: 3),
    Keep(value: 13),
    Add(value: " until later"),
])
let documentU = try changesetB.apply(to: documentS)
// "I'm at the beach" -> "We're at the beach until later"

let changesetC = try changesetA >>> changesetB
let documentV = try changesetC.apply(to: documentT)
// "I'm at home" -> "We're at the beach until later"

// Combining changsets
let changesetD = Changeset(operations: [
    Keep(value: 4),
    Add(value: "hanging out "),
    Keep(value: 7),
])
let documentW = try changesetD.apply(to: documentT)
// "I'm at home" -> "I'm hanging out at home"

let combined = try changesetC <~> changesetD
let documentX = try combined.right.apply(to: documentV)
// "We're at the beach until later" -> "We're hanging out at the beach until later"
let documentY = try combined.left.apply(to: documentW)
// "I'm hanging out at home" -> "We're hanging out at the beach until later"
```

## Installing swot

`swot` can be installed either by copying the source code or by using the Swift Package Manager (SPM).

### SPM

```swift
dependencies: [
  .package(url: "https://github.com/ireneu/swot.git", .branch("master")),
],
targets: [
	.target(name: "MyProject", dependencies: ["Swot"])
]
```

## License

This software is licensed under the MIT License.
Copyright © Ireneu Pla, 2018.
