Class {
	#name : 'RubMoveLeftAction',
	#superclass : 'RubCursorAction',
	#category : 'Rubric-Editing-Core',
	#package : 'Rubric',
	#tag : 'Editing-Core'
}

{ #category : 'testing' }
RubMoveLeftAction >> isForward [
	
	^ true.
]

{ #category : 'as yet unclassified' }
RubMoveLeftAction >> moveFromPosition: position inEditor: editor [

	editor invalidateVisualColumn.
	^ position - 1
]
