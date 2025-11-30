# Khazul-SkillTweaks
**Skill Tweaking mod for Enshrouded by Khazul**

This is a starting point library and mod for tweaking the existing skill tree by moving nodes around, delinking and relinking and in-place swapping etc.

This mod make the following changes:
- Reoganised the Warrior tree to make Veteran easier to get it
- Moved Titan Edge out to the Barbarian tree and made it a point cheaper along with its connected Strength node
- Sneak Attack and Backstab Damage are reversed in position
- Made Silient Stride 1 point cheaper
- Swapped the strength node connected beyond Warrior Path with the constitution node before Heavy Spec

The code is split into mod.lua which contain this mod and SkillTreePatcher.lua which is the begining of an lua skill tree patcher class for manipulating the skill tree.

The .scripts folder contains package and deploy scripts that are mod name and install location agnostic and package to zip (via 7zip), deploy and start enshrouded from a vs code task and so may be useful to other enshrouded mods.

This needs the **Enshrouded Mod Loader** to function: 
- Documentation - https://github.com/Brabb3l/kfc-parser/blob/dev/docs/src/eml/index.md
- Preview Releases - https://github.com/Brabb3l/kfc-parser/actions/workflows/build_release.yml

