"
Tests for RubGutterDiffDisplayer - the gutter diff ruler.
"
Class {
	#name : 'RubGutterDiffDisplayerTest',
	#superclass : 'TestCase',
	#instVars : [
		'morph',
		'ruler'
	],
	#category : 'Rubric-Tests-Editing-Widgets',
	#package : 'Rubric-Tests',
	#tag : 'Editing-Widgets'
}

{ #category : 'running' }
RubGutterDiffDisplayerTest >> setUp [
	super setUp.
	morph := RubScrolledTextMorph new.
	morph extent: 400 @ 250.
	morph withGutterDiff.
	ruler := morph gutterDiffRuler.
	ruler baseline: 'line1
line2
line3'
]

{ #category : 'running' }
RubGutterDiffDisplayerTest >> tearDown [
	morph ifNotNil: [ morph delete ].
	super tearDown
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testAllLinesAdded [
	morph setTextWith: 'new1
new2
new3'.
	ruler computeLineStates.
	self assert: ruler lineStates equals: #(#added #added #added) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testAllLinesUnchanged [
	morph setTextWith: 'line1
line2
line3'.
	ruler computeLineStates.
	self assert: ruler lineStates equals: #(#unchanged #unchanged #unchanged) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testFirstLineReplaced [
	"Positional diff: position 1 differs → #modified (blue)"
	morph setTextWith: 'modified1
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#modified #unchanged #unchanged) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testGutterDiffRulerAdded [
	self assert: ruler notNil.
	self assert: ruler class equals: RubGutterDiffDisplayer
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testGutterDiffRulerRemoved [
	morph withoutGutterDiff.
	self assert: morph gutterDiffRuler isNil
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testInsertLineInMiddle [
	"Positional diff: shifted lines show as #modified, extra line as #added"
	morph setTextWith: 'line1
inserted
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #modified #modified #added) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLastLineReplaced [
	"Positional diff: position 3 differs → #modified (blue)"
	morph setTextWith: 'line1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #unchanged #modified) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLineStatesAfterTextChanged [
	morph setTextWith: 'line1
line2
line3'.
	morph textChanged.
	"After textChanged, the ruler should have recomputed its line states"
	self
		assert: ruler lineStates
		equals: #(#unchanged #unchanged #unchanged) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLinesRemovedAtEnd [
	"Trailing baseline lines trigger removal arrows at last current line"
	morph setTextWith: 'line1'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged) asArray.
	self assert: ruler removedPositions asArray equals: #(1)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testMultipleLinesReplaced [
	"Positional diff: positions 1 and 3 differ → #modified (blue)"
	morph setTextWith: 'modified1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#modified #unchanged #modified) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testNoRemovalsWhenSameLength [
	"Same-length texts have no removed positions"
	morph setTextWith: 'line1
line2
modified3'.
	ruler computeLineStates.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionsAfterDeletion [
	"Deleting a line records the position for a red arrow"
	ruler baseline: 'a
b
c
d'.
	morph setTextWith: 'a
b
c'.
	ruler computeLineStates.
	self assert: ruler removedPositions asArray equals: #(3)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionsMultipleDeletions [
	"Multiple trailing deletions all map to the last current line"
	ruler baseline: 'a
b
c
d
e'.
	morph setTextWith: 'a
b'.
	ruler computeLineStates.
	self assert: ruler removedPositions asArray equals: #(2 2 2)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testWithGutterDiffConvenience [
	| morph2 ruler2 |
	morph2 := RubScrolledTextMorph new.
	morph2 withGutterDiff.
	ruler2 := morph2 gutterDiffRuler.
	self assert: ruler2 notNil.
	self assert: (morph2 hasRulerNamed: #gutterDiff).
	morph2 delete
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testWithoutGutterDiffConvenience [
	| morph2 |
	morph2 := RubScrolledTextMorph new.
	morph2 withGutterDiff.
	self assert: (morph2 hasRulerNamed: #gutterDiff).
	morph2 withoutGutterDiff.
	self deny: (morph2 hasRulerNamed: #gutterDiff).
	morph2 delete
]
