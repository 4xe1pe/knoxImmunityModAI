# Knox Bite Immunity

A Project Zomboid **Build 42.20+** mod: zombie bites still hurt, bleed and need treatment, but they **no longer transmit the Knox virus**.

> 🤖 **Made by an AI.** This mod was written by Claude (Anthropic's AI assistant) at the request of the repository owner, who directed the requirements and published it. The code was checked with a mock simulation and against the unofficial 42.20.0 Javadoc, and **it has been tested inside the game by the author **

## What it does

| Event | Behaviour |
|---|---|
| Zombie bite | Damage, pain, bleeding, deep wound, bandage need and normal bacterial wound infection are **unchanged**. Only the Knox virus is removed. |
| Scratch | Vanilla behaviour, vanilla infection chance. |
| Laceration | Vanilla behaviour, vanilla infection chance. |
| Everything else | Untouched. The character is not invulnerable and zombies can still bite. |

## How it works

The mod never cancels the bite or edits infection probabilities. Each tick it watches the player's Knox flag. When it flips from *not infected* to *infected*:

1. If a scratch or laceration newly appeared (or the newly infected body part carries only a scratch/laceration), the infection is **left alone**.
2. Otherwise the infection is attributed to a bite, and only the virus state is reverted (`setInfected(false)`, the infected flag on the bitten part, and the infection timers restored to their previous clean values).

Only `BodyDamage` / `BodyPart` methods listed in the 42.20.0 Javadoc are used, and none take a `BodyPartType` enum.

## Install

1. Copy `Contents/mods/KnoxBiteImmunity` into your `Zomboid/mods/` folder (or into `Zomboid/Workshop/<ModName>/Contents/mods/` for a local workshop item).
2. Enable **Knox Bite Immunity** in the in-game Mods menu.

Works on new and existing saves, nothing is written into the save, and it can be removed at any time. Already infected characters are **not** cured.

## Structure

```
Contents/mods/KnoxBiteImmunity/
├── common/
└── 42/
    ├── mod.info
    └── media/lua/
        ├── client/KnoxBiteImmunity.lua        # event wiring
        └── shared/KnoxBiteImmunity_Core.lua   # detection + revert logic
```

## Status & known limits

- **Not yet verified in game.** Simulated scenarios (bite, repeated bite on the same part, scratch/laceration infection, reload, pre-existing infection) pass; real-game testing is still needed.
- If a bite and a scratch happen in the exact same tick, the infection is kept (cannot tell them apart).
- If 42.20 does not set the per-part infected flag, a repeated scratch on an already scratched part could be mistaken for a bite (only affects the ~7% scratch infection roll).
- Multiplayer is untested; the logic is client-side.
- To see debug output, set `Core.DEBUG = true` in `KnoxBiteImmunity_Core.lua`. If the mod errors, it disables itself and logs `[KnoxBiteImmunity] disabled after error`.

Bug reports with the console log are very welcome.

## License

[The Unlicense](LICENSE) (public domain). Anyone can copy, modify, redistribute or sell it for any purpose, with no attribution required. Licenza: pubblico dominio, ognuno può farne ciò che vuole.

---

## 🇮🇹 In breve

Mod per Project Zomboid **Build 42.20+**: il morso di zombie infligge ancora danni, sanguinamento e ferita da curare, ma **non trasmette il virus Knox**. Graffi e lacerazioni restano identici al gioco. Funziona con salvataggi esistenti e non scrive nulla nel save.

**Realizzata da un'IA** (Claude di Anthropic) su richiesta del proprietario del repository. È stata verificata con una simulazione e con il javadoc 42.20.0, ma **non è ancora stata testata in partita**.
