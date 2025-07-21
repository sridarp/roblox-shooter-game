# Roblox Shooter Game

A complete 3D shooter game for Roblox with advanced weapon systems, detailed 3D models, and particle effects.

## Installation Instructions

1. **Open Roblox Studio**
2. **Create a new place**
3. **Set up the folder structure:**
   - ServerScriptService
   - ReplicatedStorage
   - StarterGui

4. **Add the scripts:**
   - Copy `GameManager.lua` to ServerScriptService
   - Copy `MapGenerator.lua` to ServerScriptService
   - Copy `WeaponSystem.lua` to ReplicatedStorage
   - Copy `EffectsSystem.lua` to ReplicatedStorage
   - Copy `GameGUI.lua` to StarterGui

5. **Configure the game:**
   - Adjust spawn points in MapGenerator
   - Modify weapon stats in WeaponSystem
   - Customize GUI elements in GameGUI

## Features

- **Multiple Weapons:** Assault Rifle, Pistol, Sniper, SMG
- **Detailed 3D Models:** Custom weapon models with realistic parts
- **Advanced Combat:** Recoil, accuracy, reload mechanics
- **Interactive Map:** Buildings, cover, spawn points
- **Real-time GUI:** Health, ammo, scoreboard
- **Particle Effects:** Muzzle flash, bullet trails, hit effects
- **Sound System:** Weapon sounds and audio feedback

## Controls

- **Left Click:** Shoot
- **Right Click:** Aim/Zoom
- **R Key:** Reload
- **WASD:** Movement
- **Space:** Jump

## Customization

You can easily customize:
- Weapon damage and stats in `WeaponSystem.lua`
- Map layout in `MapGenerator.lua`
- GUI appearance in `GameGUI.lua`
- Game rules in `GameManager.lua`

## Testing

1. Click "Play" in Roblox Studio
2. Test with multiple players using "Players" dropdown
3. Verify all weapons work correctly
4. Check GUI updates properly
5. Test respawn and scoring systems