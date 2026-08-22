# Personal Nauvis — Mod Portal listing

## Title

Personal Nauvis

## Summary

Give every guest a fresh personal Nauvis while the host keeps the established
base. Each arrival permanently chooses shared Co-op or an independent PvP force.

## Suggested categories

- Multiplayer
- Planets
- Utilities

## Full description

# Personal Nauvis

Do you want to invite friends into an advanced multiplayer save without placing
everyone inside the host's established factory? Personal Nauvis gives every
guest a newly generated Nauvis of their own while preserving the original world
and keeping the group together.

The first player keeps the original Nauvis exactly as it is. Each additional
player is assigned a separate Nauvis and receives a mandatory briefing with a
permanent choice between Co-op and PvP.

Only Nauvis is duplicated. Vulcanus, Gleba, Fulgora, Aquilo and other standard
Space Age destinations remain common meeting points for the entire team.

## Designed for existing saves

The main use case is adding friends to a game that is already well underway:

- The earliest player in the save becomes the owner of the original Nauvis.
- The original factory, terrain, entities and resources are left untouched.
- Every guest receives the first available personal-world slot.
- A personal world is generated only when it is actually assigned.
- The force-wide spawn point is never changed.
- After death, each player is returned to their own Nauvis.

The default limit is eight personal worlds and can be configured between two
and sixteen with a startup setting.

## Co-op or PvP

Each guest chooses once when arriving on their personal Nauvis:

- **Co-op** joins the host's `player` force. Research, recipes, buildings,
  logistics and force statistics are shared with all cooperative players.
- **PvP** creates a personal hostile force. The host's currently completed
  technologies are copied once so a late arrival can compete immediately.
  Research, recipes and force statistics then progress independently.

The choice is permanent for that save. A configurable grace period, 30 minutes
by default, creates a mutual cease-fire between a new PvP force and existing
player forces. When it expires, normal hostility begins.

## Space Age support

With Space Age enabled, every personal Nauvis is a real planet location rather
than a generic hidden surface. Space platforms can depart from it and use routes
to the same shared destinations available from the original Nauvis.

The mod does not create personal copies of Vulcanus, Gleba, Fulgora or Aquilo.
This keeps the space map manageable and avoids multiplying every planetary
factory for every player.

## Visiting other players

Players can move between personal worlds with commands:

- `/pn-home` — return to your assigned home world.
- `/pn-visit <player>` — visit another player's Nauvis.
- `/pn-list` — show world assignments, online state and protection state.
- `/pn-send-home <player>` — administrator recovery command for a stranded player.
- `/pn-observe <player>` — invisibly spectate an online player (administrator).
- `/pn-inspect <player>` — inspect a personal world even while its owner is offline (administrator).
- `/pn-observe-exit` — return to the administrator's original character and position.
- `/pn-delete-world <player>` — permanently delete an offline personal world and free its slot (administrator).

Visiting does not change ownership. A player always respawns on their assigned
home world. `/pn-visit` cannot cross hostile force boundaries.

## Offline base protection

Factorio continues simulating every surface while the server is running. This
means a factory could normally be attacked while its owner is away and another
player is online elsewhere.

Personal Nauvis protects absent owners without deleting or resetting anything:

- the owner's surface switches to peaceful mode while they are offline;
- damage to the owner's force buildings, walls, vehicles, trains and robots is
  restored;
- enemies, nests and pollution are not removed;
- production, resource consumption and pollution continue normally;
- protection is removed automatically when the owner reconnects;
- protection state is re-synchronised after a server restart.

Characters are deliberately excluded from damage protection. Offline protection
is intended to preserve an unattended factory, not provide combat invulnerability
to visitors.

## Optional starter kits

After choosing Co-op or PvP, every guest receives a one-time starter choice.
Nothing is placed until the player selects an option:

- **Accelerated Start** — generous early-to-mid-game materials, conventional
  machines, power, construction robots and rail equipment. It does not grant
  endgame armour, assembling machines 3, express logistics, rocket components
  or a rocket silo.
- **Essential kit** — basic machines, power, construction robots and enough
  materials to bootstrap a factory without skipping its development.
- **Spidertron only** — the vehicle and its ammunition, with no extra supplies.

Every choice grants one Spidertron loaded with 100 rockets. The selected
supplies are stored in its trunk near the personal spawn point. The vehicle is
granted only once; if the player loses it, the mod does not replace it. The
original host never receives the starter-kit prompt.

The lists use standard Factorio items. An unavailable optional item is skipped
rather than preventing the world from being created.

## Save-safety principles

The mod is intentionally conservative:

- it never deletes a surface automatically;
- `/pn-delete-world` rejects the original Nauvis and every online owner;
- it never clears enemies or pollution;
- it never clones or overwrites an existing factory;
- it never changes the global force spawn position;
- it does not move the original host away from the established Nauvis;
- it does not duplicate the Space Age planetary system.

As with every mod that adds planet prototypes, make a backup before installing,
updating or removing it from a valuable save.

## Dashboard and companion-mod support

A read-only remote interface named `personal_nauvis` exposes world ownership,
surface names, player forces, Co-op/PvP mode, online status and
offline-protection status. Dashboards can read this information without
changing the save.

Support for the separate **Personal Nauvis Companion Dashboard** is included.
Once released, that optional monitoring mod will add bounded telemetry for
server health, players, personal planets, power, production, research,
logistics, trains, resources and space platforms. Its external web application
can provide a public read-only status page and a separate authenticated
administration page when supported by the server host.

Personal Nauvis does not require the dashboard and does not contain hosting
credentials, passwords or API tokens.

## Recommended companion mod

[Teleporters Space Age 1.2.0](https://mods.factorio.com/mod/Teleporters_SpaceAge)
is recommended for connecting player worlds through normal gameplay. Its
teleporters must be placed in person and can travel between surfaces, allowing
friends to meet without typing console commands.

The companion mod is optional. Personal Nauvis still provides `/pn-home` and
`/pn-visit` as recovery and administration tools.

## Compatibility

- Factorio 2.0 or newer is required.
- Space Age is optional and supported.
- English and Italian localisation are included.
- Other mods that heavily replace Nauvis or rewrite the space-connection graph
  may require compatibility patches.

## Installation

1. Back up the save.
2. Install the mod on the server and all clients, or let Factorio synchronise it
   from the Mod Portal.
3. Start the server with the existing save.
4. The earliest existing player retains the original Nauvis.
5. New guests are assigned personal worlds when they join.
6. Use `/pn-list` to verify assignments.

## Removing the mod

Do not remove a planet-creating mod casually from a save containing active
personal worlds. Return players to the original Nauvis, create a backup and test
removal on a copy first. Personal Nauvis deliberately provides no automatic
surface deletion command.

## Beta notice

This is an early multiplayer release. Prototype loading, Lua validation and
save creation have been verified with Factorio 2.0.77 and Space Age. A live
multi-client test is recommended before using it on a valuable production save.

Bug reports should include the Factorio version, enabled mod list, relevant log
section and the exact action that triggered the issue.

## License and source

Personal Nauvis is released under the MIT License.

Source and issue tracker:
https://github.com/invern0muto/factorio

## Recommended first-release status

Beta.
