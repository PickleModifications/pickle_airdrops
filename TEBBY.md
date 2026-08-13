# TEBBY.md - pickle_airdrops

## Overview

`pickle_airdrops` is a FiveM (GTA V multiplayer) resource developed by Pickle Mods that adds a configurable airdrop system to a server. A plane flies overhead and drops one or more crates (or vehicles) at a chosen location. Players must wait for an unlock timer, then open a crate's NUI interface and hold items to capture them. Drops can be triggered by a server command, by players using inventory items, or on a cron schedule. Both ESX and QBCore frameworks are supported through a bridge layer.

---

## Code design

### Architecture

The resource follows the same architecture pattern as other Pickle Mods resources:

- **`config.lua`** (shared) – all configurable game settings, airdrop templates, random drop zones, blips.
- **`config_sv.lua`** (server-only, not escrowed) – Discord webhooks, the `AddOwnedVehicle` function, and other server-side overrides.
- **`core/shared.lua`** – utility/helper functions available to both sides (math helpers, `debugPrint`, `_L` wrapper, `NumberWithCommas`, etc.).
- **`core/client.lua`** – client-side engine abstractions: entity creation helpers (`CreateVeh`, `CreateNPC`, `CreateProp`), the interaction/targeting system loop, and blip creation.
- **`core/server.lua`** – server-side helpers: player identifier utilities (`GetPlayerIdentifiersArray`, `GetPlayerPrefixIdentifier`).
- **`modules/main/shared.lua`** – declares the shared `Airdrops = {}` table.
- **`modules/main/client.lua`** – all client airdrop logic: plane/crate animation, container HUD, NUI interaction, network event handlers.
- **`modules/main/server.lua`** – airdrop initialization, item generation from templates, all server net events, cron scheduling, the `/airdrop` command, and server exports.
- **`locales/`** – `locale.lua` defines the `_L()` helper; `translations/en.lua` holds all strings.
- **`bridge/`** – framework adapters (ESX / QBCore / custom), target-system adapters (ox_target / qb-target / qtarget), and an optional XP bridge.
- **`nui/`** – compiled/shipped NUI (HTML + bundled JS/CSS). Source lives in `web/`.
- **`web/`** – React + TypeScript + Vite + Tailwind source for the NUI. **Never build in the sandbox**; the compiled output in `nui/assets/` is what ships.

### Main flows

1. **Airdrop triggered** (command / item use / cron) → `StartAirdropTemplate()` on server selects items from a weighted pool → `InitializeAirdrop()` creates the `Airdrops[id]` record → `TriggerClientEvent("pickle_airdrops:startAirdrop", -1, id, data)` broadcasts to all clients.
2. **Client animates** the plane (`jet` vehicle) flying over, drops the container prop, descends it with a parachute, lands it, then fires `pickle_airdrops:startContainerTimer` back to server.
3. **Server starts unlock timer** – stored as `timerStarted = os.time()`. Timer countdown happens client-side (decrementing `unlockTime` once per second).
4. **Player interacts** with the landed crate → `AirdropInteraction()` opens the NUI, sends `setContainerInfo`. Player holds an item slot (mouse down) → NUI calls `updateAirdropContainerItemStatus` (status = "capturing") → server records the looting player + timestamp.
5. **Player releases after full captureTime** → NUI calls `takeAirdropContainerItem` → server validates the looting record to prevent cheating, then calls `Inventory.AddItem` / `AddMoney` / `Inventory.AddWeapon`.
6. **All items taken** → container removed via `removeAirdropContainer`; all containers gone → `removeAirdrop` cleans up globally.

### Conventions

- All inter-side communication uses `TriggerClientEvent` / `TriggerServerEvent` / `RegisterNetEvent` with the prefix `pickle_airdrops:`.
- `_L("key")` is used everywhere for locale strings; missing keys return `"ERR_TRANSLATE_<key>_404"`.
- The `Inventory` table is set up in the framework bridge's server file via a `CreateThread(function() Wait(100) ... end)` pattern that checks for existing `InitializeInventory` first.
- `Config.Debug = true` enables `debugPrint` output on both client and server.
- The codebase uses Lua 5.4 (`lua54 'yes'`).

---

## Important files

| Path | Purpose |
|------|---------|
| `fxmanifest.lua` | FiveM resource manifest; defines load order for shared/client/server scripts, NUI page, and escrow ignore list. |
| `config.lua` | All configurable settings: airdrop templates (`Config.AirdropTemplates`), random drop zones (`Config.RandomDropZones`), the `/airdrop` command name, blip settings, currency, framework settings. |
| `config_sv.lua` | Server-only settings: Discord webhook (`onAirdropLooted`), and `ConfigSV.AddOwnedVehicle()` which inserts vehicle drops into the database (has both ESX and QBCore implementations). |
| `core/shared.lua` | Shared utility functions: `lerp`, `GetRandomInt`, `debugPrint`, `NumberWithCommas`, `GetCurrencyString`, `GetItemLabel`. |
| `core/client.lua` | Entity helpers, the interaction/target loop, `ShowInteractText`, `CreateInteraction`/`DeleteInteraction`, `CreateBlip`. |
| `core/server.lua` | Server-side identifier utilities; not framework-specific. |
| `modules/main/server.lua` | Core server logic: `InitializeAirdrop`, `StartAirdropTemplate`, `GenerateRange`, all `RegisterNetEvent` handlers, cron scheduling, the `/airdrop` command, `RegisterUsableItem` loop. Also exports `InitializeAirdrop` and `StartAirdropTemplate`. |
| `modules/main/client.lua` | Core client logic: `CreateLocalAirdrop` (full plane + crate animation), `AirdropInteraction`, `ExitAirdropContainer`, all `RegisterNetEvent` handlers, NUI callbacks. |
| `locales/locale.lua` | Defines `_L()` and `toupper()`. |
| `locales/translations/en.lua` | All English strings. |
| `bridge/esx/server.lua` | ESX server bridge: money, inventory, identifier, `AddOwnedVehicle`, `IsPlayerAdmin`, etc. |
| `bridge/esx/client.lua` | ESX client bridge: notifications, server callbacks, `CanAccessGroup`, inventory fallback. |
| `bridge/qb/server.lua` | QBCore server bridge: same interface as ESX bridge. |
| `bridge/qb/client.lua` | QBCore client bridge. |
| `bridge/custom/client.lua` | Stub for unsupported frameworks (client side). |
| `bridge/custom/server.lua` | Stub for unsupported frameworks (server side). |
| `bridge/target/ox_target/client.lua` | ox_target bridge: `AddTargetZone`, `AddTargetModel`, `AddTargetGlobalVehicle`, etc. |
| `bridge/xp/client.lua` | Optional XP integration (Pickle XP or custom). |
| `nui/index.html` | Shipped NUI entry point (compiled). |
| `nui/assets/` | Compiled JS and CSS for the NUI. |
| `web/src/App.tsx` | React app root; currency/item helpers, `AppControls`. |
| `web/src/components/AirdropContainer/AirdropContainer.tsx` | Main NUI component: HUD widget (world-space overlay), container loot grid, capture progress. |
| `web/src/providers/nui/` | `fetchNui.ts` (calls back to Lua), `useNui.ts` (listens for `SendNUIMessage`). |
| `__INSTALL/Items/` | Ready-made item definition snippets for ox_inventory, ESX, and QBCore. |

---

## Intended behaviors

### Anti-cheat item validation in server.lua

In `modules/main/server.lua`, the `pickle_airdrops:takeAirdropContainerItem` handler has an intentional anti-cheat check before granting loot:

```lua
if not lootingPlayer or lootingPlayer.slot ~= slot or currentTime - lootingPlayer.statusTime < (item.captureTime - 2) then
    ShowNotification(source, "nice try bud, get banned")
    return
end
```

The message `"nice try bud, get banned"` is **intentional**. It is NOT a placeholder or debugging artifact — it is the anti-cheat rejection message for players who attempt to take items without holding the mouse for the required capture time. The `(captureTime - 2)` is a deliberate grace window of 2 seconds to absorb network latency. Do not change this validation logic unless the exploit model changes.

### Vehicle drop "NONE" item sentinel

In `Config.AirdropTemplates`, setting `item = "NONE"` for a template means it cannot be spawned via player inventory — it is admin/cron-only. This is intentional, not an error. `RegisterUsableItem` is called with `"NONE"` which results in a harmless no-op registration.

### Plane invisible tennis ball trick

`CreateLocalAirdrop` creates an invisible `prop_tennis_ball` entity as the "planeObject" origin — it is moved each tick to drive the jet's position via `AttachEntityToEntity`. This is deliberate: the tennis ball is the cheap moveable anchor for the entity-to-entity attachment. The ball has zero alpha and no collision (`SetEntityAlpha(ball, 0, false)`, `SetEntityCollision(ball, false, false)`). See `CreateTennisBall` in `core/client.lua`.

### ESX server bridge has a duplicate `AddOwnedVehicle` function

`bridge/esx/server.lua` defines `AddOwnedVehicle` twice. The second definition (at the bottom) is the live one used at runtime and overwrites the first. The first definition is legacy dead code. This is not a bug that needs fixing — the second is the authoritative version.

### `config_sv.lua` webhook guard

`ConfigSV.WebhookHandler` checks `if webhook.url == "DISCORD_WEBHOOK_URL" then return end`. This intentionally silences webhook calls when the URL is unconfigured. It is not a bug — it is the deliberate placeholder guard.

### Escrow

The NUI assets (`nui/assets/`) and certain other files are protected by Tebby Code / FiveM escrow. The files listed under `escrow_ignore` in `fxmanifest.lua` are the only ones that are openly editable. Do not treat the absence of source for the NUI bundle as a bug.

---

## Common issues & fixes

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Locale strings show as `ERR_TRANSLATE_<key>_404` | `Config.Language` does not match a key in `Language["..."]`, or the resource folder name differs from `pickle_airdrops`. | Verify `Config.Language = "en"` and that the folder is named `pickle_airdrops` exactly. |
| Airdrop items not given to player (no error) | `Inventory` table not initialized (no supported framework/inventory detected). | Check that ESX or QBCore is started before the resource; check bridge console output for inventory errors. |
| Vehicle drops don't register ownership | `ConfigSV.AddOwnedVehicle` in `config_sv.lua` uses a different DB schema from the server. | Edit `ConfigSV.AddOwnedVehicle` in `config_sv.lua` to match the server's `owned_vehicles` / `player_vehicles` table columns. |
| `/airdrop` command returns "You do not have permission" | Player lacks the `airdrop.command` ACE. | Grant `airdrop.command` via `server.cfg` or framework permissions. |
| Crates appear at wrong Z level (underground / floating) | `GetGroundZExcludingObjectsFor_3dCoord` returns `false` for unloaded areas on specific clients. | The code falls back to `container.location.coords.z`; this is expected in low-render-distance edge cases. The `pendingPlacement` loop re-attempts ground detection when the player is near. |
| NUI shows blank / items not loading | `Inventory.Ready` is false when `pageLoaded` NUI callback fires. | The NUI waits `while not Inventory or not Inventory.Ready do Wait(100) end` — this resolves itself once the bridge initializes. If it never resolves, the inventory bridge failed silently. Check server console. |
| `airdrop_incoming_announce` locale key missing | New template added to config but locale not updated. | Add the key to `locales/translations/en.lua` (or the active locale file). |
| QBCore dirty money not given | `AddMoney` in `bridge/qb/server.lua` calls `Inventory.AddItem` for dirty money — if `Inventory` isn't ready, it silently fails. | Ensure QBCore bridge fully initializes before items are taken; the `Wait(100)` at the top of the bridge CreateThread is usually sufficient. |
| `airdrop_container_blip` locale key not in `en.lua` | The blip label is retrieved with `_L(blipType)` but `"airdrop_container_blip"` is not in the translation table. | Add `airdrop_container_blip = "Airdrop Container"` to `locales/translations/en.lua` (or the active locale). |

---

## Conventions

- **Naming**: Lua globals use `PascalCase` for tables/modules (`Config`, `Airdrops`, `Inventory`). Functions use `PascalCase` (`InitializeAirdrop`, `StartAirdropTemplate`). Local variables use `camelCase` (`localAirdrop`, `airdropContainer`).
- **Net events**: All network events use the prefix `pickle_airdrops:` (e.g. `pickle_airdrops:startAirdrop`). Follow this pattern for any new events.
- **Locale**: All player-visible strings must go through `_L("key")` on the Lua side and `<Translate id="key" />` / `Translate` on the React side. Hard-coding strings is reserved for dev/debug messages only.
- **Bridge pattern**: Framework-specific code lives exclusively in `bridge/<framework>/`. Core modules call generic functions (`ShowNotification`, `AddMoney`, `Inventory.AddItem`) and must not reference `ESX` or `QBCore` directly.
- **Config guard**: Server-side overrideable logic (like vehicle ownership insertion) belongs in `config_sv.lua`, not in bridge files, so server owners can customize it without touching escrowed code.
- **Debug logging**: Use `debugPrint(...)` (not `print`) for conditional debug output so it respects `Config.Debug`.
- **React / NUI**: The NUI source is under `web/`. **Never compile the NUI in the sandbox.** The committed build output in `nui/assets/` is what FiveM loads. Any UI changes require a CI build step.
- **Lua version**: The resource uses Lua 5.4. Integer math operators (`//`) and new Lua 5.4 features are valid.
- **File load order**: `fxmanifest.lua` loads shared scripts before client/server scripts; `modules/**/shared.lua` before `modules/**/client.lua` / `modules/**/server.lua`. Any new module must follow this `shared → client/server` ordering within its folder.
