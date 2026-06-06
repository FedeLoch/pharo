"
I am a FindReplace service that uses a RubFindReplaceSearchBar for finding and replacing text in a text area.
"
Class {
	#name : 'SpRubFindReplaceService',
	#superclass : 'FindReplaceService',
	#instVars : [
		'dialog',
		'dialogWindow',
		'textAreaHolder'
	],
	#category : 'Rubric-SpecFindReplaceDialog',
	#package : 'Rubric-SpecFindReplaceDialog'
}

{ #category : 'accessing' }
SpRubFindReplaceService >> caseSensitive [
	^ caseSensitive ifNil: [caseSensitive := RubAbstractTextArea caseSensitiveFinds]
]

{ #category : 'accessing' }
SpRubFindReplaceService >> dialog [

	^ dialog
]

{ #category : 'services' }
SpRubFindReplaceService >> dialogIsActiveFor: aTextArea [
    ^ dialog isNotNil
        and: [ self textArea = aTextArea and: [ dialog world isNotNil ] ]
]

{ #category : 'accessing' }
SpRubFindReplaceService >> dialogWindow [

	^ dialogWindow
]

{ #category : 'events handling' }
SpRubFindReplaceService >> discardDialog [

	dialog := nil.
	dialogWindow := nil
]

{ #category : 'services' }
SpRubFindReplaceService >> find [
	| where |
	self setStartIndex.
	where := self findAndSelectRegex.
	where ifNil: [ self textArea flash ].
	^ where
]

{ #category : 'services' }
SpRubFindReplaceService >> findAndSelect [
	| where |
	findStartIndex > 0
		ifTrue: [ where := self textArea
				findAndSelect: self findRegex
				startingAt: findStartIndex
				searchBackwards: self searchBackwards ].
	(where isNil and: [ self wrapAround ])
		ifTrue: [ | idx |
			idx := self searchBackwards
				ifTrue: [ self textArea editor string size ]
				ifFalse: [ 1 ].
			where := self textArea
				findAndSelect: self findRegex
				startingAt: idx
				searchBackwards: self searchBackwards ].
	^ where
]

{ #category : 'services' }
SpRubFindReplaceService >> findAndSelectRegex [
	^ self findRegex ifNotNil: [ self findAndSelect ]
]

{ #category : 'services' }
SpRubFindReplaceService >> positionForSearchBar [
	| ta worldBounds |
	ta := self textArea.
	ta ifNil: [ ^ 0 @ 0 ].
	worldBounds := ta boundsInWorld.
	^ (worldBounds topRight x - 380) @ (worldBounds topRight y)
]

{ #category : 'services' }
SpRubFindReplaceService >> findNext [

	^ nil
]

{ #category : 'updating' }
SpRubFindReplaceService >> findPolicyChanged [
]

{ #category : 'accessing' }
SpRubFindReplaceService >> findText: aStringOrText [

	super findText: aStringOrText.
	self textArea ifNotNil: [:textArea | textArea whenFindTextChanged: RubFindTextChanged new].
	^ true
]

{ #category : 'initialization' }
SpRubFindReplaceService >> initialize [
	super initialize.

	textAreaHolder := WeakArray new: 1
]

{ #category : 'events handling' }
SpRubFindReplaceService >> openDialog [
	| bar |
	bar := RubFindReplaceSearchBar new.
	bar service: self.
	dialog := bar.
	bar openInWorld.
	bar position: self positionForSearchBar.
	bar findField takeKeyboardFocus
]

{ #category : 'services' }
SpRubFindReplaceService >> replace [
	findStartIndex := self searchBackwards
		ifTrue: [self textArea editor stopIndex]
		ifFalse: [self textArea editor startIndex].
	(self find)
		ifNotNil: [self textArea replaceSelectionWith: self replaceText]
]

{ #category : 'services' }
SpRubFindReplaceService >> replaceAll [
	| startIdx |
	startIdx := self wrapAround ifTrue: [1] ifFalse: [self textArea editor selectionInterval first].
	self textArea replaceAll: self findRegex with: self replaceText startingAt: startIdx
]

{ #category : 'accessing' }
SpRubFindReplaceService >> searchBackwards: aBoolean [
	searchBackwards := aBoolean.
	self updateFindStartIndex.
	self findPolicyChanged
]

{ #category : 'updating' }
SpRubFindReplaceService >> setStartIndex [
	findStartIndex
		ifNil: [ findStartIndex := self searchBackwards
				ifTrue: [ self textArea editor stopIndex ]
				ifFalse: [ self textArea editor startIndex ] ]
]

{ #category : 'services' }
SpRubFindReplaceService >> textArea [
	^ textAreaHolder at: 1
]

{ #category : 'services' }
SpRubFindReplaceService >> textArea: aTextArea [
	| oldTextArea |
	oldTextArea := textAreaHolder at: 1 ifAbsent: nil.
	oldTextArea == aTextArea ifTrue: [ ^ self ].
	oldTextArea ifNotNil: [ oldTextArea announcer unsubscribe: self ].
	textAreaHolder at: 1 put: aTextArea.
	aTextArea announcer
		when: RubFindReplaceWindowRequired send: #whenFindReplaceWindowRequired: to: self
]

{ #category : 'updating' }
SpRubFindReplaceService >> updateFindStartIndex [
	| si |
	self textArea
		ifNil: [ ^self ]
		ifNotNil: [ :aTextArea |
			aTextArea changed.
			self changed: #replaceEnabled.
			si := aTextArea selectionInterval.
			self findStartIndex: (self searchBackwards ifTrue: [si first - 1] ifFalse: [si last + 1]) ]
]

{ #category : 'user-interface' }
SpRubFindReplaceService >> whenDialogDeleted [
	dialog := nil
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenFindReplaceWindowRequired: anAnnouncement [
	(self dialogIsActiveFor: self textArea)
		ifTrue: [
			dialog findField takeKeyboardFocus.
			^ self ].
	self textArea hasSelection
		ifTrue: [ self findText: self textArea selection ].
	self openDialog
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenTextAreaGotFocus: anAnnounce [
	self textArea: anAnnounce morph
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenTextAreaLostFocus: anAnnounce [
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenTextAreaSelectionChanged: anAnnouncement [
	self updateFindStartIndex
]
