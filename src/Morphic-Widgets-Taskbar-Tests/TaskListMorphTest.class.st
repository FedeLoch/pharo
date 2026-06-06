Class {
	#name : 'TaskListMorphTest',
	#superclass : 'TaskMorphTest',
	#instVars : [
		'taskList'
	],
	#category : 'Morphic-Widgets-Taskbar-Tests',
	#package : 'Morphic-Widgets-Taskbar-Tests'
}

{ #category : 'running' }
TaskListMorphTest >> setUp [

	super setUp.
	self registerTaskFor: SystemWindow new.
	self registerTaskFor: SystemWindow new.
	self registerTaskFor: SystemWindow new.

	taskList := TaskListMorph new tasks: tasks
]

{ #category : 'tests' }
TaskListMorphTest >> testHasAllWindows [

	| newTask |
	self assert: (taskList hasCurrentWindows: tasks).

	newTask := self newTaskFor: SystemWindow new.
	self deny: (taskList hasCurrentWindows: tasks , { newTask }).

	self deny: (taskList hasCurrentWindows: tasks allButLast)
]

{ #category : 'tests' }
TaskListMorphTest >> testSelectNextTask [

	self assert: taskList activeTask equals: nil.

	self task1 state: #active.
	self assert: taskList activeTask equals: self task1.

	taskList selectNextTask.
	self assert: taskList activeTask equals: self task2.
	
	taskList selectNextTask.
	self assert: taskList activeTask equals: self task3.
	
	taskList selectNextTask. "cycle"
	self assert: taskList activeTask equals: self task1.
]

{ #category : 'tests' }
TaskListMorphTest >> testSelectPreviousTask [

	self assert: taskList activeTask equals: nil.

	self task3 state: #active.
	self assert: taskList activeTask equals: self task3.

	taskList selectPreviousTask.
	self assert: taskList activeTask equals: self task2.
	
	taskList selectPreviousTask.
	self assert: taskList activeTask equals: self task1.
	
	taskList selectPreviousTask. "cycle"
	self assert: taskList activeTask equals: self task3.
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testContainerOverhead [

	self assert: taskList containerOverhead equals: 16
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testContainerPadding [

	self assert: taskList containerPadding equals: 100
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testEffectivePreviewExtentReturnsDefaultForFewTasks [

	| tl |
	tl := self taskListWithTasks: (self newTasks: 3).
	self assert: tl effectivePreviewExtent equals: tl defaultPreviewExtent
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testEffectivePreviewExtentScalesForManyTasks [

	| tl extent |
	tl := self taskListWithTasks: (self newTasks: 30).
	extent := tl effectivePreviewExtent.
	self assert: extent x < tl defaultPreviewExtent x
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testEffectivePreviewExtentRespectsFloor [

	| tl extent minX |
	tl := self taskListWithTasks: (self newTasks: 200).
	extent := tl effectivePreviewExtent.
	minX := (tl defaultPreviewExtent x * 0.2) asInteger.
	self assert: extent x >= minX
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testMaxWidthReturnsPositiveValue [

	| tl |
	tl := self taskListWithTasks: (self newTasks: 5).
	self assert: tl maxWidth > 0
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testLabelTruncatesWhenLongerThanLimit [

	| tl task label |
	tl := self taskListWithTasks: (self newTasks: 1).
	task := self newTaskWithLabel: 'A very long task name to truncate'.
	label := tl label: task truncation: 8 size: 9.
	self assert: label contents size <= 8
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testLabelShowsFullTextWhenShorterThanLimit [

	| tl task label |
	tl := self taskListWithTasks: (self newTasks: 1).
	task := self newTaskWithLabel: 'Short'.
	label := tl label: task truncation: 10 size: 9.
	self assert: label contents equals: 'Short'
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testLabelFontSizeIsScaled [

	| tl container label |
	tl := self taskListWithTasks: (self newTasks: 30).
	tl updateButtonsAndPreview.
	container := tl submorphs first.
	label := container submorphs second.
	self assert: label fontSize < 11.
	self assert: label fontSize >= 8
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testUpdateTaskButtonsCreatesCorrectNumberOfSubmorphs [

	| tl |
	tl := self taskListWithTasks: (self newTasks: 7).
	tl updateButtonsAndPreview.
	self assert: tl submorphs size equals: 7
]

{ #category : 'tests - max width' }
TaskListMorphTest >> testUpdateButtonsAndPreviewSetsRigidResizing [

	| tl |
	tl := self taskListWithTasks: (self newTasks: 5).
	self assert: tl hResizing equals: #shrinkWrap.
	tl updateButtonsAndPreview.
	self assert: tl hResizing equals: #rigid.
	self assert: tl vResizing equals: #rigid
]
