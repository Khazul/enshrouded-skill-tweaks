
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

-- For creating new link ids
-- assume not incremented enough to ever collide with existing hash based link ids
local nextNewId = 1

function table.shallow_copy(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function table.count(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

-- return difference vector between 2 points scaled
local function diffPosScaled(p1, p2, s)
    return {
        x = (p2.x - p1.x) * s,
        y = (p2.y - p1.y) * s
    }
end

-- add vector to point
local function offsetPos(p, s)
    return {
        x = p.x + s.x,
        y = p.y + s.y
    }
end

-- return vector between p2 and p1
local function diffPos(p1, p2)
    return {
        x = p2.x - p1.x,
        y = p2.y - p1.y
    }
end

-- Just to make this easier to see what went wrong when bad id
local function getNodebyId(skillTree, nodeIndexes, id)
    local index = nodeIndexes[id]
    return skillTree.nodes[index]
end

-- Move UI positionn of node by id
local function moveNode(skillTree, nodeIndexes, id, p)
    local node = getNodebyId(skillTree, nodeIndexes, id)
    node.uiPosition = {
        x = p.x,
        y = p.y
    }
end

-- Get UI positionn of node by id
local function getNodePositionDiff(skillTree, nodeIndexes, id1, id2)
    local node1 = getNodebyId(skillTree, nodeIndexes, id1)
    local node2 = getNodebyId(skillTree, nodeIndexes, id2)
    return diffPos(node1.uiPosition, node2.uiPosition)
end

-- Project a position that is inline with two other node and at a multiple of the distance between them.
-- the position will be beyond that of id2, such that the line is id1, id2, new_position
local function projectNodePosition(skillTree, nodeIndexes, id1, id2, m)
    local node1 = getNodebyId(skillTree, nodeIndexes, id1)
    local node2 = getNodebyId(skillTree, nodeIndexes, id2)
    local offset = diffPosScaled(node1.uiPosition, node2.uiPosition, m)
    return {
        x = node2.uiPosition.x + offset.x,
        y = node2.uiPosition.y + offset.y
    }
end

local function findSkillLinkById(skillTree, id)
    for i, link in ipairs(skillTree.links) do
        if link.id.value == id then
            return {
                index = i,
                link = link
            }
        end
    end
    -- Assume that this results from fatally bad code - so fault it
    error(string.format("error - Skill link %s not found", tostring(id)))
end

local function findSkillLinkBySourceTarget(skillTree, fromId, toId)

    for i, link in pairs(skillTree.links) do
        if link.sourceNode.value == fromId and link.targetNode.value == toId then
            return {
                index = i,
                link = link
            }
        end
    end
    -- Assume that this results from fatally bad code - so fault it
    error(string.format("error - Skill link [ %s <-> %s ] not found", tostring(fromId), tostring(toId)))
end

-- Find a skill in either the incoming or outgoing link tables by the name hash of a skill
-- Return a skill node
local function findLinkedSkill(skillTree, nodeIndexes, id, nameHash)

    local skillNode = getNodebyId(skillTree, nodeIndexes, id)

    for _, hash in pairs(skillNode.outgoingLinks) do
        local link = findSkillLinkById(skillTree, hash.value).link
        local node = getNodebyId(skillTree, nodeIndexes, link.targetNode.value)
        if node.name.value == nameHash then
            return node
        end
    end

    for _, hash in pairs(skillNode.incomingLinks) do
        local link = findSkillLinkById(skillTree, hash.value).link
        local node = getNodebyId(skillTree, nodeIndexes, link.sourceNode.value)
        if node.name.value == nameHash then
            return node
        end
    end

    error(string.format("error - findLinkedSkill: no skill with name hash %s found connected to skill %s", nameHash, id))
end

local function setSkillCost(skillTree, nodeIndexes, id, cost)
    local node = getNodebyId(skillTree, nodeIndexes, id)
    node.costs = cost
end

local function linkSkillNodes(skillTree, nodeIndexes, fromId, toId)
    local fromNode = getNodebyId(skillTree, nodeIndexes, fromId)
    local toNode = getNodebyId(skillTree, nodeIndexes, toId)
    table.insert(skillTree.links, {
        id = {
            value = nextNewId
        },
        sourceNode = {
            value = fromId
        },
        targetNode = {
            value = toId
        },
        isBidirectional = false
    })
    table.insert(fromNode.outgoingLinks, {
        value = nextNewId
    })
    table.insert(toNode.incomingLinks, {
        value = nextNewId
    })

    print(string.format("Add link [ %s <-> %s ] as id %s", fromId, toId, nextNewId))

    nextNewId = nextNewId + 1
end

local function unlinkSkillNodes(skillTree, nodeIndexes, fromId, toId)
    -- find an existing link definition
    local linkInfo = findSkillLinkBySourceTarget(skillTree, fromId, toId)
    local linkId = linkInfo.link.id.value
    print(string.format("Remove link %s [ %s <-> %s ]", linkId, fromId, toId))

    -- remove the outgoing link
    local fromNode = getNodebyId(skillTree, nodeIndexes, fromId)
    for j, hash in ipairs(fromNode.outgoingLinks) do
        if hash.value == linkid then
            table.remove(fromNode.outgoingLinks, j)
            break
        end
    end
    -- remove the incomming link
    local toNode = getNodebyId(skillTree, nodeIndexes, toId)
    for k, hash in ipairs(toNode.incomingLinks) do
        if hash.value == linkid then
            table.remove(fromNode.incomingLinks, k)
            break
        end
    end
    -- remove link
    table.remove(skillTree.links, linkInfo.index)
    return
end

-- Swap link targets, replacing id1 with id2
-- Links to both id1 and id2 are not touched, but are instead
-- added to mutualLink for later handling to avoid repeat swapping
local function swapLinkTargets(skillTree, links, id1, id2, mutualLinks)
    print(string.format("Replace Skill link targets %s -> %s", id1, id2))
    for _, hash in pairs(links) do
        local link = findSkillLinkById(skillTree, hash.value).link
        if link.sourceNode.value == id1 then
            if link.targetNode.value == id2 then
                mutualLinks[link.id.value] = link
            else
                link.sourceNode.value = id2
            end
        end
        if link.targetNode.value == id1 then
            if link.sourceNode.value == id2 then
                mutualLinks[link.id.value] = link
            else
                link.targetNode.value = id2
            end
        end
    end
end

-- Swap the linking and UI position of 2 skills nodes
local function swapSkillNodes(skillTree, nodeIndexes, id1, id2)
    print(string.format("Swap Skill nodes [ %s <-> %s ]", id1, id2))

    local node1 = getNodebyId(skillTree, nodeIndexes, id1)
    local node2 = getNodebyId(skillTree, nodeIndexes, id2)

    -- Swap the UI positions
    local p = node1.uiPosition
    node1.uiPosition = node2.uiPosition
    node2.uiPosition = p

    -- Collect the existing links
    local incoming1 = table.shallow_copy(node1.incomingLinks)
    local outgoing1 = table.shallow_copy(node1.outgoingLinks)
    local incoming2 = table.shallow_copy(node2.incomingLinks)
    local outgoing2 = table.shallow_copy(node2.outgoingLinks)

    -- Swap occureances of either in the existing lists
    local mutualLinks = {} -- hash table to collect unique mutual links to handle later
    swapLinkTargets(skillTree, incoming1, id1, id2, mutualLinks)
    swapLinkTargets(skillTree, outgoing1, id1, id2, mutualLinks)
    swapLinkTargets(skillTree, incoming2, id2, id1, mutualLinks)
    swapLinkTargets(skillTree, outgoing2, id2, id1, mutualLinks)

    -- Check in case something messed up
    if table.count(mutualLinks) > 1 then
        error("error - swapSkillNodes expected only one mutual link")
    end

    -- Swap source and target in a mutual link (expect just be one)
    for _, link in pairs(mutualLinks) do
        local id = link.sourceNode.value
        link.sourceNode.value = link.targetNode.value
        link.targetNode.value = id
        print(string.format("Mutual Link: %s [ %s <-> %s ] ", link.id.value, link.sourceNode.value,
            link.targetNode.value))
    end

    -- Swap the links lists between the nodes
    node1.incomingLinks = incoming2
    node1.outgoingLinks = outgoing2
    node2.incomingLinks = incoming1
    node2.outgoingLinks = outgoing1

    -- May need to swap the targets on the externally attached nodes as well, but so far not needed
end

local function Patch()

    --- @type keen.SkillTreeResource
    local skillTree = game.assets.get_resources_by_type("keen::SkillTreeResource")[1].data
    -- Create lookup table of skills nodes by id.value
    local nodeIndexes = {}
    for index, node in ipairs(skillTree.nodes) do
        nodeIndexes[node.id.value] = index
    end

    -- Check nodes of interest are present to check consts are valid
    print(string.format("skillIdPierce @ %s", nodeIndexes[skillIdPierce]))
    print(string.format("skillIdVeteren @ %s", nodeIndexes[skillIdVeteran]))
    print(string.format("skillIdTitanEdge @ %s", nodeIndexes[skillIdTitanEdge]))
    print(string.format("skillIdHeavySpec @ %s", nodeIndexes[skillIdHeavySpec]))
    print(string.format("skillIdHammerTime @ %s", nodeIndexes[skillIdHammerTime]))
    print(string.format("skillIdBrute @ %s", nodeIndexes[skillIdBrute]))
    print(string.format("skillIdSwiftBlades @ %s", nodeIndexes[skillIdSwiftBlades]))
    print(string.format("skillIdSneakAttack @ %s", nodeIndexes[skillIdSneakAttack]))
    print(string.format("skillIdBackstabDamage @ %s", nodeIndexes[skillIdBackstabDamage]))
    print(string.format("skillIdSilentStride @ %s", nodeIndexes[skillIdSilentStride]))
    print(string.format("skillIdWarriorsPath @ %s", nodeIndexes[skillIdWarriorsPath]))

    -- Set costs
    setSkillCost(skillTree, nodeIndexes, skillIdSilentStride, 2) -- 3 seemed excessive
    setSkillCost(skillTree, nodeIndexes, skillIdTitanEdge, 3) -- 4 seemed excessive

    -- Remove unwanted links
    unlinkSkillNodes(skillTree, nodeIndexes, skillIdPierce, skillIdTitanEdge)
    unlinkSkillNodes(skillTree, nodeIndexes, skillIdHammerTime, skillIdTitanEdge)
    unlinkSkillNodes(skillTree, nodeIndexes, skillIdTitanEdge, skillIdSwiftBlades)

    -- Add in new links
    linkSkillNodes(skillTree, nodeIndexes, skillIdPierce, skillIdVeteran)
    linkSkillNodes(skillTree, nodeIndexes, skillIdHeavySpec, skillIdTitanEdge)

    -- Move node UI positions
    local titanEdgeStrOffsetPos = getNodePositionDiff(skillTree, nodeIndexes, skillIdTitanEdge, skillIdTitanEdgeStrength) -- TODO use find linked skill
    local titanEdgePos = {
        x = 1897.231689453125,
        y = 4898.53955078125
    }

    moveNode(skillTree, nodeIndexes, skillIdTitanEdge, titanEdgePos)
    moveNode(skillTree, nodeIndexes, skillIdTitanEdgeStrength, offsetPos(titanEdgePos, titanEdgeStrOffsetPos))
    moveNode(skillTree, nodeIndexes, skillIdVeteran,
        projectNodePosition(skillTree, nodeIndexes, skillIdBrute, skillIdHammerTime, 1.25))

    -- Swap unique nodes

    -- Sneak attack is useless and this will not change cost of merciless
    swapSkillNodes(skillTree, nodeIndexes, skillIdSneakAttack, skillIdBackstabDamage) 

    -- Swap stat nodes

    -- Swap cons into warrior tree
    swapSkillNodes(skillTree, nodeIndexes,
        findLinkedSkill(skillTree, nodeIndexes, skillIdWarriorsPath, skillStrengthNameHash).id.value,
        findLinkedSkill(skillTree, nodeIndexes, skillIdHeavySpec, skillConstitutionNameHash).id.value)
end
