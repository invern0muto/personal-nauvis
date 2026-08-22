# Personal Nauvis

Bring friends into an established factory without making them share the same
starting area or forcing the host to abandon an existing base.

The first player keeps the original Nauvis and every guest receives a fresh,
independently generated Nauvis. On arrival, each guest permanently chooses to
join the host in Co-op or create an independent hostile PvP force.

## Features

- Designed to be added to an existing multiplayer save.
- One original host world plus up to 16 personal Nauvis worlds.
- Permanent per-player Co-op or PvP choice with a clear first-arrival briefing.
- Co-op shares the host force; PvP copies current technology once and then separates progression.
- Personal respawn destinations without changing the force-wide spawn point.
- Space Age routes from every personal Nauvis to the normal shared planets.
- Optional one-time Essential, Advanced or Spidertron Only starter choice.
- Offline protection without deleting enemies, pollution, entities or surfaces.
- Read-only remote interface for dashboards and companion mods.
- English and Italian localisation.

## Offline protection

When a world's owner is offline, that surface becomes peaceful and damage to
the owner's force buildings, vehicles, trains and robots is restored. Factory
production, resource consumption and pollution continue normally. Protection
is removed automatically when the owner reconnects.

## Starter choice

After choosing Co-op or PvP, each guest selects a starter option. Every option grants exactly one
starter Spidertron loaded with 100 rockets; if it is destroyed, it is not
replaced automatically.

- **Advanced kit** — personal equipment, construction and logistic robots,
  machines, power, rail equipment, a rocket silo and startup materials.
- **Essential kit** — enough machines and materials to bootstrap a factory.
- **Spidertron only** — the vehicle and its 100 rockets, with no extra supplies.

The selected supplies are stored inside the Spidertron trunk near the personal
spawn point. The original host never receives a starter prompt.

## Recommended companion mod

[Teleporters Space Age 1.2.0](https://mods.factorio.com/mod/Teleporters_SpaceAge)
is recommended for physical, player-built travel between personal surfaces.
Players must place teleporters in person, so worlds can be connected through
gameplay without relying on console commands.

## Commands

- `/pn-home` — return to your own Nauvis.
- `/pn-visit <player>` — visit another player's Nauvis.
- `/pn-list` — list assignments, online state and offline protection.
- `/pn-send-home <player>` — administrator recovery command.

`/pn-visit` cannot be used to enter the world of a hostile force.

## Configuration

`Maximum personal Nauvis planets` is a startup setting with a range of 2–16 and
a default of 8. Prototype counts are fixed while Factorio loads, so changing it
requires a restart.

`PvP grace period` defaults to 30 minutes. During that time a new PvP force and
the existing player forces have a mutual cease-fire.

## Save safety

The mod never deletes surfaces, enemies, pollution or player entities. It does
not change the global force spawn point. Back up an important save before adding
or removing any world-generation mod.

This is an early multiplayer release. Test it on a copy of a valuable save
before using it in production.
