Class {
	#name : 'RubCursorAction',
	#superclass : 'Object',
	#instVars : [
		'ctrlPressed'
	],
	#category : 'Rubric-Editing-Core',
	#package : 'Rubric',
	#tag : 'Editing-Core'
}

{ #category : 'as yet unclassified' }
RubCursorAction class >> ctrlPressed: pressed [

	^ self new ctrl: pressed 
]

{ #category : 'as yet unclassified' }
RubCursorAction >> ctrl: pressed [

	ctrlPressed := pressed 
]

{ #category : 'as yet unclassified' }
RubCursorAction >> isForward [
	
	^ self subclassResponsibility 
]

{ #category : 'as yet unclassified' }
RubCursorAction >> moveFromPosition: position inEditor: editor [
	self subclassResponsibility.
]
