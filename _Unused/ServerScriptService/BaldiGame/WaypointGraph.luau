--[[
	WaypointGraph (ModuleScript, ServerScriptService.BaldiGame.WaypointGraph)

	A weighted graph over a map's waypoint parts, searched with Dijkstra's
	algorithm (binary min-heap). It's the NPCs' "mental map": the big-picture
	route across the building, while SimplePath / PathfindingService handle
	the footwork of each leg.

	  - Nodes: every BasePart in the waypoints folder.
	  - Edges: node pairs with a clear, floored straight line between them
	    (knee-height raycasts at the centre and both shoulders, plus a floor
	    check at the midpoint), weighted by distance. Pairs within
	    PATH_EDGE_RANGE without a straight line get a PathfindingService
	    route instead, weighted by its length, whose waypoints are spliced
	    into any route that uses the edge.
	  - One graph per folder, built once (yields) and rebuilt if the folder's
	    children change.

	API
	  WaypointGraph.get(folder, opts) -> graph (opts: rayParams, clearance, agentParams)
	  graph:shortestPath(fromPos, toPos) -> points, jumps | nil
	  graph:distancesFrom(pos) -> { { pos = Vector3, dist = number } }  (reachable nodes)
	  graph:clearLine(a, b) -> bool
]]

local PathfindingService = game:GetService("PathfindingService")

local WaypointGraph = {}
WaypointGraph.__index = WaypointGraph

local KNEE = 2 -- studs above the floor the edge rays travel at
local PATH_EDGE_RANGE = 120 -- no straight line? try a PathfindingService edge up to this far
local NEAREST_CANDIDATES = 6 -- nodes tried when looking for a visible entry/exit node

local cache = {} -- [folder] = graph

-- ---------- binary min-heap of { node, dist } ----------

local function heapPush(heap, item)
	table.insert(heap, item)
	local i = #heap
	while i > 1 do
		local parent = i // 2
		if heap[parent].dist <= heap[i].dist then
			break
		end
		heap[parent], heap[i] = heap[i], heap[parent]
		i = parent
	end
end

local function heapPop(heap)
	local top = heap[1]
	local last = table.remove(heap)
	if #heap > 0 then
		heap[1] = last
		local i, n = 1, #heap
		while true do
			local l, r, smallest = i * 2, i * 2 + 1, i
			if l <= n and heap[l].dist < heap[smallest].dist then
				smallest = l
			end
			if r <= n and heap[r].dist < heap[smallest].dist then
				smallest = r
			end
			if smallest == i then
				break
			end
			heap[smallest], heap[i] = heap[i], heap[smallest]
			i = smallest
		end
	end
	return top
end

-- ---------- geometry ----------

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

-- a ray that passes through characters (players and NPCs aren't walls)
function WaypointGraph:cast(origin, direction)
	local params = self.rayParams
	local ignored = nil
	for _ = 1, 6 do
		local hit = workspace:Raycast(origin, direction, params)
		if not hit then
			return nil
		end
		local model = hit.Instance:FindFirstAncestorOfClass("Model")
		if not (model and model:FindFirstChildOfClass("Humanoid")) then
			return hit
		end
		if not ignored then
			ignored = table.clone(params.FilterDescendantsInstances)
			params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
		end
		table.insert(ignored, model)
		params.FilterDescendantsInstances = ignored
	end
	return nil
end

-- the floor under a point, lifted to knee height
function WaypointGraph:knee(position)
	local hit = self:cast(position + Vector3.new(0, 2, 0), Vector3.new(0, -20, 0))
	if hit then
		return Vector3.new(position.X, hit.Position.Y + KNEE, position.Z)
	end
	return position
end

-- a body-wide, floored straight line from a to b
function WaypointGraph:clearLine(a, b)
	a, b = self:knee(a), self:knee(b)
	local delta = flat(b - a)
	local distance = delta.Magnitude
	if distance < 2 then
		return true
	end
	if math.abs(b.Y - a.Y) > 6 then
		return false -- different floors: leave it to pathfinding
	end
	local direction = delta / distance
	local step = (b - a) -- follows gentle ramps
	local side = Vector3.new(-direction.Z, 0, direction.X) * self.clearance
	for _, offset in ipairs({ Vector3.zero, side, -side }) do
		if self:cast(a + offset, step) then
			return false
		end
	end
	for _, t in ipairs({ 0.25, 0.5, 0.75 }) do
		if not self:cast(a + step * t, Vector3.new(0, -7, 0)) then
			return false -- a hole along the way
		end
	end
	return true
end

-- ---------- building ----------

function WaypointGraph:build()
	local nodes = {}
	for _, part in ipairs(self.folder:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(nodes, part.Position)
		end
	end
	local edges = {}
	for i = 1, #nodes do
		edges[i] = {}
	end

	local path = PathfindingService:CreatePath(self.agentParams)
	for i = 1, #nodes do
		for j = i + 1, #nodes do
			local a, b = nodes[i], nodes[j]
			local distance = (b - a).Magnitude
			if self:clearLine(a, b) then
				edges[i][j] = { cost = distance }
				edges[j][i] = { cost = distance }
			elseif distance <= PATH_EDGE_RANGE then
				local ok = pcall(function()
					path:ComputeAsync(a, b)
				end)
				if ok and path.Status == Enum.PathStatus.Success then
					local waypoints = path:GetWaypoints()
					local length, points, jumps = 0, {}, {}
					for k = 2, #waypoints do
						length += (waypoints[k].Position - waypoints[k - 1].Position).Magnitude
						if k < #waypoints then
							table.insert(points, waypoints[k].Position)
							jumps[#points] = waypoints[k].Action == Enum.PathWaypointAction.Jump or nil
						end
					end
					-- only worth it when it's a real detour-free connection, not
					-- a trip through half the map (the graph finds those itself)
					if length <= distance * 2 then
						local reversed, reversedJumps = {}, {}
						for k = #points, 1, -1 do
							table.insert(reversed, points[k])
							reversedJumps[#reversed] = jumps[k]
						end
						edges[i][j] = { cost = length, points = points, jumps = jumps }
						edges[j][i] = { cost = length, points = reversed, jumps = reversedJumps }
					end
				end
			end
		end
		task.wait() -- spread the raycasts / path computes out
	end
	path:Destroy()

	self.nodes, self.edges = nodes, edges
	self.dirty = false
end

function WaypointGraph:ensureBuilt()
	while self.building do
		task.wait()
	end
	if self.dirty or not self.nodes then
		self.building = true
		local ok, err = pcall(self.build, self)
		self.building = false
		if not ok then
			warn("[Tmod] WaypointGraph build failed: " .. tostring(err))
			self.nodes, self.edges = self.nodes or {}, self.edges or {}
		end
	end
end

-- ---------- Dijkstra ----------

-- nodes a position can walk straight to, with that walk's length
function WaypointGraph:visibleNodes(position)
	local order = {}
	for i, node in ipairs(self.nodes) do
		table.insert(order, { index = i, dist = (node - position).Magnitude })
	end
	table.sort(order, function(a, b)
		return a.dist < b.dist
	end)
	local visible = {}
	for k = 1, math.min(NEAREST_CANDIDATES, #order) do
		if self:clearLine(position, self.nodes[order[k].index]) then
			table.insert(visible, order[k])
		end
	end
	return visible
end

-- multi-source Dijkstra: dist[] and prev[] from the given { index, dist } seeds
function WaypointGraph:dijkstra(seeds)
	local dist, prev, done = {}, {}, {}
	local heap = {}
	for _, seed in ipairs(seeds) do
		if seed.dist < (dist[seed.index] or math.huge) then
			dist[seed.index] = seed.dist
			heapPush(heap, { node = seed.index, dist = seed.dist })
		end
	end
	while #heap > 0 do
		local item = heapPop(heap)
		local u = item.node
		if not done[u] then
			done[u] = true
			for v, edge in pairs(self.edges[u]) do
				local alt = dist[u] + edge.cost
				if alt < (dist[v] or math.huge) then
					dist[v] = alt
					prev[v] = u
					heapPush(heap, { node = v, dist = alt })
				end
			end
		end
	end
	return dist, prev
end

-- Route from fromPos to toPos across the graph: walk to a visible node,
-- follow the shortest node chain, then walk from the last node to toPos.
-- Returns the route's points (ending at toPos) and a { [i] = true } jump
-- map, or nil when the graph can't connect them.
function WaypointGraph:shortestPath(fromPos, toPos)
	self:ensureBuilt()
	if #self.nodes == 0 then
		return nil
	end
	local starts = self:visibleNodes(fromPos)
	local ends = self:visibleNodes(toPos)
	if #starts == 0 or #ends == 0 then
		return nil
	end
	local dist, prev = self:dijkstra(starts)

	-- best exit node: graph distance + the walk from it to the goal
	local best, bestCost = nil, math.huge
	for _, exit in ipairs(ends) do
		local d = dist[exit.index]
		if d and d + exit.dist < bestCost then
			best, bestCost = exit.index, d + exit.dist
		end
	end
	if not best then
		return nil
	end

	local chain = {}
	local node = best
	while node do
		table.insert(chain, 1, node)
		node = prev[node]
	end

	local points, jumps = {}, {}
	for k, index in ipairs(chain) do
		if k > 1 then
			local edge = self.edges[chain[k - 1]][index]
			for m, point in ipairs(edge.points or {}) do
				table.insert(points, point)
				jumps[#points] = edge.jumps and edge.jumps[m] or nil
			end
		end
		table.insert(points, self.nodes[index])
	end
	table.insert(points, toPos)
	return points, jumps, bestCost
end

-- graph distance from pos to every node it can reach (for search sweeps)
function WaypointGraph:distancesFrom(position)
	self:ensureBuilt()
	local dist = self:dijkstra(self:visibleNodes(position))
	local result = {}
	for index, d in pairs(dist) do
		table.insert(result, { pos = self.nodes[index], dist = d })
	end
	table.sort(result, function(a, b)
		return a.dist < b.dist
	end)
	return result
end

-- true once a build has finished and nothing changed since (never yields)
function WaypointGraph:ready()
	return self.nodes ~= nil and not self.dirty and not self.building
end

function WaypointGraph.get(folder, opts)
	local graph = cache[folder]
	if graph then
		return graph
	end
	opts = opts or {}
	graph = setmetatable({
		folder = folder,
		rayParams = opts.rayParams or RaycastParams.new(),
		clearance = opts.clearance or 2,
		agentParams = opts.agentParams or { AgentRadius = 2, AgentHeight = 5, AgentCanJump = true },
		dirty = true,
	}, WaypointGraph)
	cache[folder] = graph
	local function markDirty()
		graph.dirty = true
	end
	folder.ChildAdded:Connect(markDirty)
	folder.ChildRemoved:Connect(markDirty)
	folder.Destroying:Connect(function()
		cache[folder] = nil
	end)
	return graph
end

return WaypointGraph
