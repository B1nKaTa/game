# Art Style Guide

## Look

High-quality moody pixel art, seen from a top-down angle. Dark stone rooms are lit by torches, sparks and glowing enemies, with cold blue-purple shadows against warm orange light. The comedy comes from dreary office details in grim settings, like filing cabinets and take-a-number machines.

## Technical Rules

- Game resolution: 640×360.
- Grandpa: 68×68 frames, with the character about 46 tall inside them.
- Regular enemies: 32 wide frames.
- Senior Adjuster: 48 wide frames. Regional Reaper: 64 wide frames.
- Tiles: 32×32.
- Colors: keep the colors the generator produces, because reducing sprites to art/palette.txt made Grandpa clearly worse. Lighting happens in the engine, so sprites use flat, evenly lit colors with no baked-in glow.
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

Sprites come from PixelLab, whose terms allow commercial use. Grandpa is character `a765494f-e4ed-44db-b5c7-1b7417c6dd24` there.

1. Create the character at 48 px in v3 mode from the base prompt.
2. Generate idle, walk and attack in v3 mode facing east. The game mirrors him for facing left. Custom v3 animations share one scale and canvas, while template animations come out smaller, so don't mix them.
3. Say in every action prompt that he grips the cane in every frame and his body stays unchanged, or the cane vanishes and his body grows.
4. Build each strip from the generated frames, leaving out frame 0, which is only the standing reference. Reorder or drop frames where needed. The attack starts with the cane already forward, because the hit lands the moment the swing starts.
5. Check the frames enlarged, then in the game. Fix stray pixels by hand only if they show in play.

Use `tools/art/cleanup_cli.gd` only for art from tools that don't output true pixel art.

AI use is disclosed wherever a store requires it.
