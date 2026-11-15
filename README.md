# FiveM HUD Resource

FivemHUD is a customizable FiveM resource and NUI HUD for GTA V servers. It displays player status bars, voice activity, location information, compass direction, and vehicle data with support for standalone, ESX, and QBCore servers.

## Install

1. Copy the resource folder into your FiveM server's resources directory.
2. Add the resource to `server.cfg`:

   ```text
   ensure custom_hud
   ```

3. Start or restart your FiveM server.
4. Confirm that the resource folder contains:

   ```text
   fxmanifest.lua
   client.lua
   web/index.html
   web/style.css
   web/app.js
   ```

5. Open `client.lua` and adjust the `Config` table if needed:

   ```lua
   Position = 'right'
   ShowStreet = true
   ShowCompass = true
   ShowVehicle = true
   UpdateInterval = 250
   Unit = 'mph'
   Framework = 'auto'
   ```

   `Position` accepts `left` or `right`. `Unit` accepts `mph` or `kmh`. `Framework` accepts `auto`, `esx`, `qb`, or `standalone`.

## Use

- Press or run `/hud` to toggle the HUD.
- The HUD automatically updates health, armor, hunger, thirst, stamina, stress, and voice information.
- Street names, crossing streets, and compass directions are shown when enabled.
- The vehicle panel appears while the player is inside a vehicle when `ShowVehicle` is enabled.
- Vehicle information includes speed, speed unit, gear, fuel, engine state, and seatbelt state.
- Use the following client events to update custom status values from another resource:

  ```lua
  TriggerEvent('custom_hud:setStatus', {
      hunger = 75,
      thirst = 60,
      stress = 10
  })
  ```

  ```lua
  TriggerEvent('custom_hud:setNeeds', 75, 60)
  TriggerEvent('custom_hud:setStress', 10)
  TriggerEvent('custom_hud:setVoice', 2)
  TriggerEvent('custom_hud:setVisible', true)
  ```

- ESX servers can provide hunger and thirst through `esx_status`.
- QBCore servers can provide hunger, thirst, and stress through player metadata.
- The HUD detects ESX and QBCore automatically when `Framework = 'auto'`.

---

More FiveM resource projects by EnderDevelopment: https://github.com/EnderDevelopment

Project page: https://dash.enderdevelopment.com/community/294884ed-c292-4db8-bd94-4b8dfcd6b77a?utm_source=github&utm_medium=readme&utm_campaign=auto_publish&utm_content=294884ed-c292-4db8-bd94-4b8dfcd6b77a
