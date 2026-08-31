# MGRS Coords — Garmin Connect IQ Widget

A Connect IQ **widget** for the **Garmin Forerunner 255** (all variants: 255, 255 Music, 255S, 255S Music) that shows your current position as an **MGRS coordinate** and lets you save waypoints with one button press — right from the system widget/glance menu.

The Forerunner 255 has no native MGRS position format; this widget fills that gap without interfering with anything the watch is already doing.

## Features

- **Glance in the system menu** — press UP/DOWN from the watch face, and the MGRS glance shows your current grid (when an activity with GPS is running) or your most recently saved waypoint. The glance never turns GPS on by itself, so it costs no battery.
- **Live MGRS position** — open the widget and it acquires GPS (or instantly reuses the fix from a running activity) and displays the full MGRS grid (e.g. `32T MK 12345 67890`), plus decimal lat/lon and fix quality.
- **One-press save** — press **START** to save the current position. Waypoints are auto-named `WPT 1`, `WPT 2`, … and stored with MGRS, lat/lon, and timestamp (up to 50, oldest dropped first).
- **Browse and delete** — press **DOWN/UP** to page through saved waypoints (newest first); hold **UP** (MENU) on a waypoint to delete it, with confirmation.
- **Navigation-activity friendly** — the widget only *reads* position. If a Run/Hike/Navigation activity is in progress, the widget seeds itself from that activity's GPS fix, so the grid you see matches the activity exactly, and opening the widget never disturbs the recording.

## Controls (Forerunner 255)

| Button | On live page | On a saved waypoint page |
|---|---|---|
| START (upper right) | Save current position | — |
| UP / DOWN | Page through saved waypoints | Page through saved waypoints |
| Hold UP (MENU) | — | Delete this waypoint |
| BACK (lower right) | Exit widget | Exit widget |

## Using saved grids with navigation

Connect IQ apps can't inject waypoints into the watch's native saved-locations list, so the intended workflow is:

1. Save/read the MGRS grid in this widget.
2. To navigate to it on the watch: START → (activity) → hold UP → Navigation → Coordinates, and enter the lat/lon shown under the MGRS grid (the widget displays both for exactly this reason).
3. Or radio/report the MGRS grid directly — that's usually the point of MGRS.

## Building

### Common setup (all platforms)

1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) via the **SDK Manager** and, inside it, download the SDK plus the **Forerunner 255** device files (Devices tab).
2. Optional but recommended: install [VS Code](https://code.visualstudio.com/) with the **Monkey C** extension — it can generate the developer key, build, and launch the simulator from the command palette (`Ctrl+Shift+P` → "Monkey C: ...") on every platform.

### macOS / Linux

1. Generate a developer key if you don't have one:
   ```sh
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
2. Build for the Forerunner 255 (with the SDK's `bin` directory on your `PATH`):
   ```sh
   monkeyc -f monkey.jungle -d fr255 -o MgrsCoords.prg -y developer_key.der
   ```
3. Test in the simulator: `connectiq`, then `monkeydo MgrsCoords.prg fr255`.

### Windows

1. The SDK Manager installs SDKs under `%APPDATA%\Garmin\ConnectIQ\Sdks\`. The CLI tools are batch files on Windows (`monkeyc.bat`, `connectiq.bat`, `monkeydo.bat`) and are **not on your `PATH` by default** — running `monkeyc.bat` straight away gives "not recognized". Add the SDK's `bin` folder to the current PowerShell session with:
   ```powershell
   $sdk = (Get-ChildItem "$env:APPDATA\Garmin\ConnectIQ\Sdks" -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
   $env:Path += ";$sdk\bin"
   ```
   To make it permanent, add that `...\Sdks\<sdk-folder>\bin` path via Start menu → "Edit environment variables for your account" → `Path`. If `Get-ChildItem` finds nothing, the SDK isn't installed yet — open the SDK Manager and download it first. `monkeyc` also needs Java on the `PATH`; install a JRE/JDK (e.g. Temurin 17) if `java` isn't recognized.
2. Generate a developer key if you don't have one — easiest via VS Code: `Ctrl+Shift+P` → **Monkey C: Generate a Developer Key**. Alternatively, use OpenSSL from **Git Bash** (bundled with Git for Windows):
   ```sh
   openssl genrsa -out developer_key.pem 4096
   openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt
   ```
3. Build for the Forerunner 255 (Command Prompt or PowerShell, from this project's folder):
   ```bat
   monkeyc.bat -f monkey.jungle -d fr255 -o MgrsCoords.prg -y developer_key.der
   ```
4. Test in the simulator: run `connectiq.bat` to start it, then `monkeydo.bat MgrsCoords.prg fr255`.

### Sideloading onto the watch

Plug the watch in via USB (on Windows it shows up as a removable drive; if it doesn't, install [Garmin Express](https://www.garmin.com/express/) once to get the USB drivers) and copy `MgrsCoords.prg` into the watch's `GARMIN/APPS/` folder, then eject and unplug.

After sideloading, the widget appears in the glance loop (UP/DOWN from the watch face). If it doesn't show, add it via hold UP → Appearance → Glances → Add.

## Notes & limitations

- MGRS output uses Garmin's built-in conversion (`Position.toGeoString(GEO_MGRS)`), WGS84, 1 m precision.
- Poleward of UTM coverage (beyond 84°N / 80°S), references are computed on the Universal Polar Stereographic (UPS) grid using the standard MGRS polar scheme — grid zones Y/Z (north) and A/B (south) — and are marked with a `(UPS)` suffix, e.g. `Z AH 00000 00000 (UPS)` at the North Pole. Verified against the NGA GEOTRANS-based `mgrs` reference library.
- Requires Connect IQ API level 3.2.0+ (the Forerunner 255 ships well above this).

## Project layout

```
manifest.xml                 app manifest (widget, FR255 targets, Positioning permission)
monkey.jungle                build file
source/MgrsWidgetApp.mc      app entry point (widget + glance)
source/MgrsGlanceView.mc     glance for the system menu
source/MgrsMainView.mc       live position + saved waypoint pages
source/MgrsMainDelegate.mc   button handling + delete confirmation
source/MgrsStore.mc          persistent waypoint storage
source/MgrsFormat.mc         MGRS/lat-lon/timestamp formatting
resources/                   strings and launcher icon
```
