# Food Police

> *Yells at raid members who skip their food buff — and announces Noodle Carts so nobody has an excuse.*

Food Police watches a configurable list of players for the **Well Fed** buff. When a Ready Check fires, every group member who has the addon installed simultaneously yells at anyone on the list who forgot to eat. The chaos is the point — twenty-five people yelling twenty-five different things at the same person is a feature, not a bug.

---

## Installation

1. Download the latest `FoodPolice-vX.X.zip` from [CurseForge](https://www.curseforge.com/wow/addons/foodpolice)
2. Extract the `FoodPolice/` folder into your AddOns directory:
   ```
   World of Warcraft/_classic_/Interface/AddOns/
   ```
3. Enable Food Police in the AddOns menu on the character select screen
4. The raid leader sets up the watch list (see below)

---

## How It Works

### Food Buff Enforcement

The **raid leader** builds the watch list, then pushes it to the whole group with `/fp push`. Everyone else's addon updates automatically — they don't need to configure anything.

When a **Ready Check** fires, each client independently checks the list. Anyone missing Well Fed gets yelled at, with a 45-second cooldown between yells to prevent spam.

Only the raid leader's push commands are accepted by other clients.

### Noodle Cart Alerts

When any player deploys a Noodle Cart, the raid leader or an assist automatically sends a **Raid Warning** announcing it — one of 40 custom phrases. This feature can be toggled on or off in `/fp config`.

---

## Commands

| Command | Who | Description |
|---|---|---|
| `/fp config` | anyone | Open the configuration window |
| `/fp add <name>` | anyone | Add a player to your watch list |
| `/fp remove <name>` | anyone | Remove a player |
| `/fp list` | anyone | Show your current watch list |
| `/fp push` | leader only | Broadcast your list to the whole group |
| `/fp check` | anyone | Force-check all targets now, reset cooldown |
| `/fp test` | anyone | Preview a random yell without sending |
| `/fp clear` | anyone | Clear your local watch list |
| `/fp who` | anyone | Show which group members have Food Police installed |

**Raid leader workflow:**
```
/fp add Playername
/fp add Anothername
/fp push
```

To update the list mid-raid:
```
/fp remove Playername
/fp add Replacement
/fp push
```

---

## Phrases

**Food buff yells** — 40 phrases, one chosen randomly per client on each trigger. With the whole raid running the addon, everyone yells something different simultaneously.

**Noodle Cart raid warnings** — 40 phrases, one chosen randomly when a cart is dropped. Sent as a Raid Warning by the leader or assist.

---

## Requirements

- World of Warcraft: Mists of Pandaria Classic
- Interface version 50504 (patch 5.5.4)

---

## Version History

**v1.8**
- Noodle Cart awareness: leader/assist auto-sends a Raid Warning when any player drops a Noodle Cart
- 40 noodle-themed Raid Warning phrases
- Noodle Cart Alerts toggle in the config window

**v1.7**
- Configuration window (`/fp config`) with scrollable watch list and Remove buttons
- Target button to add your current target directly from the UI
- About panel with usage instructions
- 20 new yell phrases (40 total)

**v1.6**
- Version check: addon announces its version to the group on login
- `/fp who` shows which group members have Food Police and their version
- Notifies you if a group member is running a newer version

**v1.5**
- Ready Check is the only trigger (removed unreliable aura/roster polling)

**v1.4**
- CurseForge release; version derived from git tag

**v1.3**
- Added addon icon

**v1.2**
- Fixed false yell when leaving the raid group

**v1.1**
- Fixed compatibility with the MoP Classic modern client
- Switched from YELL to RAID/PARTY chat (YELL is restricted on the modern client)

**v1.0**
- Initial release
- Ready Check trigger, raid leader push, 20 random yell phrases, 45-second cooldown
