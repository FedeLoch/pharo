"
I am a find/replace service that creates a RubFindReplaceWidget (inline find bar)
instead of the old dialog-based RubFindReplaceDialogWindow.
"
Class {
	#name : 'RubFindReplaceService',
	#superclass : 'FindReplaceService',
	#instVars : [
		'widget',
		'textAreaHolder'
	],
	#category : 'Rubric-Editing-FindReplaceService',
	#package : 'Rubric',
	#tag : 'Editing-FindReplaceService'
}

{ #category : 'accessing' }
RubFindReplaceService >> caseSensitive [
	^ caseSensitive ifNil: [caseSensitive := RubAbstractTextArea caseSensitiveFinds]
]

{ #category : 'user-interface' }
RubFindReplaceService >> dialog [
	^ self widget
]

{ #category : 'user-interface' }
RubFindReplaceService >> dialogIsActiveFor: aTextArea [
	widget ifNil: [ ^ false ].
	^ (self textArea = aTextArea) and: [ widget visible ] 
]

{ #category : 'services' }
RubFindReplaceService >> find [
	| where |
	self setStartIndex.
	where := self findAndSelectRegex.
	where ifNil: [ self textArea flash ].
	^ where
]

{ #category : 'private' }
RubFindReplaceService >> findAndSelect [
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

{ #category : 'private' }
RubFindReplaceService >> findAndSelectRegex [
	^ self findRegex ifNotNil: [ self findAndSelect ]
]

{ #category : 'services' }
RubFindReplaceService >> findNext [
	| where |
	findStartIndex
		ifNil: [findStartIndex := self textArea editor startIndex].
	findStartIndex > 0
		ifTrue: [where := self textArea findNextString: self findString startingAt: findStartIndex].
	(where isNil and: [self wrapAround])
		ifTrue: [where := self textArea findNextString: self findString asString startingAt: 1].
	^ where
]

{ #category : 'updating' }
RubFindReplaceService >> findPolicyChanged [
	self textArea ifNotNil: [ :ta | ta whenFindTextChanged: RubFindTextChanged new ]
]

{ #category : 'accessing' }
RubFindReplaceService >> findText: aStringOrText [
	super findText: aStringOrText.
	self textArea ifNotNil: [:textArea | textArea whenFindTextChanged: RubFindTextChanged new].
	^ true
]

{ #category : 'accessing' }
RubFindReplaceService >> findTextSilently: aStringOrText [
	findText := aStringOrText asText.
	self findPolicyChanged
]

{ #category : 'initialization' }
RubFindReplaceService >> initialize [
	super initialize.
	textAreaHolder := WeakArray new: 1
]

{ #category : 'user-interface' }
RubFindReplaceService >> newWidget [
	| w |
	w := RubFindReplaceWidget new.
	w service: self.
	w textArea: self textArea.
	^ w
]

{ #category : 'services' }
RubFindReplaceService >> replace [
	findStartIndex := self searchBackwards
		ifTrue: [self textArea editor stopIndex]
		ifFalse: [self textArea editor startIndex].
	(self find)
		ifNotNil: [self textArea replaceSelectionWith: self replaceText]
]

{ #category : 'services' }
RubFindReplaceService >> replaceAll [
	| startIdx |
	startIdx := self wrapAround ifTrue: [1] ifFalse: [self textArea editor selectionInterval first].
	self textArea replaceAll: self findRegex with: self replaceText startingAt: startIdx
]

{ #category : 'accessing' }
RubFindReplaceService >> searchBackwards: aBoolean [
	searchBackwards := aBoolean.
	self updateFindStartIndex.
	self findPolicyChanged
]

{ #category : 'private' }
RubFindReplaceService >> setStartIndex [
	findStartIndex
		ifNil: [ findStartIndex := self searchBackwards
				ifTrue: [ self textArea editor stopIndex ]
				ifFalse: [ self textArea editor startIndex ] ]
]

{ #category : 'accessing' }
RubFindReplaceService >> textArea [
	^ textAreaHolder at: 1
]

{ #category : 'accessing' }
RubFindReplaceService >> textArea: aTextArea [
	textAreaHolder at: 1 put: aTextArea.
	aTextArea announcer
		when: RubFindReplaceWindowRequired send: #whenFindReplaceWindowRequired: to: self
]

{ #category : 'updating' }
RubFindReplaceService >> updateFindStartIndex [
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
RubFindReplaceService >> widget [
	^ widget ifNil: [
		widget := self newWidget ]
]

{ #category : 'events handling' }
RubFindReplaceService >> whenFindReplaceWindowRequired: anAnnouncement [
	self findText
		ifEmpty: [
			self textArea hasSelection
				ifTrue: [ self findText: self textArea selection ] ].
	self widget show
]

{ #category : 'events handling' }
RubFindReplaceService >> whenTextAreaGotFocus: anAnnounce [
	self textArea: anAnnounce morph.
	self findText: self findText.
	self changed: #findText.
	self changed: #caseSensitive.
	self changed: #replaceEnabled
]

{ #category : 'events handling' }
RubFindReplaceService >> whenTextAreaLostFocus: anAnnounce [
	widget ifNil: [ ^ self ].
	widget visible ifFalse: [ ^ self ].
	self textArea whenFindTextChanged: RubFindTextChanged new
]

{ #category : 'events handling' }
RubFindReplaceService >> whenTextAreaSelectionChanged: anAnnouncement [
	self updateFindStartIndex
]
