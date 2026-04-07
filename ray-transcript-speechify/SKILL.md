---
name: transcript-speechify
description: >
  Convert a raw transcript (talk, lecture, workshop, podcast) into a clean, flowing speech document
  organized by topical sections. Use this skill whenever the user wants to clean up a transcript,
  convert a talk recording to prose, speechify a transcript, or turn raw spoken content into a
  polished document. Trigger on phrases like "speechify", "clean up this transcript",
  "turn this transcript into a speech", "polish this talk", "convert transcript to prose".
---

# Transcript Speechify Skill

## Purpose

Transform a raw transcript into a clean, flowing speech document organized by topical sections (not slide-by-slide or timestamp-by-timestamp), preserving the speaker's natural voice while removing live-delivery artifacts.

## Usage

```
/transcript-speechify <path-to-transcript>
```

Or naturally: "speechify this transcript", "clean up workshop-presentation/transcripts/transcript.md", etc.

## Instructions for Claude

When the user invokes this skill, you will create a **speechify plan** — a structured planning document that drives the entire transformation. You do NOT immediately start writing the speech. The plan is the deliverable of this skill; execution follows from the plan.

### Phase 1: Analyze the Transcript

1. **Read the transcript** end-to-end. Note its structure (slides, timestamps, chapters, or freeform).
2. **Identify the speaker's voice**: casual/formal, technical depth, use of anecdotes, rhetorical patterns.
3. **Catalog content categories**:
   - **Remove**: Jokes, self-deprecating humor, audience banter ("OK, OK", "All right"), stutters/fillers ("uh", "um", "like"), meta-commentary about the presentation itself, references to physical space, logistics (breaks, attendance, seating), navigation filler ("where am I", "let me go back to"), audience polls ("how many of you")
   - **Move**: Content that backtracks or references earlier/later sections should be relocated to the appropriate section
   - **Keep but clean**: Technical explanations, conceptual frameworks, personal anecdotes that illustrate points, quotes, examples, demonstrations
   - **Preserve tone**: Match the speaker's natural explanatory style without live-audience artifacts

### Phase 2: Build the Speech Outline

1. **Restructure by topic, not by source order.** Group content into topical sections (##) and subsections (###). The speech should read as a coherent narrative, not a slide-by-slide replay.
2. **Identify cross-source relocations.** If the speaker revisited a topic later, consolidate that content into the section where it belongs.
3. **Mark demo/example sections.** Any walkthroughs, demonstrations, or extended examples get a `### Demo: [description]` subheader.

### Phase 3: Per-Source Analysis Table

Create a table mapping each source unit (slide, chapter, timestamp block) to:

| Source | Title | Keep | Remove | Demo? | Move/Notes |
|--------|-------|------|--------|-------|------------|

This table is essential for delegation — it lets agents write sections without re-reading the full transcript.

### Phase 4: Create the Plan File

Create `PLAN.speechify.md` (or `PLAN.speechify-<name>.md` if the user has multiple transcripts) using the template below. Update `CLAUDE.local.md` to reference the plan.

### Phase 5: Calibration (do not skip)

Before writing all sections:

1. **Pick two contrasting sections**: one short/narrative, one long/demo-heavy.
2. **Draft both** as temp files.
3. **Spawn a reviewer subagent** to assess both drafts against the calibration criteria (see template).
4. **Record calibration notes** in the plan — these become the style contract for all remaining sections.
5. If the reviewer identifies issues, adjust the approach before proceeding.

### Phase 6: Parallel Transformation

- Write each section to its own temp file: `_speech_S<N>.md` (e.g., `_speech_S1.md`, `_speech_S2a.md`).
- **Launch parallel agents** for independent sections. Each agent gets: the relevant transcript excerpt, the section outline, and the calibration notes.
- **Boundary ownership rule**: When content straddles two sections, assign it to exactly ONE section. Tell the adjacent section's agent explicitly: "do NOT include [X] — it is handled by §[Y]." This prevents duplicates.
- **Plan updates are centralized**: Only the orchestrating (main) agent updates the plan file. Section agents write their output files and report back.

### Phase 7: Assemble and Review

1. **Concatenate** all temp files in order, with YAML frontmatter matching the transcript's metadata.
2. **Delete temp files.**
3. **Run a final review agent** that reads the full assembled document end-to-end checking:
   - Section transitions (jarring boundaries between independently-written sections?)
   - Heading hierarchy consistency
   - Tone consistency across all sections
   - Content completeness (spot-check key items against transcript)
   - Duplicate content (the #1 risk of parallel writing)
4. **Fix any issues** found by the reviewer.
5. **Update the plan** to mark all tasks complete.

## Calibration Criteria

The reviewer subagent (Phase 5) and final reviewer (Phase 7) assess against these criteria:

1. **Tone**: Conversational but not sloppy? Matches speaker's natural voice? Not too formal/academic?
2. **Content**: Substantive points preserved? Nothing important dropped? Any content fabricated?
3. **Cleanup**: Jokes/fillers/tangents removed? Audience interaction artifacts gone?
4. **Flow**: Reads linearly without "let me go back to" jumps? Smooth transitions?
5. **Demos**: Clearly marked with `### Demo:` subheaders? Descriptive prose (what happened), not prescriptive (do this)?
6. **Length**: Appropriate compression — not bullet-pointed, not under-edited with transcript artifacts?

## Calibration Notes Template

After calibration, record these in the plan under `### Calibration Notes`:

- **Tone**: [describe the voice — e.g., first-person, conversational, direct]
- **Demos**: [how to frame them — e.g., descriptive narration of back-and-forth]
- **Transitions**: [style — e.g., natural topic flow, no explicit signposting]
- **Temporal anchoring**: [whether to include specific dates/references]
- **Forward references**: [policy — e.g., avoid orphaned "I will explain later" phrases]
- **Subheaders**: [density — e.g., #### every 150-200 words in long sections]
- **Length calibration**: [targets per section type — e.g., short sections 300-500w, demo-heavy 800-2000w]
- **Compression style**: [e.g., flowing prose paragraphs, never bullet points]

## Plan File Template

````markdown
# Speechify: [Title from transcript]

> **IMPORTANT**: This plan must be kept up-to-date at all times. Assume context can be cleared at any time — this file is the single source of truth for the current state of this work. Update this plan before and after task and subtask implementations.

## Branch

`speechify` (or current branch)

## Goal

Convert `[path/to/transcript.md]` into a clean, flowing speech document (`[path/to/speech.md]`), organized by topical sections (not [slides/timestamps/chapters]), preserving the speaker's natural voice while removing [jokes, stutters, tangents, and audience interaction artifacts].

## Strategy

This is a content transformation task (no code/tests). The work breaks into phases:

1. **Analyze** — Catalog per-[source unit] what needs removing, moving, or rewriting
2. **Transform** — Process each section's content into clean speech prose
3. **Review** — Verify linear flow, no content loss, consistent voice

## Current State

- [ ] Plan created
- [ ] Analysis complete
- [ ] Calibration complete
- [ ] Transformation complete
- [ ] Review and verification complete

## Key Findings

**Source file**: `[path]` — [N] [slides/chapters/segments], ~[N] lines of raw transcript.

**Output file**: `[path/to/speech.md]`

**Speech outline** (## = section, ### = subsection):

```
[To be filled in — topical sections, not source-order replay]
```

**Content categories**:

- **Remove**: [specific to this transcript]
- **Move**: [cross-section relocations]
- **Keep but clean**: [substantive content types]
- **Preserve tone**: [describe the speaker's voice]

**Per-source analysis**:

| Source | Title | Keep | Remove | Demo? | Move/Notes |
|--------|-------|------|--------|-------|------------|
| [fill in] | | | | | |

## Questions

> Questions must be crossed off when resolved. Note the decision made. For straightforward transformations, embed default decisions here rather than blocking on user input.

- [ ] [To be added — only for genuinely ambiguous decisions]

## Tasks

- [ ] 1. Resolve any open questions
- [ ] 2. Per-source analysis (see table above)
- [ ] 3. Restructure: speech outline by topical sections
- [ ] 4. **Calibration phase**:
  - [ ] 4a. Draft a short/narrative sample section
  - [ ] 4b. Draft a long/demo-heavy sample section
  - [ ] 4c. Spawn reviewer subagent, assess against calibration criteria
  - [ ] 4d. Record calibration notes in this plan, adjust approach if needed
- [ ] 5. Transform all sections into temp files (`_speech_S*.md`):
  - **File convention**: `_speech_S<N>.md`
  - **Boundary rule**: Content straddling sections is assigned to exactly ONE section; adjacent section is told explicitly not to include it
  - **Plan ownership**: Only the main agent updates this plan file
  [List all section files here as subtasks]
- [ ] 6. Assemble: concatenate temp files with YAML frontmatter into `speech.md`
- [ ] 7. Cleanup: delete `_speech_S*.md` temp files
- [ ] 8. Final review: full end-to-end read for transitions, duplicates, tone, content
- [ ] 9. Fix any issues found in review

## Completed

(none yet)

---

Last updated: [date]
````

## Lessons Learned (from prior use)

These are hard-won lessons. Follow them:

1. **Calibration is the highest-value step.** Two contrasting samples + structured review produces guidelines that keep 10+ parallel agents consistent. Never skip it.
2. **Per-source analysis table is essential for delegation.** Without it, every agent must re-read the full transcript to know what to include/exclude.
3. **Boundary ownership prevents duplicates.** When content spans two sections, assign it to one and explicitly exclude it from the other. "Include it if it flows naturally" is ambiguous and causes duplicates.
4. **Centralize plan updates.** Only the orchestrating agent writes to the plan file. Section agents report back; the orchestrator marks tasks complete. Multiple writers cause inconsistent state.
5. **The final review must be a narrative read-through**, not just a checklist spot-check. The #1 post-assembly risk is jarring transitions and duplicated content at section boundaries — these only surface by reading sequentially.
6. **Embed default decisions for straightforward questions.** Don't block on user input for obvious choices (keep YAML frontmatter? omit logistical slides?). Reserve formal Q&A for genuinely ambiguous decisions.
7. **Flat task numbering, no duplicates.** Use a single numbered task list. Never repeat task numbers or have the same task appear in two places in the plan.
