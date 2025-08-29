Class {
	#name : 'RubMoveUpAction',
	#superclass : 'RubCursorAction',
	#category : 'Rubric-Editing-Core',
	#package : 'Rubric',
	#tag : 'Editing-Core'
}

{ #category : 'testing' }
RubMoveUpAction >> isForward [
	
	^ true.
]

{ #category : 'as yet unclassified' }
RubMoveUpAction >> moveFromPosition: position inEditor: editor [

	^ editor sameColumn: position newLine: [ :line | line - 1 ] forward: self isForward
]
