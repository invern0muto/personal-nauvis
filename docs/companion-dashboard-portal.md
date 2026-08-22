# Personal Nauvis Companion Dashboard

Monitor a Personal Nauvis multiplayer server from a fast, responsive second-screen dashboard.

Companion Dashboard exports bounded, read-only telemetry from Factorio and presents it through a separate web interface. It is designed for servers where every player can own a personal Nauvis and permanently choose cooperative or PvP progression.

## What it shows

- Server availability, game tick freshness and connected players
- Personal planets, owners, forces and Co-op/PvP mode
- Offline-protection status for every personal world
- Power networks, accumulators and energy satisfaction
- Production, consumption, machine states and bottlenecks
- Research progress, laboratories and science-pack throughput
- Logistic networks, robots, inventories and shortages
- Trains, stations, resources, pollution and enemy evolution
- Space platforms, orbital requests and platform warnings
- Mod list and telemetry health

## Server administration

The optional private administration page can display hosting resource usage and expose authenticated start, stop and restart controls when supported by the hosting provider. Hosting credentials never need to be sent to Factorio clients and must remain in the dashboard backend.

## Performance

Collection work is distributed across game ticks and controlled by strict entity and chunk budgets. Larger factories take longer to scan instead of causing a large single-tick pause. Expensive collectors can be disabled individually.

## Privacy and security

Public pages are read-only. Server controls, precise coordinates, private inventories and technical logs can be restricted to the authenticated administration area. The mod does not include hosting credentials, passwords or API tokens.

## Compatibility

- Factorio 2.0
- Space Age supported
- Personal Nauvis integration
- Co-op and independent PvP forces
- Dedicated headless servers

The web dashboard is a separate companion application. This mod produces the telemetry consumed by that application.

## Credits and license

Companion Dashboard is derived from Factorio Dashboard Exporter by boehla/CryptoJunky11 and retains the original MIT attribution. New Personal Nauvis and multi-server integration code is also released under the MIT License.

The project is community-made and is not affiliated with or endorsed by Wube Software.
