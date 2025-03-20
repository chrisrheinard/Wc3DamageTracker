# Wc3DamageTracker
Damage Tracker System for Warcraft 3 version 1.24a - 1.28c

https://www.hiveworkshop.com/threads/damage-tracker-v1-2-3.358945/

<details>
<summary>Changelogs</summary>
- v1.2.3
  * Merged GetDamageTrackerData trigger into DamageTracker trigger
  * You can now run GetData (Trigger Variable) instead
  * Added functionality to get the Top Contributor when target dies (Overall/Phys/Spell)
  * Added functionality to get the contribution of Top Contributor when target dies (Overall/Phys/Spell)
  * Adjusted the examples

- v1.2.2
  * Fixed minor bug (Total Player Damage tracked incorrect damage)
  * Reset the data after an event has passed
  * You can now get the list of all damage contributors through DTR_Sources (Unit Group)
  * Changed Overall/Phys/SpellDamagePercentage variable names into Overall/Phys/SpellContribution
  * Changed the Contribution variables into arrays and use unit's custom value as the index

- v1.2.1
  * The system now also stores Total Damage Taken of each players

- v1.2
  * Added Registration Mode to configure whether damage source and/or damage target need to be registered
  * Re-added Timed Cleanup
  * Some code adjustments

- v1.1
  * Switched to Hashtable
  * Added GetDamageTrackerData Trigger
  * Removed Timed Cleanup
  * Now requires user to register unit first by using DTR_IsRegistered[Unit Custom Value]
  * System stores Total Damage Taken by a target
  * System stores Total Spell and Physical Damage dealt by players
  * Added more examples

- v1.0
  * First Public Release
</details>

## Map License

The custom scripts and triggers in this project are licensed under the MIT License (see LICENSE).

However, the Warcraft 3 map files (.w3x, .w3m) contain assets that are owned by Blizzard Entertainment.
By using or modifying these files, you agree to comply with Blizzard's End User License Agreement (EULA).

You **may**:
- Modify this map for personal and non-commercial purposes.
- Share modified versions with proper credit.

You **may not**:
- Sell or distribute this map for commercial purposes.
- Claim ownership of Blizzard’s assets included in the map.

This project is not affiliated with or endorsed by Blizzard Entertainment.
