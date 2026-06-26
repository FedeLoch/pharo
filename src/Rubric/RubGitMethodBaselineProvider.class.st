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
	| repoClass repository packageName |
	repoClass := Smalltalk classNamed: 'IceRepository'.
	repoClass ifNil: [ ^ nil ].
	packageName := aCompiledMethod package name.
	repository := repoClass repositoryForPackageNamed: packageName.
	repository ifNil: [ ^ nil ].
	^ self committedSourceFor: aCompiledMethod in: repository
]

{ #category : 'private' }
RubGitMethodBaselineProvider >> committedSourceFor: aCompiledMethod in: aRepository [
	| history commit entry |
	history := aRepository history.
	history ifNil: [ ^ nil ].
	commit := history last.
	commit ifNil: [ ^ nil ].
	entry := commit entryFor: aCompiledMethod.
	entry ifNil: [ ^ nil ].
	^ entry sourceText
]
