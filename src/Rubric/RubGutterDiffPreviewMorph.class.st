"
I am a compact popup morph showing a DiffMorph preview of a specific line range.
I appear when the user clicks on a changed line indicator in the gutter.

I show the original vs current version of the clicked line with N lines of context
(default: 3), using a side-by-side DiffMorph.

Dismissal: press Escape key or click outside the popup.
"
Class {
	#name : 'RubGutterDiffPreviewMorph',
	#superclass : 'Morph',
	#instVars : [
		'diffMorph',
		'lineIndex',
		'contextLines',
		'baselineText',
		'currentText',
		'closeButton'
	],
	#category : 'Rubric-Editing-Widgets',
	#package : 'Rubric',
	#tag : 'Editing-Widgets'
}

{ #category : 'instance creation' }
RubGutterDiffPreviewMorph class >> forLine: lineIndex baseline: baselineString current: currentString context: contextSize [
	^ self new
		lineIndex: lineIndex;
		baselineText: baselineString;
		currentText: currentString;
		contextLines: contextSize;
		buildDiff;
		yourself
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> baselineText [
	^ baselineText
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> baselineText: aString [
	baselineText := aString
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> buildDiff [
	| baselineLines currentLines startIdx endIdx contextBaseline contextCurrent |
	baselineLines := baselineText lines.
	currentLines := currentText lines.
	startIdx := (lineIndex - contextLines) max: 1.
	endIdx := (lineIndex + contextLines) min: currentLines size.
	contextBaseline := self extractContextFromLines: baselineLines start: startIdx end: endIdx.
	contextCurrent := self extractContextFromLines: currentLines start: startIdx end: endIdx.
	diffMorph := DiffMorph from: contextBaseline to: contextCurrent.
	diffMorph
		hResizing: #spaceFill;
		vResizing: #spaceFill;
		extent: 400 @ 200.
	self
		changeProportionalLayout;
		addMorph: diffMorph
		fullFrame: (LayoutFrame identity
			topOffset: 0;
			bottomOffset: 0;
			leftOffset: 0;
			rightOffset: 0);
		extent: 400 @ 200;
		color: Color white;
		borderWidth: 1;
		borderColor: Color gray
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> contextLines [
	^ contextLines
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> contextLines: anInteger [
	contextLines := anInteger
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> currentText [
	^ currentText
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> currentText: aString [
	currentText := aString
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> delete [
	super delete.
	self announcer ifNotNil: [ :ann | ann unsubscribe: self ]
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> extractContextFromLines: lines start: startIdx end: endIdx [
	^ String streamContents: [ :stream |
		startIdx to: endIdx do: [ :i |
			| line |
			line := lines at: i ifAbsent: [ '' ].
			stream nextPutAll: line.
			i < endIdx ifTrue: [ stream cr ] ] ]
]

{ #category : 'testing' }
RubGutterDiffPreviewMorph >> handlesKeyboard: evt [
	^ true
]

{ #category : 'initialization' }
RubGutterDiffPreviewMorph >> initialize [
	super initialize.
	self clipSubmorphs: true.
	contextLines := 3
]

{ #category : 'event handling' }
RubGutterDiffPreviewMorph >> keyDown: anEvent [
	anEvent keyCharacter = Character escape ifTrue: [
		self delete.
		^ true ].
	^ super keyDown: anEvent
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> lineIndex [
	^ lineIndex
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> lineIndex: anInteger [
	lineIndex := anInteger
]
