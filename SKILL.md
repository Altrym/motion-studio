---
name: motion-studio
description: "Create high-quality animated videos from a storyboard, rough idea, product brief, landing page, screenshot, or existing app. Use for launch videos, explainers, hero loops, social clips, motion graphics, logo reveals, SVG animation, and Remotion-based video generation. The skill turns loose prompts into a structured video brief, layered assets, scene code, and shared improvements learned from prior user corrections."
---

# Motion Studio — Programmatic Video Creation with Shared Learning

This skill should behave like Replit's Animated Videos flow at the front of the process: take a rough prompt, enrich it into a stronger creative brief, generate editable assets and animation code, then iterate conversationally. For rendering, it is fine to use Remotion as the default export path.

## Before Generating

Pull the latest patterns from the Motion Studio API:

```bash
bash scripts/sync.sh pull
```

This returns categorized animation patterns with confirmation counts. Higher count means more builders independently made the same correction, so treat those patterns as stronger defaults.

If the server is unreachable, fall back to `references/animation-patterns.md`.

## Embedded Remotion Workflow

When the work turns into actual Remotion code, treat the Remotion skill as a built-in secondary workflow instead of improvising from scratch.

Load `references/remotion-playbook.md` when you need any of these:
- composition structure or `calculateMetadata()`
- scene sequencing, timing, transitions, or trims
- audio, voiceover, captions, or sound design timing
- asset handling for images, video, fonts, Lottie, charts, or maps
- FFmpeg-style preprocessing such as trimming clips or detecting silence
- rendering/export decisions, transparency, codecs, or media-debugging

Do not load the whole playbook by default. Pull only the relevant subsection once the task clearly becomes Remotion-specific.

If the user wants inspiration, stronger prompt structure, or concrete video starting points, load `references/prompt-recipes.md`.

## Operating Model

- Treat the final video as software, not as raw text-to-video generation.
- Use AI image generation only for still assets, environments, plates, or illustrations that will then be animated in code.
- Keep outputs editable: scene components, SVGs, captions, JSON data, screenshots, and layered assets.
- Default render target: Remotion.
- Default implementation style: React scenes plus standard web animation techniques such as CSS transforms, SVG animation, Motion / Framer Motion, and lightweight canvas when needed.

## Workflow

### 1. Intake

Accept any of these as valid starting points:
- storyboard
- loose concept
- landing page URL
- screenshots
- product or feature brief
- existing video that needs improvement

If a landing page or app exists, extract the brand system before generating:
- product promise
- headline structure
- palette
- typography
- screenshots or UI motifs
- iconography
- CTA language

### 2. Enhanced Brief

Before coding, convert the request into a compact internal production brief:
- objective
- audience
- duration
- aspect ratio
- style direction
- motion language
- scene list
- asset plan
- audio direction
- final CTA

This mirrors Replit's "enhance prompt" behavior for video prompts. Do not stay at the level of the user's vague wording if a sharper brief can be inferred safely.

When turning a loose prompt into a buildable brief:
- make timing explicit in seconds and, when useful, frames
- name the fps when motion smoothness matters
- describe motion behavior, not just the final state
- break complex videos into scenes or beats before implementation
- prefer staggered entrances, springs, and easing over simultaneous linear motion
- if the user requests a long or crowded video, split it into scenes first and only then sequence it

### 3. Scene Planning

- Break the video into explicit scenes or beats with rough timing.
- Each scene should communicate one main idea.
- For product videos, alternate between claim, proof, and payoff.
- For explainers, a strong default is hook -> problem -> mechanism -> benefit -> CTA.
- Prefer 4 to 8 strong scenes over many weak ones.

### 4. Asset Creation

- Build vectors, shapes, masks, gradients, charts, device frames, captions, and logos as SVG or code whenever possible.
- Generate images only when they materially improve the concept.
- When the input is a landing page, derive assets from the page before inventing new ones.
- Keep assets reusable across scenes.

### 5. Animation Implementation

- Use a central timeline model so scene durations and transitions stay coherent.
- Prefer transform and opacity animation over layout thrash.
- Make the first 2 to 3 seconds visually decisive.
- Keep text readable at the target aspect ratio.
- Design for browser preview first, then render via Remotion.
- When Remotion details matter, switch to `references/remotion-playbook.md` and apply the matching section for compositions, sequencing, timing, assets, audio, subtitles, or rendering.

### 6. Rendering

- Default to a Remotion pipeline for export and frame-accurate rendering.
- Structure scenes so they can map cleanly to Remotion compositions or timed sequences.
- If a live browser preview exists, keep its timing aligned with the Remotion render model instead of maintaining two unrelated timelines.
- If the user asks for a full Remotion deliverable, include composition wiring and explicit duration / fps settings instead of returning only a leaf component.

## Pattern Categories

Apply the relevant categories from `references/animation-patterns.md`:
- `prompt-brief`
- `story-structure`
- `scene-composition`
- `motion-timing`
- `transitions`
- `svg-assets`
- `image-prompts`
- `brand-consistency`
- `audio-sfx`
- `rendering-export`

## Final Review

Before finalizing, check:
1. Does the opening hook quickly?
2. Does each scene have one clear job?
3. Are the visuals tied to the product or concept rather than generic motion design?
4. Are the assets editable and reusable?
5. Do transitions help continuity instead of showing off?
6. Is the type readable at export size?
7. Is the timeline coherent enough to render cleanly in Remotion?

## Learning and Community Improvement

Corrections are captured and pushed to the API automatically via the post-session hook, or manually:

```bash
bash scripts/sync.sh capture
bash scripts/sync.sh log "headline needed more dwell time before CTA"
```

The server should classify each correction into an animation category, extract a reusable pattern, and add it to the shared pool. If many users keep making the same fix, everyone using the skill should inherit that improvement as a stronger default.

Do not leak proprietary client details. Generalize corrections into reusable animation guidance.

## Setup

```bash
export MOTION_STUDIO_API_URL="https://motion-studio.up.railway.app"
export MOTION_STUDIO_API_KEY="your_key"
```

Auto-capture hook:

```json
{
  "hooks": {
    "Stop": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/skills/motion-studio/scripts/capture-hook.sh"
      }]
    }]
  }
}
```

## File Map

```text
motion-studio/
├── VERSION
├── SKILL.md
├── references/
│   ├── animation-patterns.md
│   ├── prompt-recipes.md
│   └── remotion-playbook.md
└── scripts/
    ├── sync.sh
    ├── capture-hook.sh
    └── classify-local.py
```

## Updating

Installed copies do not hot-reload the skill files on every use.

Instead:
- `pull`, `capture`, `log`, and `stats` do a lightweight periodic update check against the Motion Studio server
- if a newer bundle exists, the script tells the user to run `bash scripts/sync.sh update`
- `bash scripts/sync.sh update` downloads and installs the latest full skill bundle, including `SKILL.md`, `references/`, and `scripts/`
