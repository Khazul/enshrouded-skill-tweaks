--- Khazul-SkillTweaks mod
--- @Author Khazul
--- @Github https://github.com/Khazul/enshrouded-skill-tweaks
--- @mod Enshrouded Skill Tweaks
--- @description Tweaks to various skills in Enshrouded

local SkillTreePatcher = require("SkillTreePatcher")

-- Skill ids of interest
local skillIdPierce<const> = 3458361475 -- Hash 3834003269
local skillIdVeteran<const> = 3653629718 -- Hash 4043280988
local skillIdTitanEdge<const> = 2489448655 -- Hash 3606836841
local skillIdHeavySpec<const> = 3377542145 -- Hash 38576393
local skillIdHammerTime<const> = 1429546616 -- Hash 45354812
local skillIdBrute<const> = 2751446638 -- Hash 4031743929
local skillIdSwiftBlades<const> = 2508204276 -- Hash 452203209
local skillIdSneakAttack<const> = 606477139 -- Hash 4024783128
local skillIdBackstabDamage<const> = 2004272085 -- Hash 17289158
local skillIdSilentStride<const> = 293824207 -- Hash 3432832248
local skillIdWarriorsPath<const> = 2571965916 -- Hash 817490139

local skillIdTitanEdgeStrength<const> = 3980909207

-- Skill name hashes of interest
local skillStrengthNameHash<const> = 1301436537
local skillConstitutionNameHash<const> = 2141966844

local skillsPatcher = SkillTreePatcher:new()

-- Set costs
skillsPatcher:setSkillCost(skillIdSilentStride, 2) -- 3 seemed excessive
skillsPatcher:setSkillCost(skillIdTitanEdge, 3) -- 4 seemed excessive

-- Remove unwanted links
skillsPatcher:unlinkSkillNodes(skillIdPierce, skillIdTitanEdge)
skillsPatcher:unlinkSkillNodes(skillIdHammerTime, skillIdTitanEdge)
skillsPatcher:unlinkSkillNodes(skillIdTitanEdge, skillIdSwiftBlades)

-- Add in new links
skillsPatcher:linkSkillNodes(skillIdPierce, skillIdVeteran)
skillsPatcher:linkSkillNodes(skillIdHeavySpec, skillIdTitanEdge)

-- Move node UI positions
-- TODO use find linked skill
local titanEdgeStrOffsetPos = skillsPatcher:getNodePositionDiff(skillIdTitanEdge, skillIdTitanEdgeStrength)
local titanEdgePos = {
    x = 1897.231689453125,
    y = 4898.53955078125
}
skillsPatcher:moveNode(skillIdTitanEdge, titanEdgePos)
skillsPatcher:moveNode(skillIdTitanEdgeStrength, skillsPatcher:offsetPos(titanEdgePos, titanEdgeStrOffsetPos))
skillsPatcher:moveNode(skillIdVeteran,
    skillsPatcher:projectNodePosition(skillIdBrute, skillIdHammerTime, 1.25))

-- Swap unique nodes

-- Sneak attack is useless and this will not change cost of merciless
skillsPatcher:swapSkillNodes(skillIdSneakAttack, skillIdBackstabDamage) 

-- Swap stat nodes

-- Swap cons into warrior tree
skillsPatcher:swapSkillNodes(skillsPatcher:findLinkedSkill(skillIdWarriorsPath, skillStrengthNameHash).id.value,
    skillsPatcher:findLinkedSkill(skillIdHeavySpec, skillConstitutionNameHash).id.value)
