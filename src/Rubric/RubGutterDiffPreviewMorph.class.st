"
I show a side-by-side DiffMorph preview of the clicked line area.
No title panel or options panel (chrome removed).

Dismissal: click outside the popup, click in the method editor, or press Escape.
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
		'previewWidth'
	],
	#category : 'Rubric-Editing-Widgets',
	#package : 'Rubric',
	#tag : 'Editing-Widgets'
}

{ #category : 'instance creation' }
RubGutterDiffPreviewMorph class >> forLine: lineIndex baseline: baselineString current: currentString context: contextSize width: previewWidth [
	^ self new
		lineIndex: lineIndex;
		baselineText: baselineString;
		currentText: currentString;
		contextLines: contextSize;
		previewWidth: previewWidth;
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

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> previewWidth: anInteger [
	previewWidth := anInteger
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> buildDiff [
	| baselineLines currentLines startIdx endIdx contextBaseline contextCurrent builder patchText popupExtent themeColors |
	baselineLines := baselineText lines.
	currentLines := currentText lines.
	startIdx := (lineIndex - contextLines) max: 1.
	endIdx := (lineIndex + contextLines) min: currentLines size.
	contextBaseline := self extractContextFromLines: baselineLines start: startIdx end: endIdx.
	contextCurrent := self extractContextFromLines: currentLines start: startIdx end: endIdx.
	builder := TextDiffBuilder from: contextBaseline to: contextCurrent.
	themeColors := UITheme current.
	patchText := Text streamContents: [ :stream |
		builder
			patchSequenceDoIfMatch: [ :string |
				self writeLine: string withBackground: nil on: stream ]
			ifInsert: [ :string |
				self writeLine: string withBackground: themeColors diffAdditionalLineBackgroundColor on: stream ]
			ifRemove: [ :string |
				self writeLine: string withBackground: themeColors diffRemovedLinesBackgroundColor on: stream ] ].
	popupExtent := (previewWidth ifNil: [ 500 ]) @ 200.
	diffMorph := RubScrolledTextMorph new
		extent: popupExtent;
		setText: patchText;
		beWrapped;
		withLineNumbers;
		yourself.
	self
		changeProportionalLayout;
		addMorph: diffMorph
		fullFrame: (LayoutFrame identity
			topOffset: 0;
			bottomOffset: 0;
			leftOffset: 0;
			rightOffset: 0);
		extent: popupExtent;
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
	self activeHand ifNotNil: [ :hand | hand removeEventListener: self ].
	super delete
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

{ #category : 'private' }
RubGutterDiffPreviewMorph >> writeLine: aString withBackground: aColor on: stream [
	aColor ifNil: [
		stream nextPutAll: aString.
		(aString notEmpty and: [ aString last = Character cr ]) ifFalse: [ stream cr ].
		^ self ].
	stream
		withAttributes: { TextBackgroundColor color: aColor }
		do: [
			stream nextPutAll: aString.
			(aString notEmpty and: [ aString last = Character cr ]) ifFalse: [ stream cr ] ]
]

{ #category : 'testing' }
RubGutterDiffPreviewMorph >> handlesKeyboard: evt [
	^ true
]

{ #category : 'event handling' }
RubGutterDiffPreviewMorph >> handleListenEvent: anEvent [
	anEvent isMouseDown ifTrue: [
		(self bounds containsPoint: anEvent position) ifFalse: [
			self delete ] ]
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

{ #category : 'opening' }
RubGutterDiffPreviewMorph >> openInWorld [
	super openInWorld.
	self activeHand addEventListener: self
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> lineIndex [
	^ lineIndex
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> lineIndex: anInteger [
	lineIndex := anInteger
]
