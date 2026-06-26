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
RubGutterDiffDisplayerTest >> testAllLinesModified [
	"Positional: same length, all differ → all #modified (blue)"
	morph setTextWith: 'new1
new2
new3'.
	ruler computeLineStates.
	self assert: ruler lineStates equals: #(#modified #modified #modified) asArray.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testAllLinesUnchanged [
	morph setTextWith: 'line1
line2
line3'.
	ruler computeLineStates.
	self assert: ruler lineStates equals: #(#unchanged #unchanged #unchanged) asArray.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testFirstLineModified [
	"Positional: position 1 differs → #modified (blue)"
	morph setTextWith: 'modified1
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#modified #unchanged #unchanged) asArray.
	self assert: ruler removedPositions isEmpty
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
	"Positional: shifted lines show as #modified, extra line as #added"
	morph setTextWith: 'line1
inserted
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #modified #modified #added) asArray.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLastLineModified [
	"Positional: position 3 differs → #modified (blue)"
	morph setTextWith: 'line1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #unchanged #modified) asArray.
	self assert: ruler removedPositions isEmpty
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
		equals: #(#unchanged #unchanged #unchanged) asArray.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLinesRemovedAtEnd [
	"Trailing baseline lines get removal arrows at their original positions"
	morph setTextWith: 'line1'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged) asArray.
	self assert: ruler removedPositions asArray equals: #(2 3)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testMultipleLinesModified [
	"Positional: positions 1 and 3 differ → #modified (blue)"
	morph setTextWith: 'modified1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#modified #unchanged #modified) asArray.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionsAfterDeletion [
	"Trailing removal records the original baseline line index"
	ruler baseline: 'a
b
c
d'.
	morph setTextWith: 'a
b
c'.
	ruler computeLineStates.
	self assert: ruler removedPositions asArray equals: #(4)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionsMultipleDeletions [
	"Multiple trailing deletions record their original baseline indices"
	ruler baseline: 'a
b
c
d
e'.
	morph setTextWith: 'a
b'.
	ruler computeLineStates.
	self assert: ruler removedPositions asArray equals: #(3 4 5)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionInsideText [
	"Deleting middle line shows removal arrow at original position, adjacent line as #modified"
	ruler baseline: 'line1
line2
line3'.
	morph setTextWith: 'line1
line3'.
	ruler computeLineStates.
	self assert: ruler lineStates equals: #(#unchanged #modified) asArray.
	self assert: ruler removedPositions asArray equals: #(3)
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
