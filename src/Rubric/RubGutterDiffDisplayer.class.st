"
I display visual indicators in the editor gutter showing lines that differ from the baseline
(typically the last committed version). I sit at level 3 (leftmost) in the gutter.

Visual feedback per state:
  - #added:    green bar spanning the full line height
  - #modified: blue bar spanning the full line height
  - #removed:  small red right-pointing arrow (▶) aligned to the line

Instance Variables:
  baseline         <String> Cached original text to diff against
  baselineProvider <RubMethodBaselineProvider> Pluggable provider for the baseline
  lineStates       <Array of Symbol> Per-line state: #unchanged, #added, #modified
  removedPositions <OrderedCollection> 1-indexed positions in current text where a removed-line arrow should appear
  previewMorph     <RubGutterDiffPreviewMorph> Currently visible diff popup (or nil)
  editingMethod    <CompiledMethod> The method being edited (for baseline fetching)
"
Class {
	#name : 'RubGutterDiffDisplayer',
	#superclass : 'RubScrolledTextSideRuler',
	#instVars : [
		'baseline',
		'baselineProvider',
		'lineStates',
		'removedPositions',
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

{ #category : 'initialization' }
RubGutterDiffDisplayer >> initialize [
	super initialize.
	removedPositions := OrderedCollection new
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
	aSymbol = #added ifTrue: [ ^ Color green alpha: 0.5 ].
	aSymbol = #modified ifTrue: [ ^ Color blue alpha: 0.5 ].
	aSymbol = #removed ifTrue: [ ^ Color red ].
	^ Color transparent
]

{ #category : 'private' }
RubGutterDiffDisplayer >> computeLineStates [
	| currentText currentLines baselineLines common |
	baseline ifNil: [ ^ self ].
	self textArea ifNil: [ ^ self ].
	currentText := self textArea text asString.
	currentLines := currentText lines.
	baselineLines := baseline lines.
	lineStates := Array new: currentLines size withAll: #unchanged.
	removedPositions := OrderedCollection new.
	common := baselineLines size min: currentLines size.
	1 to: common do: [ :i |
		(baselineLines at: i) ~= (currentLines at: i)
			ifTrue: [ lineStates at: i put: #modified ] ].
	common + 1 to: currentLines size do: [ :i |
		lineStates at: i put: #added ].
	common + 1 to: baselineLines size do: [ :i |
		| pos |
		pos := i min: currentLines size.
		pos > 0 ifTrue: [ removedPositions add: pos ] ]
]

{ #category : 'geometry' }
RubGutterDiffDisplayer >> computedWidthFrom: aRectangle [
	^ (self indicatorWidth + self horizontalGapBefore + self horizontalGapAfter + self verticalSeparatorWidth) truncated
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawOn: aCanvas [
	| lines visibleRectangle firstLine lastLine |
	super drawOn: aCanvas.
	self paragraph ifNil: [ ^ self ].
	self paragraph lines ifNil: [ ^ self ].
	lineStates ifNil: [ ^ self ].
	lines := self lines.
	aCanvas
		clipBy: self bounds
		during: [ :clippedCanvas |
			clippedCanvas fillRectangle: self verticalSeparatorBounds color: self verticalSeparatorColor.
			visibleRectangle := clippedCanvas clipRect.
			firstLine := self lineIndexForPoint: visibleRectangle topLeft.
			lastLine := self lineIndexForPoint: visibleRectangle bottomRight.
			firstLine to: lastLine do: [ :i |
				i > lineStates size ifTrue: [ ^ self ].
				(lineStates at: i) = #unchanged ifFalse: [
					self drawIndicatorBarOn: clippedCanvas forState: (lineStates at: i) atLine: (lines at: i) ] ].
			removedPositions do: [ :pos |
				(pos between: firstLine and: lastLine) ifTrue: [
					pos <= lines size ifTrue: [
						self drawRemovedArrowOn: clippedCanvas atLine: (lines at: pos) ] ] ] ]
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawOnAthensCanvas: aCanvas [
	| lines visibleRectangle firstLine lastLine |
	super drawOnAthensCanvas: aCanvas.
	self paragraph ifNil: [ ^ self ].
	self paragraph lines ifNil: [ ^ self ].
	lineStates ifNil: [ ^ self ].
	lines := self lines.
	aCanvas
		clipBy: self bounds
		during: [
			aCanvas setShape: self verticalSeparatorBounds.
			aCanvas setPaint: self verticalSeparatorColor.
			aCanvas draw.
			visibleRectangle := aCanvas clipRect.
			firstLine := self lineIndexForPoint: visibleRectangle topLeft.
			lastLine := self lineIndexForPoint: visibleRectangle bottomRight.
			firstLine to: lastLine do: [ :i |
				i > lineStates size ifTrue: [ ^ self ].
				(lineStates at: i) = #unchanged ifFalse: [
					self drawIndicatorBarOnAthens: aCanvas forState: (lineStates at: i) atLine: (lines at: i) ] ].
			removedPositions do: [ :pos |
				(pos between: firstLine and: lastLine) ifTrue: [
					pos <= lines size ifTrue: [
						self drawRemovedArrowOnAthens: aCanvas atLine: (lines at: pos) ] ] ] ]
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawIndicatorBarOn: aCanvas forState: aSymbol atLine: line [
	| indicatorColor indicatorBounds |
	indicatorColor := self colorForState: aSymbol.
	indicatorBounds := (self bounds left + self horizontalGapBefore) @ (line top + 2)
		corner: (self bounds left + self horizontalGapBefore + self indicatorWidth) @ (line bottom - 2).
	indicatorBounds := indicatorBounds
		translateBy: 0 @ (self offset y negated + self bounds top).
	aCanvas fillRectangle: indicatorBounds color: indicatorColor
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawIndicatorBarOnAthens: aCanvas forState: aSymbol atLine: line [
	| indicatorColor indicatorBounds |
	indicatorColor := self colorForState: aSymbol.
	indicatorBounds := (self bounds left + self horizontalGapBefore) @ (line top + 2)
		corner: (self bounds left + self horizontalGapBefore + self indicatorWidth) @ (line bottom - 2).
	indicatorBounds := indicatorBounds
		translateBy: 0 @ (self offset y negated + self bounds top).
	aCanvas setShape: indicatorBounds.
	aCanvas setPaint: indicatorColor.
	aCanvas draw
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawRemovedArrowOn: aCanvas atLine: line [
	| arrowSize leftX lineMidY topY botY off |
	arrowSize := self indicatorWidth.
	leftX := self bounds left + self horizontalGapBefore.
	lineMidY := (line top + line bottom) // 2.
	topY := lineMidY - (arrowSize // 2).
	botY := lineMidY + (arrowSize // 2).
	off := self offset y negated + self bounds top.
	aCanvas drawPolygon: {
		leftX @ (topY + off).
		(leftX + arrowSize) @ (lineMidY + off).
		leftX @ (botY + off)
	} fillStyle: Color red
]

{ #category : 'drawing' }
RubGutterDiffDisplayer >> drawRemovedArrowOnAthens: aCanvas atLine: line [
	| arrowSize leftX lineMidY topY botY off |
	arrowSize := self indicatorWidth.
	leftX := self bounds left + self horizontalGapBefore.
	lineMidY := (line top + line bottom) // 2.
	topY := lineMidY - (arrowSize // 2).
	botY := lineMidY + (arrowSize // 2).
	off := self offset y negated + self bounds top.
	aCanvas setShape: (aCanvas createPath: [ :builder |
		builder absolute.
		builder moveTo: leftX @ (topY + off).
		builder lineTo: (leftX + arrowSize) @ (lineMidY + off).
		builder lineTo: leftX @ (botY + off).
		builder close ]).
	aCanvas setPaint: Color red.
	aCanvas draw
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> editingMethod [
	^ editingMethod
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> editingMethod: aCompiledMethod [
	editingMethod := aCompiledMethod
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

{ #category : 'accessing' }
RubGutterDiffDisplayer >> lineStates [
	^ lineStates
]

{ #category : 'accessing' }
RubGutterDiffDisplayer >> removedPositions [
	^ removedPositions
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
