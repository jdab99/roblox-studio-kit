# Blocky Tales style kit (built for reel 02 "The Wish Star", 11-02)

The look every reel shares: golden-hour town, big expressive faces, wish-star style markers, VFX, block pets.
`film.py` builds each Director as `core.luau` + `kit.luau` + `<reel>/shots.luau`, and installs `kit_sets.luau`
(into `workspace.Film.KitSets`) with the base. A reel uses the kit through ONE table, `K`.

## Start a reel
- `shots.luau`: write shots with `K.sh(time, preset, setup, update)` (not core `shot`). `K.sh` cleans pets, props,
  markers, DOF, overlays and flags at every cut and turns on the anime sky. Reel 02's `shots.luau` is the example.
- Your own places: `local R = {}` then `R.MYSPOT = K.TOWN + V(x, y, z)`. Keep helpers in tables (200-locals limit).
- Your own actors: `cast.luau` in the reel folder (copy reel 02's: classic head + v2 faces, builds into `Film.ReelCast`).
- Reel-only sets: `sets.luau` builds ONLY into `Film.ReelSets` (optional; reel 02 needs none).
- Check every shot: `python tools\film.py stills <reel> <out> T1 T2 ...`. Studio must be on screen (not hidden behind
  a maximized window): a fully covered Studio stops drawing the Play view and the stills fail ("magenta marker not visible").

## Lighting presets (`light()` names, also usable as the `K.sh` preset)
| name | use |
|---|---|
| `golden` | golden-hour day outside (deep blue anime sky, warm sun, hazy mountains, bloom + rays) |
| `goldenClose` | same light, a touch darker for tight face close-ups (faces never blow out) |
| `dayIn` | bright clean interior day (vet, school, bedroom by day) |
| `moon` | blue moonlit room at night |
| `lamp` | warm lamp-lit night interior (vet at night, bedside) |
| `dusk` | purple-orange eerie evening (comment-bait holds) |
| `winter` | sunny cold afternoon, blue shadows (snowy park) |
| `dawnIn` | soft first light through a window |
| `flashback` | dreamy warm low-contrast memory |
| `lampWarm` | brighter warm lamp-lit night room (vet at night) |
| `nursery` | hospital room at night, soft blue-white (add warm `K.lamp`s at about 0.5 brightness; stronger blows the white room out) |
Core presets still exist: `night store dark interior predawn sunrise morning`.

## Faces (`act(name, mood, ...)`)
v2 art (`tools/draw_faces_v2.py`, ids in `assets/faces/face_ids_v2.json`): `happy2 laugh2 scream shocked2 scared2 dizzy
angry2 smug creepy cry starry focus nervous wow sad2`. Old v1 names still work: `happy shocked scared sneaky angry sad sleep laugh`.
(`crayon` = a kid-drawing face, used on decals only.) Cast built with the reel-02 `cast.luau` starts with v2 art.

## Actors
- `K.ANIM` stock R15 emotes, loaded on every actor: `wave point cheer laugh dance jump sit` -> `act("Max", "laugh2", "cheer")`.
- Extra poses: `P.pet P.hug P.handsUp P.facepalm P.earsCover P.shrug` (core has `hold bars armsUp reach sitChair sitGround
  drive cry sneak lean laugh flash scared bagFront`). Mix with `merge(P.a, P.b)`.

## Pets (block builds in `KitSets.Pets`, posed every frame)
`Biscuit` (big old golden dog, red collar, grey muzzle), `Pup` (Biscuit as a real puppy: round, big head + eyes, about 2.7 tall;
use `K.PUP.lieDrop / crawlDrop / sitDrop` with the dog gaits), `Puppy` (old shrunk-adult build, avoid), `DogSpot` (white), `DogBrown`,
`Cat` (orange tabby), `Hamster`, `Parrot`, `Goldfish`, `BigFish` (car-sized), `FishLegs` (goldfish on legs).
- `K.pose(name, rootCF, joints, scale)` root = between the feet, front = the CFrame's look direction.
- Dog gaits: `K.DOG.walk(T, speed, amp)`, `K.DOG.lie(T, headDown, wag)` (lower root by `K.DOG.lieDrop`),
  `K.DOG.sit(T, tilt, wag)` (lower by `K.DOG.sitDrop`, 1.05: a real sit since 11-02 ph2), `K.DOG.crawl(T, speed)` belly-low (lower by `K.DOG.crawlDrop`),
  `K.DOG.pull(T, slip)` braced pulling backward (slip 0..1 skids the paws), `K.DOG.swim(T)` (head up, paddling; sink the root so only the head shows), `K.DOG.stand(T, tilt, wag)`. Joints: `Body Head EarL EarR Tail LegFL LegFR LegBL LegBR`.
  Cat: `Body Head Tail Leg*`; Parrot: `Body Head Jaw WingL WingR`; fish: `Body Tail`; FishLegs adds `LegL LegR`.
- `K.petFace(name, eyes, tongue, brows)`: eyes `open|closed|squint`, tongue true/false, brows `sad|up|nil` (dogs).
- `K.head(name)`, `K.fwd(name)`: head position / facing, for cameras and markers.

## Markers (wish star, numbers, icons over heads)
- `K.star(key, size, ghost)` gold wish star (ghost = dashed empty outline). `K.mark(key, {text="3"})` a Ralph-style number;
  `K.mark(key, {image=id, size=, color=, glow=, sparkle=})` any icon.
- Move every frame: `K.starOver(key, petName, T)`, `K.over(key, petOrActorNameOrVector3, T, up)`, `K.markAt(key, pos, T)`.
- `K.pop(key, t0, T)`: burst + sparkles + gone at t0.

## VFX (all cleaned at the next cut)
`K.burst(pos, n, color, size, speed)` sparkle burst - `K.puffs(pos, n, color, size)` dust/poof - `K.motes(pos, rate, color, size)`
magic floating sparkles - `K.ring(pos, t0, T, radius, dur, color)` glow ring on the ground - `K.speed(alpha, T)` anime speed lines
- `K.flash(alpha)` white flash - `K.say(part, text, studs)` speech bubble (returns bb, label) - `K.emitter(...)`, `K.bill(...)` raw parts.
`K.splash(pos, n, size)` water splash - `K.bubbles(pos, rate)` rising bubbles - `K.snowfall(pos, w, rate)` falling snow (prefilled) -
`K.breath(who, T, every)` cold-breath puffs from an actor's or pet's mouth (call every frame) - `K.tint(color, sat, contrast)` colour the frame (e.g. icy water) -
`K.lamp(pos, color, brightness, range)` an extra light for one shot - `K.cracks(key, centre, t0, T, n, len, dur, seed)` crack lines racing over ice.
Ice hole: `K.iceOpen(u, T, sink)` tips/sinks the hole chunks (u 0..1), `K.iceChunk(i, cf)` moves one (1..9), `K.iceHome(i)`; every cut puts them back.
Speech bubbles and markers counter-rotate by `K.ROLL` (90) and `K.say` offsets in WORLD space, so text reads upright in the 9:16 video.
Textures: `K.TEX.glow burst ring puff speedlines sparkle star ghost` (art in `assets/vfx`, made by `tools/draw_vfx.py`).

## Camera
`camMove(e1, l1, e2, l2, u, fov)` (core) + `K.dof(focusDist, radius, far, near)` depth of field (nil = off) +
`K.handheld(T, amp)` drift, `K.shake(T, t0, dur, amp)` impact shake (add to the eye), `K.whip(T, t0, dur)` whip-pan blend 0..1
with speed lines, `K.orbit(centre, deg, radius, h)`, `K.frontCam(pet, dist, up, side, h)` eye + look in front of a pet's face,
`K.face(p, x, z)` root CFrame at p looking at (x, z). Close-ups: FOV 45-50, 4-6 studs off a face, DOF radius 1.5-3.

## Props (`KitSets.Props`, `K.prop(name, cf)`, parked at every cut)
`FoodBowl Vacuum Magnifier FishBowl Perch DogBed Blanket Sled RockingChair Baby`.

## The kit world (K.TOWN = (0, 0, -3000); `K.SPOT.*` has these points)
- Ground top y 0. **Maple Street** road along X (-330..330, z -11..11), sidewalks top 0.55 (z -19..-11 and 11..19).
- **Houses** (Creator Store, scripts stripped): north side x = -175, -60, 60, 175 (fronts at z -24), south side mirrored
  (fronts at z 24). Sage-green two-storey at x 60 north = `K.SPOT.yard` lawn (its brick mailbox at x 84, z -26).
  Street trees every ~58 studs at z +-21. Pine forest band r 250..1050, mountain ring r ~1550-1800 (horizon).
- **School** front plaza `K.SPOT.school` (school at x ~500 facing -X). **Ferris wheel** `K.SPOT.ferris`. Playground `K.SPOT.playground`.
- **Snowy park** `K.SPOT.winter` (ice top y 0.85, dark water top 0.35 under it, snow 0.2) (snow disc r 150, sled hill NW, snowy pines, THIN ICE sign `KitSets.Winter.ThinIceSign`),
  frozen pond `K.SPOT.pond`, ice hole `K.SPOT.hole` with chunks `KitSets.Winter.Ice.Ice1..Ice8` (attribute `Home`) to crack/sink.
- **Interiors** in the west woods: bedroom `K.SPOT.bed` (store "Kids bedroom", bed head at z -67), vet room `K.SPOT.vet`
  (exam table top 3.4, lamp), nursery `K.SPOT.nursery` (incubator mattress top 3.6, monitor, chair, night window),
  school hallway `K.SPOT.hallway` (lockers, trophy case, banner), boy's bedroom `K.SPOT.boyroom` (blue + orange, bed head on the
  north wall, mattress top 2.6, posters, toys, window; open floor south of the bed for the `DogBed` prop). Vet room has two chairs
  (seat top 2.2, x -7.4..-4.8, z 0 and 3.4, facing +X); the nursery has a real round wall clock at 3:00 (north wall, NU + (-4, 10, -11.8)) and stars in its night window.

## Creator Store assets in the kit (every script deleted on load; `ScriptsStripped` attribute on each)
houses 18102018549, 317197851 (1 stripped), 16127244089 (14), 125443645311849, 18609718207 (14); street tree 12605122162;
pines 5392132809, 183435411; snowy pine 11590212184; mountains 11720266086, 8761896930; school 76558120171446;
playground 3699248235 (9); kids bedroom 5474231697; Ferris wheel 7159480504 (1); rocking chair 303336108.
A load checks again for any script and errors if one survived.

## Kit change log
- 11-02 phase 2 (reel 02): added `LP.lampWarm`, `K.DOG.crawl/pull/swim`, `K.DOG.crawlDrop`, ice-hole functions, `K.cracks`, `K.splash`,
  `K.bubbles`, `K.snowfall`, `K.breath`, `K.tint`, `K.lamp`, `K.SPOT.boyroom`; boy's bedroom, vet chairs, nursery clock, `Ice9`; pond ice now
  reaches the bank and sits above the water. Changed inside (same signatures): `K.DOG.sit` now reads as sitting (`sitDrop` 0.9 -> 1.05),
  `K.say` bubbles offset in world space, `K.reset` also resets the ice.
- 11-02 v2: added the `Pup` build, `K.PUP`, `K.STAR_UP.Pup`, `LP.nursery`, the nursery wall clock + window stars (replaced the 3:00 text card).
