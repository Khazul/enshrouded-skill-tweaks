--- Creates a shallow copy of the given table.
-- Only the top-level keys and values are copied; nested tables are referenced.
-- @param t table The table to copy.
-- @return table A new table with the same key-value pairs as the input table.
-- TODO: move to own src
local function table_shallow_copy(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

--- Counts the number of key-value pairs in a table.
-- @param t table The table to count elements in.
-- @return number The number of elements in the table.
-- TODO: move to own src
local function table_count(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

--- SkillTreePatcher - API for manipulating skill nodes and links in the skill tree.
local SkillTreePatcher = {}
SkillTreePatcher.__index = SkillTreePatcher

--- Creates a new SkillTreePatcher instance.
function SkillTreePatcher:new()
    print("new SkillTreePatcher")

    local newObj = {}
    setmetatable(newObj, self)
    self.__index = self

    --- @type keen.SkillTreeResource
    local resources = game.assets.get_resources_by_type("keen::SkillTreeResource")
    if resources and #resources > 0 and resources[1] and resources[1].data then
        self.skillTree = resources[1].data
    else
        error("SkillTreePatcher: keen::SkillTreeResource not found or invalid structure")
    end

    -- Create lookup table of skills nodes by id.value
    self.nodeIndexes = {}
    for index, node in ipairs(self.skillTree.nodes) do
        self.nodeIndexes[node.id.value] = index
    end

    -- Used for generated link ids - assumes it is never incremented anough to collide with lowest hash values
    self.nextNewLinkId = 1

    print("SkillTreePatcher new completed")

    return newObj
end

--- Calculates the scaled difference between two positions.
-- @param p1 table The first position, with fields `x` and `y`.
-- @param p2 table The second position, with fields `x` and `y`.
-- @param s number The scale factor to apply to the difference.
-- @return table A table containing the scaled difference `{x, y}`.
function SkillTreePatcher:diffPosScaled(p1, p2, s)
    return {
        x = (p2.x - p1.x) * s,
        y = (p2.y - p1.y) * s
    }
end

--- Offsets a position by a given shift.
-- @param p table A table representing the original position with fields `x` and `y`.
-- @param s table A table representing the shift to apply, with fields `x` and `y`.
-- @return table A new table with the offset position (`x` and `y`).
-- TODO: move to own src
function SkillTreePatcher:offsetPos(p, s)
    return {
        x = p.x + s.x,
        y = p.y + s.y
    }
end

--- Calculates the difference between two positions.
-- @param p1 table The first position, with fields `x` and `y`.
-- @param p2 table The second position, with fields `x` and `y`.
-- @return table A table containing the difference in `x` and `y` coordinates (`x = p2.x - p1.x`, `y = p2.y - p1.y`).
-- TODO: move to own src
function SkillTreePatcher:diffPos(p1, p2)
    return {
        x = p2.x - p1.x,
        y = p2.y - p1.y
    }
end

--- Retrieves a skill tree node by its unique identifier.
-- @param id The unique identifier of the node to retrieve.
-- @return The skill tree node corresponding to the given id, or nil if not found.
-- TODO: move to own src
function SkillTreePatcher:getNodebyId(id)
    local index = self.nodeIndexes[id]
    return self.skillTree.nodes[index]
end

--- Moves a skill tree node to a new UI position.
-- @param id The unique identifier of the node to move.
-- @param p A table containing the new position with fields `x` and `y`.
-- @usage SkillTreePatcher:moveNode(42, {x = 100, y = 200})
function SkillTreePatcher:moveNode(id, p)
    local node = self:getNodebyId(id)
    node.uiPosition = {
        x = p.x,
        y = p.y
    }
end

--- Calculates the positional difference between two skill tree nodes by their IDs.
-- @param id1 The ID of the first node.
-- @param id2 The ID of the second node.
-- @return The difference between the UI positions of the two nodes.
function SkillTreePatcher:getNodePositionDiff(id1, id2)
    local node1 = self:getNodebyId(id1)
    local node2 = self:getNodebyId(id2)
    return self:diffPos(node1.uiPosition, node2.uiPosition)
end

--- Projects the position of a node in the skill tree based on two node IDs and a scaling factor.
-- Calculates the offset between the positions of two nodes, scales it by the given multiplier,
-- and returns the projected position relative to the second node.
-- @param id1 number The ID of the first node.
-- @param id2 number The ID of the second node.
-- @param m number The scaling multiplier for the offset.
-- @return table A table containing the projected x and y coordinates.
function SkillTreePatcher:projectNodePosition(id1, id2, m)
    local node1 = self:getNodebyId(id1)
    local node2 = self:getNodebyId(id2)
    local offset = self:diffPosScaled(node1.uiPosition, node2.uiPosition, m)
    return {
        x = node2.uiPosition.x + offset.x,
        y = node2.uiPosition.y + offset.y
    }
end

--- Finds a skill link in the skill tree by its ID.
-- @param id The ID of the skill link to find.
-- @return table A table containing the `index` of the link and the `link` object itself if found.
-- @error Throws an error if no skill link with the specified ID is found.
function SkillTreePatcher:findSkillLinkById(id)
    for i, link in ipairs(self.skillTree.links) do
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

--- Finds a skill link in the skill tree by matching the source and target node IDs.
-- @param fromId The ID of the source node to search for.
-- @param toId The ID of the target node to search for.
-- @return table A table containing the index and the link object if found.
-- @error Throws an error if no matching skill link is found.
function SkillTreePatcher:findSkillLinkBySourceTarget(fromId, toId)
    for i, link in pairs(self.skillTree.links) do
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

--- Finds a skill node linked to the given skill node by its ID and the target node's name hash.
-- Searches both outgoing and incoming links of the specified skill node to find a connected node
-- whose name matches the provided name hash.
-- @param id The ID of the skill node to search from.
-- @param nameHash The name hash of the target skill node to find.
-- @return The linked skill node whose name matches the given name hash.
-- @error Throws an error if no linked skill node with the specified name hash is found.
function SkillTreePatcher:findLinkedSkill(id, nameHash)

    local skillNode = self:getNodebyId(id)

    for _, hash in pairs(skillNode.outgoingLinks) do
        local link = self:findSkillLinkById(hash.value).link
        local node = self:getNodebyId(link.targetNode.value)
        if node.name.value == nameHash then
            return node
        end
    end

    for _, hash in pairs(skillNode.incomingLinks) do
        local link = self:findSkillLinkById(hash.value).link
        local node = self:getNodebyId(link.sourceNode.value)
        if node.name.value == nameHash then
            return node
        end
    end

    error(string.format("error - findLinkedSkill: no skill with name hash %s found connected to skill %s", nameHash, id))
end

--- Sets the cost for a skill node identified by its ID.
-- @param id The unique identifier of the skill node.
-- @param cost The new cost value to assign to the skill node.
function SkillTreePatcher:setSkillCost(id, cost)
    local node = self:getNodebyId(id)
    node.costs = cost
end

--- Links two skill nodes in the skill tree by creating a new link between them.
-- @param fromId The ID of the source skill node.
-- @param toId The ID of the target skill node.
-- Adds a link entry to the skill tree, updates outgoing and incoming links for the nodes,
function SkillTreePatcher:linkSkillNodes(fromId, toId)
    local fromNode = self:getNodebyId(fromId)
    local toNode = self:getNodebyId(toId)
    table.insert(self.skillTree.links, {
        id = {
            value = self.nextNewLinkId
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
        value = self.nextNewLinkId
    })
    table.insert(toNode.incomingLinks, {
        value = self.nextNewLinkId
    })

    print(string.format("Add link [ %s <-> %s ] as id %s", fromId, toId, self.nextNewLinkId))

    self.nextNewLinkId = self.nextNewLinkId + 1
    -- Arbitary limit warning to keep the new link ids well away from existing link id hash values
    -- that have been observed to be much higher numbers. 10000 is very unlikely to be exceeded with reasonable use.
    if self.nextNewLinkId > 10000 then
        error("error: SkillTreePatcher:linkSkillNodes - new link ids limited to avoid hash collision")
    end
end

--- Unlinks two skill nodes in the skill tree by removing the link between them.
-- @param fromId The ID of the source skill node.
-- @param toId The ID of the target skill node.
-- @return nil
function SkillTreePatcher:unlinkSkillNodes(fromId, toId)
    -- find an existing link definition
    local linkInfo = self:findSkillLinkBySourceTarget(fromId, toId)
    local linkId = linkInfo.link.id.value
    print(string.format("Remove link %s [ %s <-> %s ]", linkId, fromId, toId))

    -- remove the outgoing link
    local fromNode = self:getNodebyId(fromId)
    for j, hash in ipairs(fromNode.outgoingLinks) do
        if hash.value == linkId then
            table.remove(fromNode.outgoingLinks, j)
            break
        end
    end
    -- remove the incomming link
    local toNode = self:getNodebyId(toId)
    for k, hash in ipairs(toNode.incomingLinks) do
        if hash.value == linkId then
            table.remove(toNode.incomingLinks, k)
            break
        end
    end
    -- remove link
    table.remove(self.skillTree.links, linkInfo.index)
end

--- Swaps the source and target node IDs in a set of skill links.
-- For each link, if the source or target node matches `id1`, it is replaced with `id2`.
-- If a link is mutual (i.e., source is `id2` and target is `id1`, or vice versa), it is added to `mutualLinks`.
-- @param links Table containing skill link hashes.
-- @param id1 The node ID to be replaced.
-- @param id2 The node ID to replace with.
-- @param mutualLinks Table to collect links that are mutual between `id1` and `id2`.
function SkillTreePatcher:swapLinkTargets(links, id1, id2, mutualLinks)
    print(string.format("Replace Skill link targets %s -> %s", id1, id2))
    for _, hash in pairs(links) do
        local link = self:findSkillLinkById(hash.value).link
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

--- Swaps two skill nodes in the skill tree, exchanging their UI positions and link relationships.
-- @param id1 The first skill node ID
-- @param id2 The second skill node ID
function SkillTreePatcher:swapSkillNodes(id1, id2)
    print(string.format("Swap Skill nodes [ %s <-> %s ]", id1, id2))

    local node1 = self:getNodebyId(id1)
    local node2 = self:getNodebyId(id2)

    -- Swap the UI positions
    local p = node1.uiPosition
    node1.uiPosition = node2.uiPosition
    node2.uiPosition = p

    -- Collect the existing links
    local incoming1 = table_shallow_copy(node1.incomingLinks)
    local outgoing1 = table_shallow_copy(node1.outgoingLinks)
    local incoming2 = table_shallow_copy(node2.incomingLinks)
    local outgoing2 = table_shallow_copy(node2.outgoingLinks)

    -- Swap occureances of either in the existing lists
    local mutualLinks = {} -- hash table to collect unique mutual links to handle later
    self:swapLinkTargets(incoming1, id1, id2, mutualLinks)
    self:swapLinkTargets(outgoing1, id1, id2, mutualLinks)
    self:swapLinkTargets(incoming2, id2, id1, mutualLinks)
    self:swapLinkTargets(outgoing2, id2, id1, mutualLinks)

    -- Check in case something messed up - assuming that two nodes can only ever have one mutual link
    if table_count(mutualLinks) > 1 then
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

print("import SkillTreePatcher")

return SkillTreePatcher