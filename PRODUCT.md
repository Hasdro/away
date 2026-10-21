# Away

A small macOS menu-bar app that takes the screen away for eye breaks.

## Why

EyeLeo is Windows-only. The 20-20-20 rule is easy to know and impossible to
remember, and every timer app I have tried is either a Chrome extension or a
subscription. This one is a native menu-bar utility: one eye icon, a real break
that covers every display, and no settings to fiddle with on day one.

## Who

One person: Hasan, at a Mac, coding for most of the day. One machine, one
display or two, no admin.

## What it does

- Short breaks: 20 seconds every 20 minutes.
- Long breaks: 5 minutes every third break (60 minutes of work).
- The break is a dark full-screen surface on every display. It is the only
  thing you can look at until it ends.
- Skipping is one key (Esc), unless strict mode is on and then it isn't.
- If you were already away for a couple of minutes, it doesn't fire — you
  already rested. No stale break when you come back from lunch.
- Pause for 15 / 30 / 60 / 120 minutes from the menu.

## Success

- The break arrives without me watching a clock.
- Taking the break takes zero decisions.
- When it isn't breaking, it is invisible: one menu-bar glyph, no Dock icon.
- It never asks for Accessibility, Screen Recording, notifications, or an
  account. If those dialogs ever appear, the app has failed.

## Non-goals

Streaks, stats, history, cloud sync, accounts, exercise libraries, iPhone,
calendar integration, multiple profiles, themes, i18n, updater, App Store.

## Assumptions (inferred from the brief, not confirmed)

- Native Mac app, English only, macOS 14+, Apple silicon.
- Defaults are the 20-20-20 cadence, editable, and start working immediately on
  launch. No onboarding.
- Local build, ad-hoc signed; no notarization or distribution.
