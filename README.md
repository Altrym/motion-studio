# Motion Studio

Collective intelligence for programmatic animated video creation. Every correction feeds the next generation.

Storyboard or landing page in, high-quality motion system out, with Remotion as the default render target.

## Install

This public repo is the skill distribution.

Install the repo contents as `motion-studio` in your local skills directory:

```text
.claude/skills/motion-studio/
```

Keep the full skill together:
- `VERSION`
- `SKILL.md`
- `references/`
- `scripts/`

Bundled references now include:
- `references/animation-patterns.md` for learned craft defaults
- `references/prompt-recipes.md` for strong starting prompts and prompt upgrades
- `references/remotion-playbook.md` for Remotion-specific composition, timing, assets, audio, and render guidance

## Setup

```bash
# Connect to the community server
export MOTION_STUDIO_API_URL="https://motion-studio.up.railway.app"
export MOTION_STUDIO_API_KEY="your_key"

# Auto-capture corrections after every session (optional, recommended)
# Add to ~/.claude/settings.json:
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

## How It Works

1. You describe a storyboard, idea, product brief, or landing page
2. The skill expands it into a stronger animation brief and scene plan
3. It generates editable assets and scene code, then targets Remotion for rendering
4. You refine the output
5. The post-session hook captures recurring corrections and contributes them back to the shared pattern pool

Works without the server too — falls back to starter patterns in `references/animation-patterns.md`.

## Commands

```bash
bash scripts/sync.sh pull      # Get latest community patterns
bash scripts/sync.sh capture   # Classify current git diffs & push
bash scripts/sync.sh log "description of what you fixed"
bash scripts/sync.sh stats     # Community stats
bash scripts/sync.sh update    # Install the latest Motion Studio bundle
```

## Categories

Prompt Brief · Story Structure · Scene Composition · Motion Timing · Transitions · SVG Assets · Image Prompts · Brand Consistency · Audio & SFX · Rendering & Export

## License

MIT
