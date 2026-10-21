# Away — design

Mode: **Operate**. This is a tool doing a job; the system's own controls carry
the settings, and the break is the one surface allowed to have a point of view.

## The world

Dusk. A dark field, a single line of amber light where the horizon would be, and
one number. Eyes rest in low light; the screen stops being a thing to read.

## Signature move: the horizon drains

The break's timer is not a ring and not a bar. It is a full-width amber hairline
at the horizon, and it recedes to the centre as the break runs out, then goes
out. The number above it is the same idea in type: huge, thin, tabular.

Nothing else in the app uses the horizon. The menu bar is an eye; settings are
stock macOS. One authored moment.

## Palette

| Token | Value | Job |
|---|---|---|
| ink | `#08090B` | break surface |
| paper | `#F2EDE3` | break type |
| amber | `#E7A45C` | horizon, strict notices, control accent |
| muted | paper at 52% | hints only, never body copy |

No gradients in text, no blur, no shadows. The horizon glow is a 120 pt linear
band, not a gaussian.

## Type

SF Pro only; the app owns no typeface and should not.

- Timer: system ultralight, 76–120 pt by screen height, tabular, tracking −0.01em.
- Instruction: 19 pt regular, 72% paper.
- Hint: 12 pt medium, +0.03em, 52% paper. Amber when strict.
- Settings/menu: system sizes, no custom faces.

## Surfaces

- **Menu bar**: 18 pt template eye, custom-drawn, pupil filled. Dimmed when
  paused. Optional `18m` countdown, off by default.
- **Break**: full-bleed ink on every display, the same composition on each.
  Horizontal position is always the centre. Horizon at 64% height.
- **Settings**: native grouped `Form`, 440 × 706, system accent. No hero, no
  marketing copy. Explanations live under the two settings that need them.
