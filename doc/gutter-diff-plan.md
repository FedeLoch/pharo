# Gutter Diff for Pharo Editor — Implementation Plan

## Overview

Add VS Code-style change indicators in the editor's left gutter, showing which lines have been **added**, **modified**, or **removed** relative to the last Git commit (or last save as fallback). Clicking an indicator opens a tooltip containing a `DiffMorph` preview showing the original vs current version.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   3 layers                              │
│                                                         │
│  Baseline Provider  ──►  Gutter Ruler  ──►  Diff Popup │
│  (abstract)              (Rubric ruler)      (DiffMorph)│
│     ↕                                                  │
│  GitMethodBaselineProvider                              │
│  EpiceaMethodBaselineProvider                           │
│                                                         │
│  All backed by: TextDiffBuilder (Myers LCS algorithm)   │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 1: Baseline Provider

**Goal:** Pluggable mechanism to fetch the "original" source code for a method.

### 1.1 — `RubMethodBaselineProvider` (abstract)

| Property | Value |
|----------|-------|
| Package | `Rubric` |
| File | `src/Rubric/RubMethodBaselineProvider.class.st` (NEW) |
| Superclass | `Object` |
| API | `baselineForMethod: aCompiledMethod → String` |

Returns `self subclassResponsibility`.

### 1.2 — `RubGitMethodBaselineProvider`

| Property | Value |
|----------|-------|
| File | `src/Rubric/RubGitMethodBaselineProvider.class.st` (NEW) |

- Uses `IceRepository` to locate the repository for the method's package
- Retrieves the committed version of the method from the last commit
- Falls back to `aCompiledMethod sourceCode` if no Git history exists
- Handles `IceRepository` not being loaded (graceful degradation)

### 1.3 — `RubEpiceaMethodBaselineProvider`

| Property | Value |
|----------|-------|
| File | `src/Rubric/RubEpiceaMethodBaselineProvider.class.st` (NEW) |

- Walks `EpMonitor current log priorEntriesFromHeadDo:` to find the last `EpMethodModification` for the given class + selector
- Returns `oldSourceCode` as the baseline
- Falls back to `aCompiledMethod sourceCode` if no events found

### 1.4 — Provider Chain (in Calypso)

- When the editor opens a method, instantiate the provider chain:
  1. Try `RubGitMethodBaselineProvider` first
  2. If it returns no useful baseline, fall back to `RubEpiceaMethodBaselineProvider`
  3. If neither works, use `aCompiledMethod sourceCode` (no diff, everything is "unchanged")

---

## Phase 2: Gutter Diff Ruler

**Goal:** A new Rubric side ruler that draws colored indicators and handles clicks.

### 2.1 — `RubGutterDiffDisplayer`

| Property | Value |
|----------|-------|
| Superclass | `RubScrolledTextSideRuler` |
| Key (class) | `#gutterDiff` |
| Side | `#left` |
| Level | **3** (leftmost — higher than `RubLineNumberDisplayer` at 2) |
| Width | Fixed ~16px (indicator width + gaps + separator) |

**Instance variables:**
| Variable | Type | Purpose |
|----------|------|---------|
| `baseline` | `String` | Cached original text (fetched once when editor opens) |
| `baselineProvider` | `RubMethodBaselineProvider` | Pluggable provider |
| `lineStates` | `Array of Symbol` | Per-line state: `#unchanged`, `#added`, `#modified` |
| `previewMorph` | `RubGutterDiffPreviewMorph` or `nil` | Currently open tooltip |

### 2.2 — Drawing (`drawOn: aCanvas`)

```
┌──────────────────┬──────────────┬──────────
│  indicator area  │  separator   │  line numbers / text
│  (≈16px)         │  (1px)       │
│                  │              │
│  ■ green bar     │  │           │   1  foo
│  ■ orange bar    │  │           │   2  bar
│  (no bar)        │  │           │   3  baz
│  ■ red bar       │  │           │   4  qux
└──────────────────┴──────────────┴──────────
```

For each visible line (from clip rect intersection):
- `#added` → fill a 10×lineHeight rectangle at `Color green muchDarker alpha: 0.3`
- `#modified` → `Color orange muchDarker alpha: 0.3`
- `#removed` → `Color red muchDarker alpha: 0.3` (drawn at the line's calculated position; for removed lines between existing lines, a small red triangle marker)
- Draw a 1px vertical separator on the right edge of the ruler

### 2.3 — Change Detection (`textChanged`)

1. Get `currentText` from `self textArea text asString`
2. Run `TextDiffBuilder from: baseline to: currentText`
3. Walk `patchSequenceDoIfMatch:ifInsert:ifRemove:` to build `lineStates`:
   - Track destination line index (`dstIdx` starting at 1)
   - `#match` block → `lineStates at: dstIdx put: #unchanged`; increment `dstIdx`
   - `#insert` block → `lineStates at: dstIdx put: #added`; increment `dstIdx`
   - `#remove` block → do NOT increment `dstIdx`; log a removed line marker at the gap

   For modification detection within matches: compare `DiffElement` strings — if they differ (same position, different text), mark as `#modified` instead of `#unchanged`.

4. Call `self changed` to trigger redraw

### 2.4 — Click Handling (`mouseDown: anEvent`)

1. Compute line index via `self lineIndexForPoint: anEvent position`
2. Check `lineStates at: lineIndex`
3. If `#added` or `#modified`:
   - Create `RubGutterDiffPreviewMorph` with the line index + context range
   - Position it to the right of the ruler, aligned with the clicked line
   - Attach as a child morph
4. If `#unchanged` → do nothing (pass event to `textArea` for cursor positioning)

### 2.5 — Convenience Methods on `RubScrolledTextMorph`

```smalltalk
withGutterDiff
    self withRulerNamed: #gutterDiff

withoutGutterDiff
    self rulerNamed: #gutterDiff ifNotNil: [ :r | self withoutRuler: r ]

gutterDiffRuler
    ^ self rulerNamed: #gutterDiff
```

---

## Phase 3: Diff Preview Tooltip

**Goal:** A lightweight popup showing a `DiffMorph` of the lines around the clicked change.

### 3.1 — `RubGutterDiffPreviewMorph`

| Property | Value |
|----------|-------|
| Superclass | `Morph` |
| File | `src/Rubric/RubGutterDiffPreviewMorph.class.st` (NEW) |

**Instance variables:**
| Variable | Type | Purpose |
|----------|------|---------|
| `diffMorph` | `DiffMorph` | The embedded diff viewer |
| `lineIndex` | `Integer` | The clicked line in the destination text |
| `contextLines` | `SmallInteger` | Lines of context (default: 3) |
| `baselineText` | `String` | Original text from baseline |
| `currentText` | `String` | Current editor text |

**Construction:**
1. Extract a window of text around `lineIndex` from both `baselineText` and `currentText`:
   - Start: `max(1, lineIndex - contextLines)`
   - End: `min(totalLines, lineIndex + contextLines)`
   - Extract the corresponding line ranges from both texts
2. Create `DiffMorph from: contextBaseline to: contextCurrent`
3. Set the popup size to fit the diff content (e.g., `400 × 200`)

**Appearance:**
- Light gray background with a subtle border/shadow
- Optional close button in top-right corner
- Semi-transparent overlay? Or just float above the text

**Dismissal:**
- On `Escape` key → delete from parent
- On click outside the popup → delete from parent
- On `scrollerOffsetChanged` → reposition or dismiss

---

## Phase 4: Calypso Integration

### 4.1 — `ClyMethodCodeEditorToolMorph` (EDIT)

**Override `buildLeftSideBar` or add to the existing chain:**

```smalltalk
buildLeftSideBar
    super buildLeftSideBar.  "adds textSegmentIcons"
    self textMorph withGutterDiff.
    "Set up baseline provider chain"
    self textMorph gutterDiffRuler 
        baselineProvider: (RubGitMethodBaselineProvider new 
            fallback: RubEpiceaMethodBaselineProvider new).
    "Refresh baseline when method changes are accepted"
    self textMorph when: RubTextAcceptedInModel send: #refreshBaseline to: self
```

**Add `refreshBaseline`:**
```smalltalk
refreshBaseline
    self textMorph gutterDiffRuler ifNotNil: [ :r |
        r refreshBaseline ]
```

### 4.2 — Baseline Refresh on Save

When the user saves/accepts the method, the compiled method changes. After save:
1. Fire `refreshBaseline`
2. The ruler fetches a new baseline from the provider
3. Recomputes the diff → all lines become `#unchanged`
4. Redraws the gutter (all indicators disappear)

---

## File Manifest

### New Files (5)

| # | File | Class | Lines (est.) |
|---|------|-------|-------------|
| 1 | `src/Rubric/RubGutterDiffDisplayer.class.st` | `RubGutterDiffDisplayer` | ~200 |
| 2 | `src/Rubric/RubGutterDiffPreviewMorph.class.st` | `RubGutterDiffPreviewMorph` | ~120 |
| 3 | `src/Rubric/RubMethodBaselineProvider.class.st` | `RubMethodBaselineProvider` | ~20 |
| 4 | `src/Rubric/RubGitMethodBaselineProvider.class.st` | `RubGitMethodBaselineProvider` | ~60 |
| 5 | `src/Rubric/RubEpiceaMethodBaselineProvider.class.st` | `RubEpiceaMethodBaselineProvider` | ~60 |

### Edited Files (2)

| # | File | Changes |
|---|------|---------|
| 1 | `src/Rubric/RubScrolledTextMorph.class.st` | Add 3 methods: `withGutterDiff`, `withoutGutterDiff`, `gutterDiffRuler` |
| 2 | `src/Calypso-SystemTools-Core/ClyMethodCodeEditorToolMorph.class.st` | Override `buildLeftSideBar`, add `refreshBaseline` |

---

## Dependencies

| Dependency | Usage | Handling if absent |
|------------|-------|-------------------|
| `Iceberg` (Git) | Get last committed method version | Fall back to Epicea provider |
| `Epicea` / `Ombu` | Get last saved method version | Fall back to current source (no diff) |
| `Tool-Diff` / `DiffMorph` | Preview popup | Required always |
| `Text-Diff` / `TextDiffBuilder` | Line diff algorithm | Required always |

---

## Edge Cases & Trade-offs

| Case | Handling |
|------|----------|
| **Empty file** | Baseline is empty string; all lines are `#added` |
| **File unchanged** | All lines `#unchanged`; no indicators drawn |
| **Lines added at end** | Detected as `#insert` in patch sequence; `lineStates` grows |
| **Lines removed** | A red triangle indicator shown at the line above the removal |
| **New method (no Git history)** | Baseline falls back to current source; no diff shown |
| **Method renamed** | Epicea/Git tracks by class+selector; if the old name is gone, no baseline |
| **Very long methods (>1000 lines)** | Drawing only processes visible lines (via clip rect); performance is O(visible lines) |
| **Rapid typing / every-keystroke diff** | `TextDiffBuilder` is fast for small edits; we recompute on `textChanged` which fires once per edit operation; profiling may be needed |
| **Multiple rulers on same side** | Our ruler has level 3 (leftmost), outside line numbers (level 2) and text segment icons (level 1) |

---

## Sequence of Implementation

```
1. RubMethodBaselineProvider (abstract base)
2. RubEpiceaMethodBaselineProvider (simpler, no Iceberg dep)
3. RubGitMethodBaselineProvider (needs Iceberg knowledge)
4. RubGutterDiffDisplayer (the ruler itself)
5. RubScrolledTextMorph (convenience methods)
6. RubGutterDiffPreviewMorph (the diff popup)
7. ClyMethodCodeEditorToolMorph (wire everything together)
```

Steps 1-2 and 6 can be done in parallel.

---

## Verification

- Test manually in a Pharo image by opening a method, editing lines, and verifying the gutter indicators appear/disappear
- Click an indicator → verify the `DiffMorph` popup shows the correct old/new context
- Accept the method → verify all indicators clear
- Verify the ruler correctly repositions on scroll and window resize
- Test with both Git-tracked and non-Git packages
- Verify no performance degradation on rapid typing

---
