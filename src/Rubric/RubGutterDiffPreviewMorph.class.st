"
Unified inline diff preview like DiffMorph but inline (not side-by-side).
Removed lines have a red background, added lines a green background.
For modifications (both old and new content at the same position),
InlineTextDiffBuilder gives per-token highlighting: matched tokens use
the line-level color, changed tokens use a stronger alpha.
Consecutive same-type lines are merged into blocks.
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
	| builder rawPairs blocks themeColors patchText lines lineCount longestLine maxHeight popupWidth popupHeight targetPatchLine |
	builder := TextDiffBuilder from: baselineText to: currentText.
	rawPairs := builder buildPatchSequence.
	blocks := self segmentIntoBlocks: rawPairs.
	targetPatchLine := self
		computeTargetPatchLineFromBlocks: blocks
		startIdx: 1
		lineIndex: lineIndex.
	themeColors := UITheme current.
	patchText := Text streamContents: [ :stream |
		blocks do: [ :block | self writeBlock: block withTheme: themeColors on: stream ] ].
	patchText size > 0 ifTrue: [ patchText := patchText copyFrom: 1 to: patchText size - 1 ].
	lines := patchText asString lines.
	lineCount := lines size.
	longestLine := (lines collect: [ :each | each size ]) max ifNil: [ 0 ].
	popupWidth := ((longestLine * 8 + 70) min: previewWidth) max: 200.
	maxHeight := self world ifNotNil: [ :w | w height * 0.6 ] ifNil: [ 400 ].
	popupHeight := ((5 min: lineCount) * 14 + 30) min: maxHeight max: 100.
	diffMorph := RubScrolledTextMorph new
		extent: popupWidth @ popupHeight;
		setText: patchText;
		beNotWrapped;
		withLineNumbers;
		yourself.
	targetPatchLine ifNotNil: [
		| textLines textLine currentOffset viewportHeight centerY targetY |
		textLines := diffMorph paragraph lines.
		targetPatchLine <= textLines size ifTrue: [
			textLine := textLines at: targetPatchLine.
			currentOffset := diffMorph scrollPane offset.
			viewportHeight := diffMorph scrollPane scrollBounds height.
			centerY := textLine top + (textLine height / 2).
			targetY := (centerY - (viewportHeight / 2)) max: 0.
			diffMorph scrollPane scrollBy: 0 @ (currentOffset y - targetY) ] ].
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

{ #category : 'private' }
RubGutterDiffPreviewMorph >> computeTargetPatchLineFromBlocks: blocks startIdx: startIdx lineIndex: lineIndex [
	"Walk through diff blocks and find the patch text line number
	corresponding to the clicked line at lineIndex in the current text.
	For non-match blocks (changes), scroll to the first line of the block
	so both old and new content of a modification are visible together."
	| clickedContextPos currentLinesSeen patchLines |
	clickedContextPos := lineIndex - startIdx + 1.
	currentLinesSeen := 0.
	patchLines := 0.
	blocks do: [ :block |
		(block first key = #match) ifTrue: [
			patchLines := patchLines + 1.
			currentLinesSeen := currentLinesSeen + 1.
			currentLinesSeen >= clickedContextPos ifTrue: [ ^ patchLines ]
		] ifFalse: [
			| blockStart |
			blockStart := patchLines + 1.
			block do: [ :pair |
				patchLines := patchLines + 1.
				pair key = #remove ifFalse: [
					currentLinesSeen := currentLinesSeen + 1.
					currentLinesSeen >= clickedContextPos ifTrue: [ ^ blockStart ] ] ] ] ].
	^ nil
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
	(anEvent isKindOf: MouseButtonEvent) ifFalse: [ ^ self ].
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
RubGutterDiffPreviewMorph >> segmentIntoBlocks: pairs [
	| blocks currentBlock |
	blocks := OrderedCollection new.
	currentBlock := nil.
	pairs do: [ :pair |
		pair key = #match ifTrue: [
			currentBlock ifNotNil: [
				blocks add: currentBlock asArray.
				currentBlock := nil ].
			blocks add: { pair } ].
		pair key ~= #match ifTrue: [
			currentBlock ifNil: [ currentBlock := OrderedCollection new ].
			currentBlock add: pair ] ].
	currentBlock ifNotNil: [ blocks add: currentBlock asArray ].
	^ blocks asArray
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> writeBlock: block withTheme: themeColors on: stream [
	block first key = #match ifTrue: [
		^ self writeLine: block first value withBackground: nil on: stream ].
	(block anySatisfy: [ :p | p key = #remove ]) ifTrue: [
		(block anySatisfy: [ :p | p key = #insert ]) ifTrue: [
			^ self writeModificationBlock: block withTheme: themeColors on: stream ].
		^ block do: [ :p |
			self writeLine: p value withBackground: themeColors diffRemovedLinesBackgroundColor on: stream ] ].
	block do: [ :p |
		self writeLine: p value withBackground: themeColors diffAdditionalLineBackgroundColor on: stream ]
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

{ #category : 'private' }
RubGutterDiffPreviewMorph >> writeModificationBlock: block withTheme: themeColors on: stream [
	| removes inserts i |
	removes := block select: [ :p | p key = #remove ].
	inserts := block select: [ :p | p key = #insert ].
	i := 1.
	removes do: [ :removePair |
		i <= inserts size
			ifTrue: [
				| oldLine newLine |
				oldLine := removePair value.
				newLine := (inserts at: i) value.
				self
					writeTokenDiff: oldLine
					against: newLine
					forSide: #remove
					background: themeColors diffRemovedLinesBackgroundColor
					highlight: (themeColors diffRemovedLinesBackgroundColor alpha: 0.5)
					on: stream.
				self
					writeTokenDiff: oldLine
					against: newLine
					forSide: #insert
					background: themeColors diffAdditionalLineBackgroundColor
					highlight: (themeColors diffAdditionalLineBackgroundColor alpha: 0.5)
					on: stream.
				i := i + 1 ]
			ifFalse: [
				self writeLine: removePair value
					withBackground: themeColors diffRemovedLinesBackgroundColor
					on: stream ] ].
	i to: inserts size do: [ :j |
		self writeLine: (inserts at: j) value
			withBackground: themeColors diffAdditionalLineBackgroundColor
			on: stream ]
]

{ #category : 'private' }
RubGutterDiffPreviewMorph >> writeTokenDiff: lineString against: otherString forSide: sideSymbol background: bgColor highlight: hlColor on: stream [
	| diffs groups |
	diffs := (InlineTextDiffBuilder from: lineString to: otherString) buildPatchSequence.
	groups := diffs groupByRuns: [ :e | e key ].
	groups do: [ :group |
		| groupKey |
		groupKey := group first key.
		groupKey = #match ifTrue: [
			group do: [ :each |
				stream
					withAttributes: { TextBackgroundColor color: bgColor }
					do: [ stream nextPutAll: each value ] ] ].
		groupKey = sideSymbol ifTrue: [
			group do: [ :each |
				stream
					withAttributes: { TextBackgroundColor color: hlColor }
					do: [ stream nextPutAll: each value ] ] ] ].
	stream cr
]
