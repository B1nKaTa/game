# Art Style Guide

## Look

High-quality moody pixel art, seen from a top-down angle. Dark stone rooms are lit by torches, sparks and glowing enemies, with cold blue-purple shadows against warm orange light. The comedy comes from dreary office details in grim settings, like filing cabinets and take-a-number machines.

## Technical Rules

- Game resolution: 640×360.
- Grandpa: about 32 wide by 48 tall.
- Regular enemies: 32 wide frames.
- Senior Adjuster: 48 wide frames. Regional Reaper: 64 wide frames.
- Tiles: 32×32.
- Colors: only those in art/palette.txt. Lighting happens in the engine, so sprites use flat, evenly lit colors with no baked-in glow.
- Backgrounds: transparent.

## File Layout

Sprites go in `art/sprites/<id>/<anim>.png` as one horizontal strip per animation. The game uses them automatically in place of placeholders.

- `<id>` matches the enemy's id in its data file, or `grandpa` or `merchant`.
- `<anim>` is `idle`, `walk` or `attack`.

Open the project in the Godot editor once after adding files, so they get imported.

## Prompts

Never use names of other games, studios or artists in prompts. Describe the look directly.

Base prompt for a character:

> Pixel art game sprite, single character on a plain flat background, 3/4 top-down view, clean dark outline, limited color palette, flat even lighting, no shadows on the ground, no text. {SUBJECT}

Subjects:

- **Grandpa:** A grumpy thin old man with white hair and a big white mustache, round glasses, olive green cardigan, brown trousers, holding a wooden walking cane.
- **Intern Reaper:** A small nervous hooded skeleton in an ill-fitting dark purple robe, holding a small scythe and a lanyard.
- **Filing Clerk:** A tired grey ghost-like office worker in a short-sleeved shirt and tie, carrying a stack of paper.
- **Debt Collector Ghost:** A floating teal ghost wearing a cheap suit jacket, holding a clipboard.
- **Senior Adjuster:** A large hooded skeleton in a deep red robe, wearing a tie, holding a long scythe.
- **Regional Reaper:** A towering dark hooded reaper with a huge scythe and a name badge, glowing teal eyes.
- **Merchant:** A shady hooded figure in a purple coat, with the coat held open to show stolen goods.

## Processing

1. Generate at the largest size the tool allows, using a tool whose terms allow commercial use.
2. Remove the background.
3. Run the cleanup command, which reduces the image to the game's pixel grid and palette:

       godot --headless --path . --script res://tools/art/cleanup_cli.gd -- input.png output.png 32 48

4. Fix stray pixels and frame-to-frame differences by hand in a pixel art editor.

AI use is disclosed wherever a store requires it.
