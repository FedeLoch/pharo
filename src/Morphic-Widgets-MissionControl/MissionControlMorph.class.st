Class {
	#name : 'MissionControlMorph',
	#superclass : 'Morph',
	#instVars : [
		'thumbnails',
		'spacesBar',
		'isActive',
		'scrollOffset'
	],
	#category : 'Morphic-Widgets-MissionControl',
	#package : 'Morphic-Widgets-MissionControl'
}

{ #category : 'activation' }
MissionControlMorph class >> toggleInWorld: aWorld [
	| current |
	current := aWorld submorphs
		detect: [ :m | m isKindOf: self ]
		ifNone: [ nil ].
	current
		ifNil: [ self new activateInWorld: aWorld ]
		ifNotNil: [ current deactivate ]
]

{ #category : 'activation' }
MissionControlMorph >> activateInWorld: aWorld [
	| nonCollapsed collapsed |
	nonCollapsed := (aWorld systemWindows select: [ :w | w isCollapsed not ]).
	collapsed := (aWorld systemWindows select: [ :w | w isCollapsed ]).
	self bounds: aWorld bounds.
	self clipSubmorphs: true.
	spacesBar := MissionControlSpacesBar new
		initializeForWorld: aWorld
		collapsedWindows: collapsed.
	self addMorph: spacesBar.
	self createThumbnailsFor: nonCollapsed.
	aWorld addMorphFront: self.
	aWorld activeHand newKeyboardFocus: self.
	isActive := true
]

{ #category : 'activation' }
MissionControlMorph >> deactivate [
	| w |
	w := self world.
	self delete.
	isActive := false.
	w ifNotNil: [ w activeHand newKeyboardFocus: nil ]
]

{ #category : 'activation' }
MissionControlMorph >> deactivateAndShowWindow: aSystemWindow [
	| w |
	w := self world.
	self delete.
	isActive := false.
	w ifNotNil: [ w activeHand newKeyboardFocus: nil ].
	aSystemWindow
		unexpandedFrame: aSystemWindow fullFrame;
		activate;
		fullscreen
]

{ #category : 'accessing' }
MissionControlMorph >> thumbnails [
	^ thumbnails
]

{ #category : 'accessing' }
MissionControlMorph >> spacesBar [
	^ spacesBar
]

{ #category : 'accessing' }
MissionControlMorph >> isActive [
	^ isActive
]

{ #category : 'private' }
MissionControlMorph >> createThumbnailsFor: windows [
	| padding n minCellW cols rows cellW cellH labelHeight gridHeight |
	thumbnails := OrderedCollection new.
	scrollOffset := 0.
	n := windows size.
	n = 0 ifTrue: [ ^ self ].
	padding := MissionControlSettings thumbnailPadding.
	labelHeight := MissionControlSettings showWindowLabels
		ifTrue: [ StandardFonts defaultFont height + 4 ]
		ifFalse: [ 0 ].
	minCellW := 200.
	cols := ((self width - padding left - padding right) / minCellW) floor max: 1.
	rows := (n + cols - 1) // cols.
	cellW := (self width - padding left - padding right) / cols.
	cellH := (cellW * 0.75) max: 120.
	gridHeight := spacesBar height + padding top + (rows * (cellH + labelHeight)) + padding bottom.
	self setProperty: #totalContentHeight toValue: gridHeight.
	windows withIndexDo: [ :w :i |
		| col row thumbnail scale thumbExtent cellLeft cellTop basePos |
		col := (i - 1) \\ cols.
		row := (i - 1) // cols.
		scale := (cellW / w extent x) min: (cellH / w extent y) min: 1.0.
		thumbExtent := (w extent * scale) rounded.
		thumbnail := MissionControlThumbnailMorph new
			initializeForWindow: w extent: thumbExtent.
		self addMorph: thumbnail.
		thumbnails add: thumbnail.
		cellLeft := padding left + (col * cellW).
		cellTop := spacesBar height + padding top + (row * (cellH + labelHeight)).
		basePos := cellLeft @ cellTop.
		thumbnail setProperty: #basePosition toValue: basePos.
		thumbnail position: basePos.
		MissionControlSettings showWindowLabels ifTrue: [
			thumbnail buildLabel ]
	]
]

{ #category : 'event handling' }
MissionControlMorph >> handlesMouseDown: evt [
	^ true
]

{ #category : 'event handling' }
MissionControlMorph >> handleMouseDown: evt [
	| clicked |
	evt wasHandled ifTrue: [ ^ self ].
	(spacesBar bounds containsPoint: evt position) ifTrue: [ ^ self ].
	clicked := thumbnails detect: [ :t |
		t bounds containsPoint: evt position ] ifNone: [ nil ].
	clicked ifNotNil: [ ^ self deactivateAndShowWindow: clicked window ].
	self deactivate
]

{ #category : 'event handling' }
MissionControlMorph >> handlesKeyboard: evt [
	^ true
]

{ #category : 'event handling' }
MissionControlMorph >> handlesKeyDown: evt [
	^ true
]

{ #category : 'event handling' }
MissionControlMorph >> keyDown: evt [
	evt keyCharacter = Character escape ifTrue: [ ^ self deactivate ]
]

{ #category : 'event handling' }
MissionControlMorph >> handlesMouseWheel: evt [
	^ (self valueOfProperty: #totalContentHeight ifAbsent: [0]) > self height
]

{ #category : 'event handling' }
MissionControlMorph >> mouseWheel: evt [
	| contentHeight visibleHeight maxOff step |
	evt wasHandled ifTrue: [ ^ self ].
	contentHeight := self valueOfProperty: #totalContentHeight ifAbsent: [0].
	visibleHeight := self height - spacesBar height.
	maxOff := (contentHeight - visibleHeight) max: 0.
	maxOff = 0 ifTrue: [ ^ self ].
	step := 60.
	evt isDown ifTrue: [
		scrollOffset := (scrollOffset + step) min: maxOff ].
	evt isUp ifTrue: [
		scrollOffset := (scrollOffset - step) max: 0 ].
	self applyScrollOffset
]

{ #category : 'private' }
MissionControlMorph >> applyScrollOffset [
	thumbnails do: [ :t |
		| basePos |
		basePos := t valueOfProperty: #basePosition.
		basePos ifNotNil: [
			t position: basePos x @ (basePos y - scrollOffset) ]
	]
]

{ #category : 'wiw support' }
MissionControlMorph >> morphicLayerNumber [
	^ 5
]

{ #category : 'accessing' }
MissionControlMorph >> wantsToBeTopmost [
	^ true
]

{ #category : 'drawing' }
MissionControlMorph >> drawOn: aCanvas [
	aCanvas
		fillRectangle: self bounds
		fillStyle: (SolidFillStyle color: (Color black alpha: MissionControlSettings overlayOpacity))
]
