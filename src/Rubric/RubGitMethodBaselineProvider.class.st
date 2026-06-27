"
I provide the baseline source code for a method by querying the last
committed version via Iceberg. I check if IceRepository is available
and try to find the committed source.

If Iceberg is not loaded, or the method has no Git history, I answer nil
(letting the fallback chain handle it).
"
Class {
	#name : 'RubGitMethodBaselineProvider',
	#superclass : 'RubMethodBaselineProvider',
	#category : 'Rubric-Editing-Widgets',
	#package : 'Rubric',
	#tag : 'Editing-Widgets'
}

{ #category : 'accessing' }
RubGitMethodBaselineProvider >> baselineForMethod: aCompiledMethod [
	| repoClass repositories |
	repoClass := Smalltalk classNamed: 'IceRepository'.
	repoClass ifNil: [ ^ nil ].
	repositories := aCompiledMethod package repositories.
	(repositories size ~= 1) ifTrue: [ ^ nil ].
	^ self committedSourceFor: aCompiledMethod in: repositories first
]

{ #category : 'private' }
RubGitMethodBaselineProvider >> committedSourceFor: aCompiledMethod in: aRepository [
	| commit snapshot methodDefinition |
	aRepository head ifNil: [ ^ nil ].
	commit := aRepository head commit ifNil: [ ^ nil ].
	snapshot := commit snapshotFor: aCompiledMethod package.
	snapshot ifNil: [ ^ nil ].
	methodDefinition := snapshot definitions
		detect: [ :e |
			e isMethodDefinition
				and: [ e selector = aCompiledMethod selector ]
				and: [ e className = aCompiledMethod methodClass name ] ]
		ifNone: [ ^ nil ].
	^ methodDefinition source
]
