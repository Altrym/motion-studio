# Remotion Playbook

Use this reference when Motion Studio has clearly crossed into Remotion-specific work.

## When To Load This

Load only the subsection you need:
- compositions or `calculateMetadata()` for duration, dimensions, or props
- sequencing, transitions, trims, or frame math
- media assets such as images, video, audio, fonts, or Lottie
- subtitles, captions, or text timing
- voiceover, sound effects, or audio-reactive visuals
- FFmpeg-style preprocessing before rendering
- export, transparency, codec, or decode troubleshooting

This playbook is adapted from the Remotion skill published at:
`https://github.com/remotion-dev/skills/blob/main/skills/remotion/SKILL.md`

## Core Defaults

- Model the video as compositions plus timed sequences, not one monolithic component.
- Keep duration explicit in both seconds and frames when precision matters.
- Use `useCurrentFrame()` and `useVideoConfig()` as the default timing primitives.
- Prefer `interpolate()` and `spring()` over ad hoc timing math.
- Keep scene timing coherent between preview and final render.
- When a prompt asks for a renderable result, include composition setup, not only scene internals.
- Default delivery should be a rendered `.mp4`, with the underlying Remotion project files preserved for iteration.

## Section Guide

### Compositions

Use when:
- the project needs a root composition
- duration depends on props or scene count
- dimensions, fps, or default props must be declared

Default approach:
- define a clear root composition
- use `calculateMetadata()` when duration or size depends on inputs
- keep one composition per final video output, with scenes implemented beneath it

### Sequencing And Timing

Use when:
- scenes must appear in order
- entrances should be staggered
- elements need trims, offsets, or holds

Default approach:
- map each beat to a sequence with explicit start and duration
- specify delays and overlaps in frames
- avoid letting all elements animate at once unless the scene genuinely calls for it

### Animations And Transitions

Use when:
- motion needs to feel polished instead of robotic
- scenes need entrances, exits, or handoffs

Default approach:
- use spring-based motion for UI reveals, counters, and callouts
- use easing and interpolation for fades, scales, slides, and blurs
- keep transitions in service of readability, not spectacle

### Assets

Use when:
- the video includes UI mockups, screenshots, video clips, images, fonts, charts, or Lottie

Default approach:
- import assets in a Remotion-safe way
- keep fonts explicit and reproducible
- preprocess awkward media before using it in the composition if it simplifies playback

### Audio, Voiceover, And Sound Design

Use when:
- the output includes narration, music, sound effects, or waveform / spectrum visuals

Default approach:
- sync motion beats to voiceover structure
- trim and level audio deliberately
- treat voiceover timing as a first-class part of the composition

### Subtitles And Captions

Use when:
- narration needs on-screen text
- the project needs accessibility or social-video subtitle behavior

Default approach:
- time captions to phrases, not arbitrary line breaks
- avoid overly long caption blocks
- keep typography readable at target resolution

### FFmpeg And Media Prep

Use when:
- clips need trimming before entering Remotion
- silence detection or preprocessing is easier outside the composition
- codec or export problems are blocking progress

Default approach:
- use FFmpeg for clip surgery and media cleanup
- keep Remotion focused on composition and rendering, not heavy preprocessing

### Final Delivery

Use when:
- the user needs a reviewable handoff
- the project is ready for a first finished render

Default approach:
- render an `.mp4` as the primary output unless the user asked for another format
- keep the Remotion composition, scene components, assets, and timing code in the output too
- treat the `.mp4` as the review artifact and the source files as the iteration artifact

## Common Corrections

- If the result is only a component, add root composition wiring.
- If the duration is wrong, restate total seconds and total frames.
- If everything animates together, convert it into staggered sequences.
- If motion feels dead, replace linear timing with springs or easing.
- If the request is too large, split scenes first, then assemble them in the root composition.
