Class {
	#name : 'RubMoveDownAction',
	#superclass : 'RubCursorAction',
	#category : 'Rubric-Editing-Core',
	#package : 'Rubric',
	#tag : 'Editing-Core'
}

{ #category : 'as yet unclassified' }
RubMoveDownAction >> isForward [
	
	^ false.
]

{ #category : 'as yet unclassified' }
RubMoveDownAction >> moveFromPosition: position inEditor: editor [

	^ editor sameColumn: position newLine: [ :line | line + 1 ] forward: self isForward
]
