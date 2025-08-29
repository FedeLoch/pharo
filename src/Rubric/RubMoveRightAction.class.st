Class {
	#name : 'RubMoveRightAction',
	#superclass : 'RubCursorAction',
	#category : 'Rubric-Editing-Core',
	#package : 'Rubric',
	#tag : 'Editing-Core'
}

{ #category : 'testing' }
RubMoveRightAction >> isForward [
	
	^ true.
]

{ #category : 'as yet unclassified' }
RubMoveRightAction >> moveFromPosition: position inEditor: editor [

	editor invalidateVisualColumn. "Take into account the ctrl"
	^ position + 1
]
