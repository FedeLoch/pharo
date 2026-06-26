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
	"LCS: line is not matched → #added (green). Old line becomes a removal (arrow at gap pos 2)."
	morph setTextWith: 'modified1
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#added #unchanged #unchanged) asArray.
	self assert: ruler removedPositions asArray equals: #(2)
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
	"LCS: only 'inserted' is unmatched → #added at position 2"
	morph setTextWith: 'line1
inserted
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #added #unchanged #unchanged) asArray.
	self assert: ruler removedPositions isEmpty
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLastLineReplaced [
	"LCS: 'modified3' is unmatched → #added. Old line3 becomes trailing removal (arrow after last line)."
	morph setTextWith: 'line1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #unchanged #added) asArray.
	self assert: ruler removedPositions asArray equals: #(4)
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
	"Trailing baseline lines are recorded as removal gaps at dstIdx"
	morph setTextWith: 'line1'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged) asArray.
	self assert: ruler removedPositions asArray equals: #(2 2)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testMultipleLinesReplaced [
	"LCS: both replaced lines are unmatched → #added. Old lines become removals at gaps."
	morph setTextWith: 'modified1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#added #unchanged #added) asArray.
	self assert: ruler removedPositions asArray equals: #(2 4)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionsAfterDeletion [
	"Deleting trailing line records the removal gap after last current line"
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
	"Multiple trailing deletions all record as gaps at the same dstIdx"
	ruler baseline: 'a
b
c
d
e'.
	morph setTextWith: 'a
b'.
	ruler computeLineStates.
	self assert: ruler removedPositions asArray equals: #(3 3 3)
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testRemovedPositionInsideText [
	"Deletion between two remaining lines shows arrow at the gap"
	ruler baseline: 'line1
line2
line3'.
	morph setTextWith: 'line1
line3'.
	ruler computeLineStates.
	self assert: ruler lineStates equals: #(#unchanged #unchanged) asArray.
	self assert: ruler removedPositions asArray equals: #(2)
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
