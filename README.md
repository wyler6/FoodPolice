# Food Police

> *Yells at raid members who skip their food buff.*

Food Police watches a configurable list of players for the **Well Fed** buff. When a Ready Check fires, every group member who has the addon installed simultaneously yells at anyone on the list who forgot to eat. The chaos is the point — ten people yelling ten different things at one person is a feature, not a bug.

---

## Installation

1. Download `FoodPolice-v1.0.zip`
2. Extract the `FoodPolice/` folder into your AddOns directory:
   ```
   World of Warcraft/_classic_/Interface/AddOns/
   ```
3. Enable Food Police in the AddOns menu on the character select screen
4. The raid leader sets up the watch list (see below)

---

## How It Works

The **raid leader** builds the watch list on their client, then pushes it to the whole group with `/fp push`. Everyone else's addon updates automatically — they don't need to configure anything.

When a **Ready Check** fires, each client independently checks the list. Anyone missing Well Fed gets yelled at immediately, cooldown reset. If multiple people lack food, the addon yells at one per 45-second window to avoid spam.

Only the raid leader's push commands are accepted. If a non-leader tries to push, it's silently ignored.

---

## Commands

| Command | Description |
|---|---|
| `/fp add <name>` | Add a player to your watch list |
| `/fp remove <name>` | Remove a player |
| `/fp list` | Show your current watch list |
| `/fp push` *(leader only)* | Broadcast your list to the whole group |
| `/fp check` | Force-check all targets now, reset cooldown |
| `/fp test` | Preview a random yell without sending |
| `/fp clear` | Clear your local watch list |

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

## Yell Phrases

20 phrases selected randomly per client — so if the whole raid has the addon, everyone yells something different at the same time:

1. EAT YOUR FOOD!
2. THE FEAST IS FREE!
3. NO FOOD, NO PULL.
4. WELL FED. LOOK IT UP.
5. CHECK YOUR BAGS!
6. WE ARE NOT STARTING WITHOUT WELL FED!
7. THE COOK DIED FOR THOSE BUFFS!
8. DO YOU WANT TO WIPE? BECAUSE THIS IS HOW WE WIPE.
9. ONE JOB. ONE.
10. AGAIN?! SERIOUSLY?!
11. I AM BEGGING YOU. EAT SOMETHING.
12. FOOD EXISTS. USE IT.
13. THE RAID BOSS PROBABLY EATS BEFORE A FIGHT.
14. I WILL WAIT. EAT.
15. WOULD IT KILL YOU TO EAT SOMETHING?
16. THIS IS WHY WE WIPE.
17. EAT OR SIT OUT. YOUR CHOICE.
18. THE FEAST IS RIGHT THERE! CLICK IT!
19. HOW IS THIS STILL HAPPENING.
20. BLESS YOUR HEART, NOW EAT YOUR FOOD.

---

## Requirements

- World of Warcraft: Mists of Pandaria Classic
- Interface version 50504 (patch 5.5.4)

---

## Version History

**v1.0**
- Initial release
- Ready Check trigger
- Raid leader push via addon message channel
- 20 random yell phrases
- 45-second cooldown between yells
- Watch list persists across sessions
