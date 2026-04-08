#!/usr/bin/env python3
"""
Motion Studio Local Classifier — Offline fallback for animation diff classification.
Uses keyword matching when the server API is unreachable.

Usage: echo "diff content" | python3 classify-local.py scene.tsx
"""

import json
import sys

CATEGORY_SIGNALS = {
    "prompt-brief": [
        "brief", "audience", "duration", "aspect ratio", "tone", "style",
        "cta", "landing page", "brand voice", "product promise",
    ],
    "story-structure": [
        "hook", "opening", "ending", "scene order", "sequence", "beat", "arc",
        "act", "outline", "takeaway", "learning objective", "payoff",
        "example", "analogy", "question", "misconception", "storyboard", "chapter",
    ],
    "scene-composition": [
        "layout", "hierarchy", "frame", "contrast", "color", "colour",
        "typography", "label", "diagram", "icon", "callout", "grid",
        "alignment", "readability", "shot", "composition", "visual", "screen",
        "mockup", "foreground", "midground", "background", "negative space",
    ],
    "motion-timing": [
        "keyframe", "easing", "ease", "duration", "timing", "pace", "pacing",
        "transition", "cut", "camera", "zoom", "pan", "hold", "stagger",
        "animate", "animation", "loop", "tempo", "trim",
    ],
    "transitions": [
        "wipe", "morph", "crossfade", "reveal", "mask", "handoff", "enter", "exit",
    ],
    "svg-assets": [
        "<svg", "path", "stroke", "fill", "viewbox", "gradient", "mask",
        "clippath", "logo", "illustration", "icon",
    ],
    "image-prompts": [
        "image prompt", "background plate", "lighting", "lens", "photoreal",
        "illustration", "negative space",
    ],
    "brand-consistency": [
        "brand", "palette", "font", "typography", "design system",
        "screenshot", "landing page", "ui", "logo",
    ],
    "audio-sfx": [
        "audio", "music", "sfx", "voice", "voiceover", "narrator", "caption",
        "subtitle", "vtt", "srt", "duck", "ducking", "mix", "loudness",
        "pronunciation", "breath", "sync", "emphasis", "pause",
    ],
    "rendering-export": [
        "remotion", "render", "export", "fps", "frame", "composition",
        "mp4", "preview", "1080p", "720p",
    ],
}


def classify(filename: str, diff_text: str) -> dict:
    text = (filename + " " + diff_text).lower()

    scores = {}
    for category, signals in CATEGORY_SIGNALS.items():
        score = sum(1 for signal in signals if signal.lower() in text)
        if score > 0:
            scores[category] = score

    if not scores:
        return {
            "category": "general",
            "pattern": f"Unclassified correction in {filename}",
            "is_animation_relevant": True,
        }

    best_cat = max(scores, key=scores.get)
    added_lines = [
        line[1:].strip()
        for line in diff_text.split("\n")
        if line.startswith("+") and not line.startswith("+++")
    ]
    removed_lines = [
        line[1:].strip()
        for line in diff_text.split("\n")
        if line.startswith("-") and not line.startswith("---")
    ]

    if added_lines and removed_lines:
        pattern = f"Changed: '{removed_lines[0][:50]}' -> '{added_lines[0][:50]}'"
    elif added_lines:
        pattern = f"Added: '{added_lines[0][:60]}'"
    elif removed_lines:
        pattern = f"Removed: '{removed_lines[0][:60]}'"
    else:
        pattern = f"Correction in {filename}"

    return {
        "category": best_cat,
        "pattern": pattern,
        "is_animation_relevant": True,
    }


if __name__ == "__main__":
    filename = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    diff_text = sys.stdin.read()
    result = classify(filename, diff_text)
    print(json.dumps(result))
