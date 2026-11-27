# ApexCombat AI

Client-side Minecraft **1.21.11** Fabric combat assistant built on **Java 21**, **Fabric Loader 0.18.1**, **Fabric API 0.141.1+1.21.11**, **Fabric Loom 1.14.10**, **Yarn 1.21.11+build.5**, and **Gradle 9.2.1**.

## Fair Play & Server Rules
- Automated combat actions may violate server rules on public or competitive multiplayer servers.
- Use only in single-player worlds, private test servers, or environments where automation is explicitly permitted.
- This assistant does not claim undetectability or universal server compatibility, and does not implement reach hacks, damage modifications, or packet spoofing.

## Requirements & Installation
1. Install **Minecraft 1.21.11** with **Fabric Loader 0.18.1+** and **Fabric API 0.141.1+1.21.11** on **Java 21**.
2. Place `READY-MOD/ApexCombat-AI-1.21.11.jar` into your Fabric instance's `mods/` folder.
3. Launch Minecraft—ApexCombat AI starts **OFF** by default.

## Controls & Targeting
- **Toggle Master State:** `K` (configurable in Minecraft *Controls*).
- **Emergency Stop:** `Right Shift` (immediately disables automation).
- **Retaliation-Only Targeting:** By default, only valid aggressors who damage the player are queued; teammates, spectators, invalid/disconnected entities, and configured exclusions are ignored, with optional target rotation across queued aggressors.

## Combat Profiles & Configuration
Supports modular profiles for Netherite Pot, Mace, Elytra Mace, Crystal, Anchor, UHC, Mole/Team/Survival, Axe, Shield/Tank, Spear, Sword, and SMP/General PvP, plus configurable thresholds, cooldowns, ranges, and feature toggles stored in `config/apexcombat-ai.properties`.

## Building & Troubleshooting
- **Windows:** Double-click `MAKE MOD.bat` (or run `make-mod.ps1` / `build.bat`). It checks for JDK 21 and Gradle 9.2.1 (downloading portable copies if absent), runs a clean build, inspects the JAR, and outputs `READY-MOD/ApexCombat-AI-1.21.11.jar`.
- **Linux / macOS / CI:** Run `./build.sh` or push to GitHub Actions (`.github/workflows/build.yml`), which uploads `ApexCombat-AI-Verified-Mod` containing `READY-MOD/ApexCombat-AI-1.21.11.jar`.
- **Troubleshooting:** If Gradle or Loom fails due to offline cache or mapping mismatches, verify Java 21 (`java -version`) and network access to `maven.fabricmc.net` and `mavenCentral`.
