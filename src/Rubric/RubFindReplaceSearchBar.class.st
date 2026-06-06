"
I am a compact search bar for finding and replacing text in a text area.

I appear near the top-right of the text area and provide:
- A find text field with live matching as you type
- Match navigation via Enter/Shift+Enter and arrow buttons
- Match count display showing ''current/total''
- Toggle buttons for regular expression, case sensitive, whole words only
- An expandable replace mode with Replace and Replace All
- Close via Escape or the close button

I am managed by a RubFindReplaceService.
"
Class {
	#name : 'RubFindReplaceSearchBar',
	#superclass : 'BorderedMorph',
	#instVars : [
		'findField',
		'replaceField',
		'matchCountLabel',
		'regexButton',
		'caseButton',
		'wordButton',
		'expandButton',
		'closeButton',
		'prevButton',
		'nextButton',
		'replaceButton',
		'replaceAllButton',
		'service',
		'replaceRow',
		'isExpanded'
	],
	#category : 'Rubric-Editing-FindReplaceService',
	#package : 'Rubric',
	#tag : 'Editing-FindReplaceService'
}

{ #category : 'accessing' }
RubFindReplaceSearchBar >> service [
	^ service
]

{ #category : 'accessing' }
RubFindReplaceSearchBar >> service: aFindReplaceService [
	service := aFindReplaceService.
	replaceField setText: service replaceText.
	findField setText: service findText
]

{ #category : 'initialization' }
RubFindReplaceSearchBar >> initialize [
	super initialize.
	isExpanded := false.
	self
		changeTableLayout;
		listDirection: #topToBottom;
		cellInset: 0;
		hResizing: #rigid;
		vResizing: #shrinkWrap;
		borderWidth: 1;
		borderColor: (Color gray: 0.6);
		color: Color paleBuff;
		extent: 340 @ 26.

	self initializeFindRow.
	self initializeReplaceRow.
	self hideReplaceRow
]

{ #category : 'initialization' }
RubFindReplaceSearchBar >> initializeFindRow [
	| row |
	row := self newRow.
	row
		addMorphBack: self newFindField;
		addMorphBack: self newMatchCountLabel;
		addMorphBack: self newPrevButton;
		addMorphBack: self newNextButton;
		addMorphBack: self newRegexButton;
		addMorphBack: self newCaseButton;
		addMorphBack: self newWordButton;
		addMorphBack: self newExpandButton;
		addMorphBack: self newCloseButton.
	self addMorphBack: row
]

{ #category : 'initialization' }
RubFindReplaceSearchBar >> initializeReplaceRow [
	replaceRow := self newRow.
	replaceRow
		addMorphBack: self newReplaceField;
		addMorphBack: self newReplaceButton;
		addMorphBack: self newReplaceAllButton.
	self addMorphBack: replaceRow
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newFindField [
	findField := RubPluggableTextFieldMorph new.
	findField
		ghostText: 'Find';
		acceptOnCR: false;
		hResizing: #spaceFill;
		vResizing: #rigid;
		changedAction: [ :t | self onFindTextChanged ].
	findField textArea announcer
		when: RubKeystroke send: #onFindFieldKeystroke: to: self.
	^ findField
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newMatchCountLabel [
	^ matchCountLabel := StringMorph new
		contents: '';
		font: (StandardFonts defaultFont pointSize: 9);
		color: (Color gray: 0.3);
		vResizing: #rigid;
		hResizing: #shrinkWrap;
		yourself
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newPrevButton [
	^ prevButton := self
		createCompactButtonLabeled: '▲'
		getState: nil
		action: #findPrevious
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newNextButton [
	^ nextButton := self
		createCompactButtonLabeled: '▼'
		getState: nil
		action: #findNext
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newRegexButton [
	^ regexButton := self
		createCompactButtonLabeled: '.*'
		getState: #isRegex
		action: #toggleRegex
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newCaseButton [
	^ caseButton := self
		createCompactButtonLabeled: 'Aa'
		getState: #isCaseSensitive
		action: #toggleCaseSensitive
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newWordButton [
	^ wordButton := self
		createCompactButtonLabeled: 'ab'
		getState: #isEntireWords
		action: #toggleWholeWord
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newExpandButton [
	^ expandButton := self
		createCompactButtonLabeled: '▸'
		getState: nil
		action: #toggleReplaceMode
]

{ #category : 'submorphs - find row' }
RubFindReplaceSearchBar >> newCloseButton [
	^ closeButton := self
		createCompactButtonLabeled: '✕'
		getState: nil
		action: #close
]

{ #category : 'submorphs - replace row' }
RubFindReplaceSearchBar >> newReplaceField [
	replaceField := RubPluggableTextFieldMorph new.
	replaceField
		ghostText: 'Replace';
		acceptOnCR: false;
		hResizing: #spaceFill;
		vResizing: #rigid;
		changedAction: [ :t | service replaceText: t ].
	^ replaceField
]

{ #category : 'submorphs - replace row' }
RubFindReplaceSearchBar >> newReplaceButton [
	^ replaceButton := self
		createCompactButtonLabeled: 'Replace'
		getState: nil
		action: #replace
]

{ #category : 'submorphs - replace row' }
RubFindReplaceSearchBar >> newReplaceAllButton [
	^ replaceAllButton := self
		createCompactButtonLabeled: 'All'
		getState: nil
		action: #replaceAll
]

{ #category : 'helpers' }
RubFindReplaceSearchBar >> newRow [
	^ PanelMorph new
		changeTableLayout;
		listDirection: #leftToRight;
		cellInset: 2;
		hResizing: #spaceFill;
		vResizing: #shrinkWrap;
		borderWidth: 0;
		fillStyle: Color transparent;
		yourself
]

{ #category : 'helpers' }
RubFindReplaceSearchBar >> createCompactButtonLabeled: aString getState: getSel action: actSel [
	| btn |
	btn := PluggableButtonMorph on: self getState: getSel action: actSel.
	btn
		label: aString font: (StandardFonts defaultFont pointSize: 9);
		cornerStyle: #square;
		hResizing: #rigid;
		vResizing: #rigid;
		extent: 22 @ 20;
		color: Color transparent;
		borderWidth: 1;
		borderColor: Color transparent.
	^ btn
]

{ #category : 'events' }
RubFindReplaceSearchBar >> onFindFieldKeystroke: anAnnouncement [
	| event |
	event := anAnnouncement event.
	event keyCharacter = Character escape ifTrue: [ ^ self close ].
	event keyCharacter = Character cr ifTrue: [
		event shiftPressed
			ifTrue: [ self findPrevious ]
			ifFalse: [ self findNext ].
		^ self ].
	event key = KeyboardKey up ifTrue: [ ^ self findPrevious ].
	event key = KeyboardKey down ifTrue: [ ^ self findNext ]
]

{ #category : 'events' }
RubFindReplaceSearchBar >> onFindTextChanged [
	| text |
	text := findField text asString.
	text = service findText ifTrue: [ ^ self ].
	service findText: text.
	service setStartIndex.
	service findAndSelectRegex.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> findNext [
	service searchBackwards: false.
	service find.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> findPrevious [
	service searchBackwards: true.
	service find.
	service searchBackwards: false.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> toggleRegex [
	service isRegex: service isRegex not.
	service setStartIndex.
	service findAndSelectRegex.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> toggleCaseSensitive [
	service caseSensitive: service caseSensitive not.
	service setStartIndex.
	service findAndSelectRegex.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> toggleWholeWord [
	service entireWordsOnly: service entireWordsOnly not.
	service setStartIndex.
	service findAndSelectRegex.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> toggleReplaceMode [
	isExpanded := isExpanded not.
	isExpanded
		ifTrue: [ self showReplaceRow ]
		ifFalse: [ self hideReplaceRow ].
	expandButton label: (isExpanded ifTrue: [ '▾' ] ifFalse: [ '▸' ])
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> replace [
	service replace.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> replaceAll [
	service replaceAll.
	self updateMatchCount
]

{ #category : 'actions' }
RubFindReplaceSearchBar >> close [
	| ta |
	ta := service textArea.
	service findText: ''.
	self delete.
	service whenDialogDeleted.
	ta ifNotNil: [ :t | t takeKeyboardFocus ]
]

{ #category : 'updating' }
RubFindReplaceSearchBar >> updateMatchCount [
	| text regex ranges count currentIdx |
	text := service textArea text asString.
	regex := service findRegex.
	(regex isNil or: [ text isEmpty or: [ findField text asString isEmpty ] ])
		ifTrue: [ ^ matchCountLabel contents: '' ].
	ranges := regex matchingRangesIn: text.
	count := ranges size.
	count = 0 ifTrue: [ ^ matchCountLabel contents: 'No matches' ].
	currentIdx := self currentMatchIndexAmong: ranges.
	^ matchCountLabel contents:
		(currentIdx > 0
			ifTrue: [ currentIdx asString , '/' , count asString ]
			ifFalse: [ count asString , ' matches' ])
]

{ #category : 'updating' }
RubFindReplaceSearchBar >> currentMatchIndexAmong: ranges [
	| sel |
	sel := service textArea selectionInterval.
	ranges withIndexDo: [ :r :i |
		(r first = sel first and: [ r last = sel last ]) ifTrue: [ ^ i ] ].
	^ 0
]

{ #category : 'updating' }
RubFindReplaceSearchBar >> showReplaceRow [
	replaceRow show.
	self height: self height + replaceRow height
]

{ #category : 'updating' }
RubFindReplaceSearchBar >> hideReplaceRow [
	replaceRow hide
]

{ #category : 'testing' }
RubFindReplaceSearchBar >> isRegex [
	^ service notNil and: [ service isRegex ]
]

{ #category : 'testing' }
RubFindReplaceSearchBar >> isCaseSensitive [
	^ service notNil and: [ service caseSensitive ]
]

{ #category : 'testing' }
RubFindReplaceSearchBar >> isEntireWords [
	^ service notNil and: [ service entireWordsOnly ]
]

{ #category : 'focus' }
RubFindReplaceSearchBar >> findField [
	^ findField
]
