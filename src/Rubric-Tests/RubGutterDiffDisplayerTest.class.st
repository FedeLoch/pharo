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
	"Replaced content at the same position shows as #added (LCS diff)"
	morph setTextWith: 'modified1
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#added #unchanged #unchanged) asArray
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
	morph setTextWith: 'line1
inserted
line2
line3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #added #unchanged #unchanged) asArray
]

{ #category : 'tests' }
RubGutterDiffDisplayerTest >> testLastLineReplaced [
	"Replaced content at the same position shows as #added (LCS diff)"
	morph setTextWith: 'line1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#unchanged #unchanged #added) asArray
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
RubGutterDiffDisplayerTest >> testMultipleLinesReplaced [
	"Multiple lines replaced show as #added (LCS diff)"
	morph setTextWith: 'modified1
line2
modified3'.
	ruler computeLineStates.
	self
		assert: ruler lineStates
		equals: #(#added #unchanged #added) asArray
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
