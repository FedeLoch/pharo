"
I am a VS Code-style inline Find & Replace widget for Pharo's text editor.
I float at the top-right corner of the editor and provide live/incremental search,
match navigation, replace, and search option toggles.

Usage:
  aRubFindReplaceService widget show  -- or --
  RubFindReplaceWidget openOn: aRubAbstractTextArea

I replace the old dialog-based RubFindReplaceDialogWindow.
"
Class {
	#name : 'RubFindReplaceWidget',
	#superclass : 'Morph',
	#instVars : [
		'service',
		'findInput',
		'replaceInput',
		'matchCounter',
		'caseBtn',
		'wordBtn',
		'regexBtn',
		'chevronBtn',
		'closeBtn',
		'prevBtn',
		'nextBtn',
		'replaceBtn',
		'replaceAllBtn',
		'preserveBtn',
		'replaceRow',
		'textArea',
		'allMatches',
		'currentMatchIndex',
		'isReplaceVisible',
		'isSearching',
		'isPreserveCase'
	],
	#category : 'Rubric-Editing-FindReplaceService',
	#package : 'Rubric',
	#tag : 'Editing-FindReplaceService'
}

{ #category : 'instance creation' }
RubFindReplaceWidget class >> openOn: aTextArea [
	^ self new
		textArea: aTextArea;
		show;
		yourself
]

{ #category : 'button helpers' }
RubFindReplaceWidget >> buttonExtent [
	^ 28 @ 26
]

{ #category : 'building' }
RubFindReplaceWidget >> buildFindRow [
	| row |
	row := self newRow.
	chevronBtn := self createButton: '›' action: #toggleReplaceVisible.
	chevronBtn helpText: 'Toggle Replace (Cmd+H)'.
	findInput := self newInputField.
	findInput announcer when: RubTextChanged send: #whenFindTextChanged to: self.
	findInput announcer when: RubReturnEntered send: #whenFindReturnEntered to: self.
	caseBtn := self createToggle: 'Aa' getState: #isCaseSensitive action: #toggleCaseSensitive.
	caseBtn helpText: 'Match Case (Alt+C)'.
	wordBtn := self createToggle: 'ab' getState: #isWholeWord action: #toggleWholeWord.
	wordBtn helpText: 'Match Whole Word (Alt+W)'.
	regexBtn := self createToggle: '.*' getState: #isRegex action: #toggleRegex.
	regexBtn helpText: 'Use Regex (Alt+R)'.
	matchCounter := StringMorph new
		contents: '';
		font: (StandardFonts defaultFont pointSize: 11);
		color: self textColor;
		hResizing: #shrinkWrap;
		vResizing: #center;
		yourself.
	prevBtn := self createButton: '↑' action: #previousMatch.
	prevBtn helpText: 'Previous Match (Shift+Enter)'.
	nextBtn := self createButton: '↓' action: #nextMatch.
	nextBtn helpText: 'Next Match (Enter)'.
	closeBtn := self createButton: '×' action: #closeWidget.
	closeBtn helpText: 'Close (Esc)'.
	row addMorphBack: chevronBtn.
	row addMorphBack: findInput.
	row addMorphBack: caseBtn.
	row addMorphBack: wordBtn.
	row addMorphBack: regexBtn.
	row addMorphBack: matchCounter.
	row addMorphBack: prevBtn.
	row addMorphBack: nextBtn.
	row addMorphBack: closeBtn.
	^ row
]

{ #category : 'building' }
RubFindReplaceWidget >> buildReplaceRow [
	| row spacer |
	row := self newRow.
	spacer := Morph new
		extent: 20 @ 26;
		color: Color transparent;
		hResizing: #rigid;
		vResizing: #rigid;
		yourself.
	row addMorphBack: spacer.
	replaceInput := self newInputField.
	replaceInput announcer when: RubTextChanged send: #whenReplaceTextChanged to: self.
	replaceInput announcer when: RubReturnEntered send: #whenReplaceReturnEntered to: self.
	preserveBtn := self createToggle: 'AB' getState: #isPreserveCase action: #togglePreserveCase.
	preserveBtn helpText: 'Preserve Case'.
	replaceBtn := self createButton: '⎘' action: #replaceCurrent.
	replaceBtn helpText: 'Replace'.
	replaceAllBtn := self createButton: '⎘⎘' action: #replaceAll.
	replaceAllBtn helpText: 'Replace All'.
	row addMorphBack: replaceInput.
	row addMorphBack: preserveBtn.
	row addMorphBack: replaceBtn.
	row addMorphBack: replaceAllBtn.
	^ row
]

{ #category : 'building' }
RubFindReplaceWidget >> buildWidget [
	| mainCol |
	self removeAllMorphs.
	mainCol := self newColumn.
	mainCol addMorphBack: self buildFindRow.
	replaceRow := self buildReplaceRow.
	replaceRow visible: isReplaceVisible.
	mainCol addMorphBack: replaceRow.
	self addMorphBack: mainCol
]

{ #category : 'highlights' }
RubFindReplaceWidget >> clearHighlights [
	textArea ifNotNil: [ :ta |
		ta withoutFindReplaceSelection.
		ta changed ]
]

{ #category : 'highlights' }
RubFindReplaceWidget >> clearRegexError [
	findInput borderColor: self inputBorderColor
]

{ #category : 'highlights' }
RubFindReplaceWidget >> showRegexError: anError [
	findInput borderColor: self inputNoResultBorderColor
]

{ #category : 'actions' }
RubFindReplaceWidget >> closeWidget [
	self hide.
	textArea ifNotNil: [ :ta | ta takeKeyboardFocus ]
]

{ #category : 'button helpers' }
RubFindReplaceWidget >> createButton: label action: selector [
	| btn |
	btn := PluggableButtonMorph new
		model: self;
		action: selector;
		label: label;
		color: Color transparent;
		hResizing: #rigid;
		vResizing: #rigid;
		extent: self buttonExtent;
		cornerStyle: #rounded;
		borderWidth: 0;
		yourself.
	btn labelMorph color: self textColor.
	^ btn
]

{ #category : 'button helpers' }
RubFindReplaceWidget >> createToggle: label getState: getSel action: actSel [
	| btn |
	btn := PluggableButtonMorph new
		model: self;
		getStateSelector: getSel;
		action: actSel;
		label: label;
		color: Color transparent;
		hResizing: #rigid;
		vResizing: #rigid;
		extent: self buttonExtent;
		cornerStyle: #rounded;
		borderWidth: 0;
		yourself.
	btn labelMorph color: self textColor.
	^ btn
]

{ #category : 'searching' }
RubFindReplaceWidget >> findAllMatches [
	| regex |
	service findText isEmptyOrNil ifTrue: [ ^ #() ].
	regex := [ service findRegex ]
		on: Error
		do: [ :err | self showRegexError: err. ^ #() ].
	self clearRegexError.
	regex ifNil: [ ^ #() ].
	^ textArea editor findAll: regex startingAt: 1
]

{ #category : 'navigation' }
RubFindReplaceWidget >> findEditorContainer [
	| morph |
	morph := textArea.
	[ morph isNil ] whileFalse: [
		(morph isKindOf: RubScrolledTextMorph) ifTrue: [ ^ morph ].
		morph := morph owner ].
	^ textArea owner
]

{ #category : 'navigation' }
RubFindReplaceWidget >> focusMatchAtIndex: index [
	| match textEditor |
	index < 0 ifTrue: [ ^ self ].
	index >= allMatches size ifTrue: [ ^ self ].
	match := allMatches at: index + 1.
	textEditor := textArea editor.
	textEditor selectFrom: match first to: match last.
	textEditor scrollSelectionIntoView
]

{ #category : 'navigation' }
RubFindReplaceWidget >> focusNearestMatch [
	| cursorPos nearestDist nearestIdx dist |
	allMatches ifEmpty: [ ^ self ].
	cursorPos := textArea editor startIndex.
	nearestDist := SmallInteger maxVal.
	nearestIdx := 0.
	allMatches withIndexDo: [ :match :idx |
		(match first >= cursorPos and: [ match first - cursorPos < nearestDist ])
			ifTrue: [
				nearestDist := match first - cursorPos.
				nearestIdx := idx - 1 ] ].
	nearestIdx < 0 ifTrue: [ nearestIdx := 0 ].
	currentMatchIndex := nearestIdx.
	self focusMatchAtIndex: currentMatchIndex.
	self updateCounter
]

{ #category : 'testing' }
RubFindReplaceWidget >> hasValidSearch [
	^ service findText isEmptyOrNil not
]

{ #category : 'actions' }
RubFindReplaceWidget >> hide [
	self visible ifFalse: [ ^ self ].
	self delete.
	allMatches := #().
	currentMatchIndex := -1.
	self clearHighlights
]

{ #category : 'initialization' }
RubFindReplaceWidget >> initialize [
	super initialize.
	isReplaceVisible := false.
	isSearching := false.
	isPreserveCase := false.
	allMatches := #().
	currentMatchIndex := -1.
	self
		changeTableLayout;
		listDirection: #topToBottom;
		cellInset: 0;
		layoutInset: 4;
		hResizing: #shrinkWrap;
		vResizing: #shrinkWrap;
		color: self widgetBackgroundColor;
		borderStyle: (BorderStyle inset width: 1);
		borderColor: self widgetBorderColor.
	self buildWidget
]

{ #category : 'colors' }
RubFindReplaceWidget >> inputBackgroundColor [
	^ Color r: 60 g: 60 b: 60 range: 255
]

{ #category : 'colors' }
RubFindReplaceWidget >> inputBorderColor [
	^ Color r: 60 g: 60 b: 60 range: 255
]

{ #category : 'colors' }
RubFindReplaceWidget >> inputFocusBorderColor [
	^ Color r: 0 g: 122 b: 204 range: 255
]

{ #category : 'colors' }
RubFindReplaceWidget >> inputNoResultBorderColor [
	^ Color r: 244 g: 71 b: 71 range: 255
]

{ #category : 'testing' }
RubFindReplaceWidget >> isCaseSensitive [
	^ service ifNotNil: [ service caseSensitive ] ifNil: [ false ]
]

{ #category : 'testing' }
RubFindReplaceWidget >> isPreserveCase [
	^ isPreserveCase
]

{ #category : 'testing' }
RubFindReplaceWidget >> isRegex [
	^ service ifNotNil: [ service isRegex ] ifNil: [ false ]
]

{ #category : 'testing' }
RubFindReplaceWidget >> isWholeWord [
	^ service ifNotNil: [ service entireWordsOnly ] ifNil: [ false ]
]

{ #category : 'layout' }
RubFindReplaceWidget >> newColumn [
	^ Morph new
		changeTableLayout;
		listDirection: #topToBottom;
		cellInset: 2;
		hResizing: #spaceFill;
		vResizing: #shrinkWrap;
		yourself
]

{ #category : 'building' }
RubFindReplaceWidget >> newInputField [
	| input |
	input := RubTextFieldArea new.
	input
		withoutDecoratorNamed: #findReplaceSelection;
		backgroundColor: self inputBackgroundColor;
		color: self textColor;
		borderStyle: (BorderStyle inset width: 1);
		borderColor: self inputBorderColor;
		cornerStyle: #rounded;
		hResizing: #spaceFill;
		vResizing: #rigid;
		height: 26;
		font: (StandardFonts defaultFont pointSize: 13);
		yourself.
	^ input
]

{ #category : 'layout' }
RubFindReplaceWidget >> newRow [
	^ Morph new
		changeTableLayout;
		listDirection: #leftToRight;
		cellInset: 2;
		hResizing: #spaceFill;
		vResizing: #shrinkWrap;
		yourself
]

{ #category : 'actions' }
RubFindReplaceWidget >> nextMatch [
	self hasValidSearch ifFalse: [ ^ self ].
	allMatches ifEmpty: [ allMatches := self findAllMatches ].
	allMatches ifEmpty: [ ^ self ].
	currentMatchIndex := currentMatchIndex + 1.
	currentMatchIndex >= allMatches size ifTrue: [ currentMatchIndex := 0 ].
	self focusMatchAtIndex: currentMatchIndex.
	self updateCounter
]

{ #category : 'navigation' }
RubFindReplaceWidget >> performSearch [
	service findText isEmptyOrNil ifTrue: [ ^ self clearHighlights ].
	allMatches := self findAllMatches.
	allMatches ifEmpty: [
		currentMatchIndex := -1.
		textArea withoutFindReplaceSelection.
		findInput borderColor: self inputNoResultBorderColor.
		self updateCounter.
		^ self ].
	findInput borderColor: self inputBorderColor.
	currentMatchIndex := -1.
	textArea withFindReplaceSelection.
	textArea changed.
	self focusNearestMatch
]

{ #category : 'positioning' }
RubFindReplaceWidget >> positionRelativeTo: aMorph [
	| bounds |
	aMorph ifNil: [ ^ self ].
	bounds := aMorph innerBounds.
	self position: (bounds right - self width - 4) @ (bounds top + 2)
]

{ #category : 'actions' }
RubFindReplaceWidget >> previousMatch [
	self hasValidSearch ifFalse: [ ^ self ].
	allMatches ifEmpty: [ allMatches := self findAllMatches ].
	allMatches ifEmpty: [ ^ self ].
	currentMatchIndex := currentMatchIndex - 1.
	currentMatchIndex < 0 ifTrue: [ currentMatchIndex := allMatches size - 1 ].
	self focusMatchAtIndex: currentMatchIndex.
	self updateCounter
]

{ #category : 'actions' }
RubFindReplaceWidget >> replaceAll [
	| regex |
	self hasValidSearch ifFalse: [ ^ self ].
	regex := [ service findRegex ]
		on: Error
		do: [ :err | ^ self ].
	regex ifNil: [ ^ self ].
	textArea editor replaceAll: regex with: service replaceText.
	allMatches := self findAllMatches.
	currentMatchIndex := -1.
	allMatches ifNotEmpty: [ textArea withFindReplaceSelection. self focusNearestMatch ]
		ifEmpty: [ textArea withoutFindReplaceSelection ].
	textArea changed.
	self updateCounter
]

{ #category : 'actions' }
RubFindReplaceWidget >> replaceCurrent [
	| regex match |
	self hasValidSearch ifFalse: [ ^ self ].
	currentMatchIndex < 0 ifTrue: [ ^ self ].
	currentMatchIndex >= allMatches size ifTrue: [ ^ self ].
	match := allMatches at: currentMatchIndex + 1.
	textArea editor selectFrom: match first to: match last.
	textArea editor replaceSelectionWith: service replaceText.
	allMatches := self findAllMatches.
	currentMatchIndex := currentMatchIndex min: (allMatches size - 1).
	currentMatchIndex < 0 ifTrue: [ currentMatchIndex := 0 ].
	allMatches ifNotEmpty: [ textArea withFindReplaceSelection. self focusMatchAtIndex: currentMatchIndex ]
		ifEmpty: [ textArea withoutFindReplaceSelection ].
	textArea changed.
	self updateCounter
]

{ #category : 'accessing' }
RubFindReplaceWidget >> service: aService [
	service := aService
]

{ #category : 'actions' }
RubFindReplaceWidget >> show [
	| container |
	self visible ifTrue: [
		textArea hasSelection ifTrue: [
			service findText: textArea selection asString.
			findInput updateTextWith: textArea selection asString.
			self performSearch ].
		^ self ].
	textArea ifNil: [ ^ self ].
	container := self findEditorContainer.
	container ifNil: [ ^ self ].
	container addMorphFront: self.
	self positionRelativeTo: container.
	self visible: true.
	allMatches := #().
	currentMatchIndex := -1.
	service findText ifNotEmpty: [ self performSearch ].
	findInput takeKeyboardFocus
]

{ #category : 'accessing' }
RubFindReplaceWidget >> textArea [
	^ textArea
]

{ #category : 'accessing' }
RubFindReplaceWidget >> textArea: aTextArea [
	textArea := aTextArea.
	service := aTextArea findReplaceService
]

{ #category : 'colors' }
RubFindReplaceWidget >> textColor [
	^ Color r: 204 g: 204 b: 204 range: 255
]

{ #category : 'actions' }
RubFindReplaceWidget >> toggleCaseSensitive [
	service caseSensitive: service caseSensitive not.
	service caseSensitive
		ifTrue: [ self toggleOn: caseBtn ]
		ifFalse: [ self toggleOff: caseBtn ].
	self performSearch
]

{ #category : 'button helpers' }
RubFindReplaceWidget >> toggleOff: btn [
	btn color: Color transparent.
	btn labelMorph color: self textColor
]

{ #category : 'button helpers' }
RubFindReplaceWidget >> toggleOn: btn [
	btn color: (Color r: 0 g: 122 b: 204 range: 255).
	btn labelMorph color: Color white
]

{ #category : 'actions' }
RubFindReplaceWidget >> togglePreserveCase [
	isPreserveCase := isPreserveCase not.
	isPreserveCase
		ifTrue: [ self toggleOn: preserveBtn ]
		ifFalse: [ self toggleOff: preserveBtn ]
]

{ #category : 'actions' }
RubFindReplaceWidget >> toggleRegex [
	service isRegex: service isRegex not.
	service isRegex
		ifTrue: [ self toggleOn: regexBtn ]
		ifFalse: [ self toggleOff: regexBtn ].
	self performSearch
]

{ #category : 'actions' }
RubFindReplaceWidget >> toggleReplaceVisible [
	isReplaceVisible := isReplaceVisible not.
	replaceRow visible: isReplaceVisible.
	chevronBtn label: (isReplaceVisible ifTrue: ['⌄'] ifFalse: ['›']).
	isReplaceVisible
		ifTrue: [ replaceInput takeKeyboardFocus ]
		ifFalse: [ findInput takeKeyboardFocus ]
]

{ #category : 'actions' }
RubFindReplaceWidget >> toggleWholeWord [
	service entireWordsOnly: service entireWordsOnly not.
	service entireWordsOnly
		ifTrue: [ self toggleOn: wordBtn ]
		ifFalse: [ self toggleOff: wordBtn ].
	self performSearch
]

{ #category : 'updating' }
RubFindReplaceWidget >> updateCounter [
	| total |
	allMatches ifEmpty: [
		matchCounter contents: (service findText isEmptyOrNil ifTrue: [''] ifFalse: ['No results']).
		service findText isEmptyOrNil ifFalse: [ matchCounter color: Color red ].
		^ self ].
	total := allMatches size.
	matchCounter contents: (currentMatchIndex + 1) printString, ' of ', total printString.
	matchCounter color: self textColor
]

{ #category : 'events' }
RubFindReplaceWidget >> whenFindReturnEntered [
	self nextMatch
]

{ #category : 'events' }
RubFindReplaceWidget >> whenFindTextChanged [
	isSearching ifTrue: [ ^ self ].
	isSearching := true.
	service findText: findInput text asString.
	service findText isEmptyOrNil
		ifTrue: [ self clearHighlights. matchCounter contents: ''. isSearching := false. ^ self ].
	self performSearch.
	isSearching := false
]

{ #category : 'events' }
RubFindReplaceWidget >> whenReplaceReturnEntered [
	self replaceCurrent
]

{ #category : 'events' }
RubFindReplaceWidget >> whenReplaceTextChanged [
	service replaceText: replaceInput text asString
]

{ #category : 'colors' }
RubFindReplaceWidget >> widgetBackgroundColor [
	^ Color r: 37 g: 37 b: 38 range: 255
]

{ #category : 'colors' }
RubFindReplaceWidget >> widgetBorderColor [
	^ Color r: 60 g: 60 b: 60 range: 255
]
