"
I display colored indicators in the editor gutter showing which lines have been added,
modified, or removed relative to a baseline version (typically the last commit).

I sit to the left of line numbers (level 3) and respond to mouse clicks to show
a DiffMorph preview popup (RubGutterDiffPreviewMorph) when a changed line is clicked.

Colors:
  - green: line was added
  - orange: line was modified
  - red: line was removed

Instance Variables:
  baseline        <String> Cached original text to diff against
  baselineProvider <RubMethodBaselineProvider> Pluggable provider for the baseline
  lineStates      <Array of Symbol> Per-line state: #unchanged, #added, #modified
  previewMorph    <RubGutterDiffPreviewMorph> Currently visible diff popup (or nil)
  editingMethod   <CompiledMethod> The method being edited (for baseline fetching)
"
Class {
	#name : 'RubGutterDiffDisplayer',
	#superclass : 'RubScrolledTextSideRuler',
	#instVars : [
		'baseline',
		'baselineProvider',
		'lineStates',
		'previewMorph',
		'editingMethod'
	],
	#category : 'Rubric-Editing-Widgets',
	#package : 'Rubric',
	#tag : 'Editing-Widgets'
}

{ #category : 'querying' }
RubGutterDiffDisplayer class >> key [
	^ #gutterDiff
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> baseline [
	^ baseline
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> baseline: aString [
	baseline := aString
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> baselineProvider [
	^ baselineProvider
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> baselineProvider: aProvider [
	baselineProvider := aProvider
]

{ #category : 'private' }
RubGutterDiffDisplayer >> colorForState: aSymbol [
	aSymbol = #added ifTrue: [ ^ Color green muchDarker alpha: 0.35 ].
	aSymbol = #modified ifTrue: [ ^ Color orange muchDarker alpha: 0.35 ].
	aSymbol = #removed ifTrue: [ ^ Color red muchDarker alpha: 0.35 ].
	^ Color transparent
]

{ #category : 'private' }
RubGutterDiffDisplayer >> computeLineStates [
	| currentText builder dstIdx |
	baseline ifNil: [ ^ self ].
	self textArea ifNil: [ ^ self ].
	currentText := self textArea text asString.
	lineStates := Array new: currentText lines size withAll: #unchanged.
	builder := TextDiffBuilder from: baseline to: currentText.
	dstIdx := 1.
	builder
		patchSequenceDoIfMatch: [ :yElement |
			dstIdx := dstIdx + 1 ]
		ifInsert: [ :yElement |
			dstIdx <= lineStates size ifTrue: [
				lineStates at: dstIdx put: #added ].
			dstIdx := dstIdx + 1 ]
		ifRemove: [ :xElement | "skip" ]
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> lineStates [
	^ lineStates
]

{ #category : 'geometry' }
RubGutterDiffDisplayer >> computedWidthFrom: aRectangle [
	^ (self indicatorWidth + self horizontalGapBefore + self horizontalGapAfter + self verticalSeparatorWidth) truncated
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawOn: aCanvas [
	| right lines visibleRectangle |
	super drawOn: aCanvas.
	self paragraph ifNil: [ ^ self ].
	self paragraph lines ifNil: [ ^ self ].
	lineStates ifNil: [ ^ self ].
	right := self bounds right.
	lines := self lines.
	aCanvas
		clipBy: self bounds
		during: [ :clippedCanvas |
			| sepBounds |
			sepBounds := self verticalSeparatorBounds.
			sepBounds ifNotNil: [
				clippedCanvas fillRectangle: sepBounds color: self verticalSeparatorColor ].
			visibleRectangle := clippedCanvas clipRect.
			(self lineIndexForPoint: visibleRectangle topLeft)
				to: (self lineIndexForPoint: visibleRectangle bottomRight)
				do: [ :i |
					| line state indicatorColor indicatorBounds |
					i > lineStates size ifTrue: [ ^ self ].
					state := lineStates at: i.
					state = #unchanged ifFalse: [
						line := lines at: i.
						indicatorColor := self colorForState: state.
						indicatorBounds := (self bounds left + self horizontalGapBefore) @ (line top + 2)
							corner: (self bounds left + self horizontalGapBefore + self indicatorWidth) @ (line bottom - 2).
						indicatorBounds := indicatorBounds
							translateBy: 0 @ (self offset y negated + self bounds top).
						clippedCanvas fillRectangle: indicatorBounds color: indicatorColor ] ] ]
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawOnAthensCanvas: aCanvas [
	| right lines visibleRectangle |
	super drawOnAthensCanvas: aCanvas.
	self paragraph ifNil: [ ^ self ].
	self paragraph lines ifNil: [ ^ self ].
	lineStates ifNil: [ ^ self ].
	right := self bounds right.
	lines := self lines.
	aCanvas
		clipBy: self bounds
		during: [
			| sepBounds |
			sepBounds := self verticalSeparatorBounds.
			sepBounds ifNotNil: [
				aCanvas setShape: sepBounds.
				aCanvas setPaint: self verticalSeparatorColor.
				aCanvas draw ].
			visibleRectangle := aCanvas clipRect.
			(self lineIndexForPoint: visibleRectangle topLeft)
				to: (self lineIndexForPoint: visibleRectangle bottomRight)
				do: [ :i |
					| line state indicatorColor indicatorBounds |
					i > lineStates size ifTrue: [ ^ self ].
					state := lineStates at: i.
					state = #unchanged ifFalse: [
						line := lines at: i.
						indicatorColor := self colorForState: state.
						indicatorBounds := (self bounds left + self horizontalGapBefore) @ (line top + 2)
							corner: (self bounds left + self horizontalGapBefore + self indicatorWidth) @ (line bottom - 2).
						indicatorBounds := indicatorBounds
							translateBy: 0 @ (self offset y negated + self bounds top).
						aCanvas setShape: indicatorBounds.
						aCanvas setPaint: indicatorColor.
						aCanvas draw ] ]
			]
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> editingMethod [
	^ editingMethod
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> editingMethod: aCompiledMethod [
	editingMethod := aCompiledMethod
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> handlesMouseDown: evt [
	^ true
]

{ #category : 'geometry' }
RubGutterDiffDisplayer >> horizontalGapAfter [
	^ 2
]

{ #category : 'geometry' }
RubGutterDiffDisplayer >> horizontalGapBefore [
	^ 2
]

{ #category : 'geometry' }
RubGutterDiffDisplayer >> indicatorWidth [
	^ 6
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> level [
	^ 3
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> mouseDown: anEvent [
	| lineIndex state |
	(anEvent yellowButtonPressed and: [ anEvent commandKeyPressed not ])
		ifTrue: [ ^ self yellowButtonActivity: anEvent shiftPressed ].
	lineStates ifNil: [ ^ self ].
	lineIndex := self lineIndexForPoint: anEvent position.
	lineIndex > lineStates size ifTrue: [ ^ self ].
	state := lineStates at: lineIndex.
	state = #unchanged ifTrue: [
		^ self forwardMouseEventToTextArea: anEvent ].
	self showPreviewAtLine: lineIndex
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> mouseMove: anEvent [
	self forwardMouseEventToTextArea: anEvent
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> mouseUp: anEvent [
	self forwardMouseEventToTextArea: anEvent
]

{ #category : 'private' }
RubGutterDiffDisplayer >> forwardMouseEventToTextArea: anEvent [
	| lineIndex line |
	lineIndex := self lineIndexForPoint: anEvent position.
	lineIndex > (self lines size) ifTrue: [ ^ self ].
	line := self lines at: lineIndex.
	anEvent setPosition: line topLeft.
	self textArea mouseDown: anEvent
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> previewMorph [
	^ previewMorph
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> previewMorph: aRubGutterDiffPreviewMorph [
	previewMorph := aRubGutterDiffPreviewMorph
]

{ #category : 'refreshing' }
RubGutterDiffDisplayer >> refreshBaseline [
	baselineProvider ifNil: [ ^ self ].
	editingMethod ifNil: [ ^ self ].
	baseline := baselineProvider
		baselineForMethod: editingMethod
		ifNone: [ self textArea text asString ].
	self computeLineStates.
	self changed
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> scrollerOffsetChanged [
	super scrollerOffsetChanged.
	previewMorph ifNotNil: [
		previewMorph delete.
		previewMorph := nil ]
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> selectionChanged [
	self changed
]

{ #category : 'private' }
RubGutterDiffDisplayer >> showPreviewAtLine: lineIndex [
	| currentText preview |
	previewMorph ifNotNil: [
		previewMorph delete.
		previewMorph := nil ].
	currentText := self textArea text asString.
	preview := RubGutterDiffPreviewMorph
		forLine: lineIndex
		baseline: (baseline ifNil: [ currentText ])
		current: currentText
		context: 3.
	preview openInWorld.
	preview position: self bounds topRight + (5 @ 0).
	previewMorph := preview
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> textChanged [
	self computeLineStates.
	super textChanged
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> verticalSeparatorBounds [
	| bnds |
	bnds := self bounds.
	^ self side = #left
		ifTrue: [ (bnds topRight - (self verticalSeparatorWidth @ 0)) corner: bnds bottomRight ]
		ifFalse: [ (bnds topLeft corner: bnds bottomLeft + (self verticalSeparatorWidth @ 0)) ]
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> verticalSeparatorColor [
	^ (self textArea backgroundColor contrastingBlackAndWhiteColor) alpha: 0.3
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> verticalSeparatorWidth [
	^ 1
]

{ #category : 'event handling' }
RubGutterDiffDisplayer >> yellowButtonActivity: shiftKeyState [
	^ true
]
