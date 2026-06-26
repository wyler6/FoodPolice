## [1.8]
- Added Noodle Cart awareness: raid leader/assist auto-sends a raid warning when any player drops a Noodle Cart
- 40 new "runny" noodle-themed raid warning phrases
- Noodle Cart Alerts toggle added to the config window (/fp config)

## [1.7]
- Added configuration window (/fp config) with scrollable watch list and Remove buttons
- Added Target button to add your current target directly from the UI
- Added About panel with basic usage instructions
- Added 20 new yell phrases (40 total)

## [1.6]
- Added version check: addon announces its version to the group on login
- Added /fp who command to see which group members have FoodPolice installed and their version
- Notifies you locally if a group member is running a newer version than you

## [1.5]
- Fixed over-triggering: addon now only fires on Ready Check (removed UNIT_AURA and GROUP_ROSTER_UPDATE triggers)

## [1.4]
- Fixed transparent icon background (eyes were removed in v1.3)
- Release version now derived from git tag instead of .toc file

## [1.3]
- Added addon icon for the addon list
- Icon background is transparent

## [1.2]
- Fixed false yell firing when leaving the raid group

## [1.1]
- Fixed compatibility with the MoP Classic modern client (RegisterAddonMessagePrefix, SendAddonMessage)
- Switched from YELL to RAID/PARTY chat (YELL is restricted in modern client)
- Fixed active chat channel being reset after FoodPolice sends a message

## [1.0]
- Initial release
- Monitors watch list for Well Fed buff on Ready Check
- Raid leader can sync watch list to group with /fp push
- 45-second cooldown between messages
- 20 random phrases
