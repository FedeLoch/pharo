"
I am a FindReplace service that uses the new inline RubFindReplaceWidget.
I replace the old SpRubFindReplaceDialog-based approach.
"
Class {
	#name : 'SpRubFindReplaceService',
	#superclass : 'FindReplaceService',
	#instVars : [
		'widget',
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
	^ self widget
]

{ #category : 'services' }
SpRubFindReplaceService >> dialogIsActiveFor: aTextArea [
	widget ifNil: [ ^ false ].
	^ (self textArea = aTextArea) and: [ widget visible ]
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

{ #category : 'user-interface' }
SpRubFindReplaceService >> newWidget [
	| w |
	w := RubFindReplaceWidget new.
	w service: self.
	w textArea: self textArea.
	^ w
]

{ #category : 'services' }
SpRubFindReplaceService >> openDialog [
	self widget show
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
SpRubFindReplaceService >> widget [
	^ widget ifNil: [
		widget := self newWidget ]
]

{ #category : 'user-interface' }
SpRubFindReplaceService >> whenDialogDeleted [
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenFindReplaceWindowRequired: anAnnouncement [
	self textArea hasSelection
		ifTrue: [ self findText: self textArea selection ].
	self widget show
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenTextAreaGotFocus: anAnnounce [
	self textArea: anAnnounce morph
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenTextAreaLostFocus: anAnnounce [
	widget ifNil: [ ^ self ].
	widget visible ifFalse: [ ^ self ].
	self textArea whenFindTextChanged: RubFindTextChanged new
]

{ #category : 'events handling' }
SpRubFindReplaceService >> whenTextAreaSelectionChanged: anAnnouncement [
	self updateFindStartIndex
]
