# Personal Nauvis

Public source repository for the Personal Nauvis Factorio 2.0 mod and its planned Companion Dashboard integration.

## Projects

- [`mods/personal-nauvis`](mods/personal-nauvis) — personal Nauvis worlds for guests joining an established multiplayer save, with a permanent Co-op/PvP choice, starter Spidertron and offline base protection.
- `mods/companion-dashboard` — planned optional telemetry exporter for the public and administrative web dashboard.

## Documentation

- [Personal Nauvis Mod Portal copy](docs/personal-nauvis-portal.md)
- [Companion Dashboard Mod Portal copy](docs/companion-dashboard-portal.md)
- [Companion Dashboard gallery concepts](docs/companion-dashboard-gallery)

## Building

Run `build-personal-nauvis.ps1` from PowerShell. Release archives are written to `dist/` and are intentionally excluded from Git.

## Security

This repository must not contain server passwords, Factorio tokens, Pine Hosting credentials, Vercel environment variables or private server configuration.

## License

Personal Nauvis is released under the [MIT License](mods/personal-nauvis/LICENSE).

The future Companion Dashboard will retain attribution and licensing notices required by Factorio Dashboard Exporter.
