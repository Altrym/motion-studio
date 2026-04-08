# Motion Studio Community Animation Patterns

> **Version**: 1.0.0
> **Patterns**: 40
> **Contributors**: Seeded from maintainers; designed to improve through shared corrections
> **Last Updated**: 2026-04-08

These are reusable corrections for AI-generated motion graphics and Remotion-ready videos. Read only the categories relevant to the current task.

## Prompt Brief

- Convert vague requests into a production brief before generating code: audience, goal, duration, aspect ratio, tone, visual style, scene list, and CTA.
- If the user provides a landing page or product site, extract the visual system first instead of inventing a disconnected style.
- Default to 15 to 30 seconds for promos and 30 to 60 seconds for explainers unless the user specifies otherwise.
- Lock the format early. A 16:9 launch video, 9:16 social clip, and looping hero background need different composition and pacing.

## Story Structure

- Start with a visual hook in the first 2 seconds.
- Give each scene one primary idea.
- Alternate bold claim with proof such as UI, feature detail, or outcome.
- End with a readable CTA or logo hold instead of cutting away instantly.

## Scene Composition

- Use one dominant focal plane per scene.
- Preserve negative space around headlines and product UI.
- Device mockups should support the message, not dominate every frame.
- Layer foreground, midground, and background so motion has depth.

## Motion Timing

- Animate mostly with transforms and opacity.
- Text needs dwell time; if it cannot be read comfortably, the scene is too fast.
- Use stagger to express hierarchy, not decoration.
- Choose easing deliberately based on the tone of the piece.

## Transitions

- Carry a visual thread across scenes: color, shape, screenshot, line, or motion vector.
- Avoid stacking unrelated transition tricks.
- Mask reveals and wipes work best when they align with scene geometry.
- For looping videos, make the final state hand off cleanly to the first.

## SVG Assets

- Prefer SVG for logos, icons, charts, line art, and diagrams that need animation.
- Break SVGs into meaningful groups so fills, strokes, and transforms can animate independently.
- Stroke-draw sequences should follow reading order or intended eye movement.
- Use gradients and filters sparingly to protect export performance.

## Image Prompts

- Generate still images with explicit framing and intended use, such as "wide background plate for scene 2."
- Ask for negative space where text will sit.
- Keep lens, lighting, and color temperature consistent across generated scenes.
- Stylized illustration often survives motion better than over-detailed photoreal imagery.

## Brand Consistency

- If brand assets exist, inherit them.
- Typography should match the product's voice and audience.
- Reuse UI tokens from the product when animating screenshots and cards.
- Keep copy short; motion amplifies weak writing.

## Audio and SFX

- Sound should accent transitions and reveals, not cover every second.
- Align major cuts and hero reveals to musical phrases when a soundtrack exists.
- Use one sonic family per video.
- Leave room at the end for a logo sting or CTA hold.

## Rendering and Export

- Keep timing deterministic and centralized.
- Test at the intended aspect ratio from the start.
- Heavy blur, shadows, and particles can wreck render performance.
- The browser preview should already resemble the final video; export should be a render step, not a redesign step.
