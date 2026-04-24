# R-Zones

A standalone zone system for FiveM with:

- Safezones, redzones, and drug zones
- Optional map blips (radius + icon)
- Optional 3D zone visualization
- NUI banner when you enter/exit a zone
- Config toggles to enable/disable everything (per-type and per-zone)
- Performance-focused detection (adaptive tick rate)

## Requirements

- None

## Installation

1. Put `R-Zones` into your resources folder.
2. Add to `server.cfg`:

```cfg
ensure R-Zones
```

## Configuration

All settings are in `config.lua`.

### Master enable/disable

- `Config.Enabled`

If `false`, the script is fully disabled:

- No zone detection
- No NUI banner
- No blips
- No spheres

### Zone types (safe/red/drug)

Zone types are defined in:

- `Config.ZoneTypes`

Each type supports:

- `enabled` (true/false)
- `label` (blip name)
- `blipColor`, `blipSprite`, `blipScale`
- `sphereColor` (RGB)
- `nuiType` (used by the NUI banner)
- `disableCombat` (safezone feature)

### Zones list

Zones are defined in:

- `Config.Zones`

Each zone supports:

- `enabled` (true/false)
- `coords` (`vec3`)
- `radius` (meters)

Example:

```lua
Config.Zones = {
  safezone = {
    { enabled = true, coords = vec3(140.96, -3092.31, 5.9), radius = 50.0 },
  },
  redzone = {
    { enabled = true, coords = vec3(687.25, 577.5, 146.67), radius = 80.0 },
  },
  drug = {
    { enabled = true, coords = vec3(1387.0, 3604.0, 38.9), radius = 80.0 },
  }
}
```

## Map blips

Controlled by:

- `Config.Blips.enabled`

If enabled, each zone gets:

- A **radius blip** (matching the zone radius)
- An **icon blip** (type-based sprite + label)

## 3D Spheres (zone visualization)

Controlled by:

- `Config.Spheres.enabled`

Details:

- Spheres are drawn using native `DrawSphere`.
- Sphere **radius always matches the zone radius** (same size as the map radius blip).
- Sphere colors match zone types:
  - Safezone = green
  - Redzone = red
  - Drug zone = purple

Opacity:

- `Config.Spheres.opacity` (0.0 to 1.0)

Visibility distance:

- `Config.Spheres.visibleDistance` (meters)

## Performance

Zone checks use an adaptive tick rate (less CPU usage when you’re far away).

Tune in:

- `Config.Performance`

Recommended:

- Keep `farSleep` fairly high (500-1000ms)
- Keep `nearSleep` moderate (100-250ms)

