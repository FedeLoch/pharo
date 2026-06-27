"
Unified inline diff preview (GitHub-style). Removed lines have a red background,
added lines a green background, matching DiffMorph's theme colors.
Consecutive same-type changes are merged into single blocks.
Removals appear before additions at the same position.

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

{ #category : 'private' }
RubGutterDiffPreviewMorph >> buildDiff [
	| baselineLines currentLines startIdx endIdx contextBaseline contextCurrent builder pairs themeColors patchText lines lineCount longestLine maxHeight popupWidth popupHeight |
	baselineLines := baselineText lines.
	currentLines := currentText lines.
	startIdx := (lineIndex - contextLines) max: 1.
	endIdx := (lineIndex + contextLines) min: currentLines size.
	contextBaseline := self extractContextFromLines: baselineLines start: startIdx end: endIdx.
	contextCurrent := self extractContextFromLines: currentLines start: startIdx end: endIdx.
	builder := TextDiffBuilder from: contextBaseline to: contextCurrent.
	pairs := OrderedCollection new.
	builder
		patchSequenceDoIfMatch: [ :s | pairs add: #match -> s ]
		ifInsert: [ :s | pairs add: #insert -> s ]
		ifRemove: [ :s | pairs add: #remove -> s ].
	pairs := self reorderPatchPairs: pairs.
	themeColors := UITheme current.
	patchText := Text streamContents: [ :stream |
		pairs do: [ :pair |
			pair key = #match ifTrue: [ self writeLine: pair value withBackground: nil on: stream ].
			pair key = #insert ifTrue: [ self writeLine: pair value withBackground: themeColors diffAdditionalLineBackgroundColor on: stream ].
			pair key = #remove ifTrue: [ self writeLine: pair value withBackground: themeColors diffRemovedLinesBackgroundColor on: stream ] ] ].
	lines := patchText asString lines.
	lineCount := lines size.
	longestLine := (lines collect: [ :each | each size ]) max ifNil: [ 0 ].
	popupWidth := ((longestLine * 8 + 70) min: previewWidth) max: 200.
	maxHeight := self world ifNotNil: [ :w | w height * 0.6 ] ifNil: [ 400 ].
	popupHeight := ((lineCount * 14 + 30) min: maxHeight) max: 100.
	diffMorph := RubScrolledTextMorph new
		extent: popupWidth @ popupHeight;
		setText: patchText;
		beNotWrapped;
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
		extent: popupWidth @ popupHeight;
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

{ #category : 'event handling' }
RubGutterDiffPreviewMorph >> handleListenEvent: anEvent [
	anEvent isMouseDown ifTrue: [
		(self bounds containsPoint: anEvent position) ifFalse: [
			self delete ] ]
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

{ #category : 'opening' }
RubGutterDiffPreviewMorph >> openInWorld [
	super openInWorld.
	self activeHand addEventListener: self
]

{ #category : 'accessing' }
RubGutterDiffPreviewMorph >> previewWidth: anInteger [
	previewWidth := anInteger
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> reorderPatchPairs: pairs [
	| result i |
	result := OrderedCollection new.
	i := 1.
	[i <= pairs size] whileTrue: [
		| pair |
		pair := pairs at: i.
		((pair key = #insert) and: [
			(i < pairs size) and: [ (pairs at: i + 1) key = #remove ] ]) ifTrue: [
				"Swap: output remove first, then insert (GitHub-style unified diff)"
				result add: (pairs at: i + 1).
				result add: pair.
				i := i + 2 ] ifFalse: [
				"Merging: if same type as previous, concatenate"
				result isEmpty ifTrue: [ result add: pair ] ifFalse: [
					| last |
					last := result last.
					last key = pair key
						ifTrue: [ result at: result size put: (last key -> (last value, String cr, pair value)) ]
						ifFalse: [ result add: pair ] ].
				i := i + 1 ] ].
	^ result
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
