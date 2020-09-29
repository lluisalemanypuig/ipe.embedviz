----------------------------------------------------------------------
-- Automatic labelling ipelet
----------------------------------------------------------------------
--[[
This file is an extension of the drawing editor Ipe (ipe7.sourceforge.net)

Copyright (c) 2020 Lluís Alemany-Puig

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]


--[[
You'll find the instruction manual at:
https://github.com/lluisalemanypuig/ipe.drawembedding
--]]

--- AUXILIARY FUNCTIONS

--[[
Function 'split_string' is borrowed from: https://stackoverflow.com/a/1579673/12075306
]]--
function split_string(pString, pPattern)
	local Table = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pPattern
	local last_end = 1
	local s, e, cap = pString:find(fpat, 1)
	while s do
		if s ~= 1 or cap ~= "" then
			table.insert(Table,cap)
		end
		last_end = e + 1
		s, e, cap = pString:find(fpat, last_end)
	end
	if last_end <= #pString then
		cap = pString:sub(last_end)
		table.insert(Table, cap)
	end
	return Table
end

---------------------------------------
-- look for errors in the input data --
function check(__edge_list, __embedding, model)
	local edge_list = split_string(__edge_list, " ")
	local embedding = split_string(__embedding, " ")
	
	local mx2 = #edge_list
	local n = #embedding
	
	-- 1. The number of elements in edge_list must be even
	if mx2%2 == 1 then
		model:warning("List of edges contains an odd number of elements.")
		return
	end
	
	-- 2. check that the embedding is a permutation
	local perm = {}
	local vertex_set = {}
	for i = 1,n do
		v = tonumber(embedding[i])
		if v <= 0 then
			model:warning("Invalid value '" .. v .. "'.")
			return
		end
		
		if vertex_set[v] == nil then
			vertex_set[v] = true
			perm[#perm + 1] = v
		else
			model:warning("Repeated vertex '" .. v .. "'.")
			return
		end
	end
	
	-- 3. make sure there are as many labels as vertices
	if #vertex_set ~= n then
		print("Error: there are more labels than vertices")
		return
	end
	
	-- allocate adjacency matrix
	local adj_matrix = {}
	for i = 1,n do
		adj_matrix[i] = {}
		for j = 1,n do
			adj_matrix[i][j] = false
		end
	end
	
	-- fill adjacency matrix
	for i = 1,mx2,2 do
		v1 = tonumber(edge_list[i])
		v2 = tonumber(edge_list[i + 1])
		if v1 == v2 then
			model:warning("Self-loop " .. "{" .. v1 .. "," .. v2 .. "}.")
			return
		end
		
		-- 4. check vertices exist
		if vertex_set[v1] == nil then
			model:warning("Vertex " .. v1 .. " does not exist in the embedding.")
			return
		end
		if vertex_set[v2] == nil then
			model:warning("Vertex " .. v2 .. " does not exist in the embedding.")
		end
		
		-- 5. if the edge does not exist add it to the matrix
		if adj_matrix[v1][v2] == false then
			adj_matrix[v1][v2] = true
			adj_matrix[v2][v1] = true
		else
			model:warning("Multiedges were found {" .. v1 .. "," .. v2 .. "}.")
		end
	end
	
	return perm, adj_matrix
end

function midpoint(x1,x2)
	local midx = (x1.x + x2.x)/2
	local midy = (x1.y + x2.y)/2
	return ipe.Vector(midx, midy)
end

function make_arc(model, left, right)
	local C = midpoint(left, right) -- center of the arc
	local r = right.x - C.x -- radius of the arc
	local arc = ipe.Arc(ipe.Matrix(r, 0, 0, r, C.x, C.y), right,left)
	local arc_seg = {type="arc", right, left, arc = arc}
	local curve = {type="curve", closed = false, arc_seg}
	local path = ipe.Path(model.attributes, {curve})
	return path
end

function add_arc(model, left, right)
	local path = make_arc(model, left, right)
	model:creation("ACTION", path)
end

-----------------------------
--- IPELET IMPLEMENTATION ---

label = "Embedding visualizer"

about = [[
Tool for drawing (linear) embeddings of graphs.
]]

-- VARIABLES
local dist = 64 -- distance between consecutive points
local xstart = 24  -- starting x coordinate
local ycoord = 500 -- height of the points

-- prompt the user asking where to put the label next to selected objects
function run(model)
	local d = ipeui.Dialog(model.ui:win(), "Indicate graph and embedding")

	d:add("label1", "label", {label="graph edges"}, 1, 1)
	d:add("edges", "input", {}, 1, 2, 1, 3)
	d:add("label2", "label", {label="embedding"}, 2, 1)
	d:add("embedding", "input", {}, 2, 2, 1, 3)
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	if not d:execute() then
		return
	end
	
	-- input data
	local edge_list = d:get("edges")
	local embedding = d:get("embedding")
	
	-- check for errors in the data,
	-- and retrieve embedding and adjacency matrix
	local perm, adj = check(edge_list, embedding, model)
	if perm == nil then
		print("Something is wrong in the data...")
		return
	end
	-- nothing is wrong with the data!
	
	local n = #perm	-- number of vertices
	local mx2 = #edge_list -- number of edges
	
	-- make coordinates
	local coords_x = {}
	for idx,i in ipairs(perm) do
		coords_x[i] = idx*dist + xstart
	end
	
	-- make labels
	for i = 1,n do
		-- make the text
		local text_str = tostring(i)
		-- create the text label
		local pos = ipe.Vector(coords_x[i] - 4, ycoord - 8)
		local text = ipe.Text(model.attributes, text_str, pos)
		-- add the text label to the document
		model:creation("create label", text)
	end
	
	-- create arcs
	for i = 1,n do
		for j = i+1,n do
			if adj[i][j] == true then
				-- choose right and left points
				local right = nil
				local left = nil
				if perm[i] < perm[j] then
					right = ipe.Vector(coords_x[j], ycoord)
					left = ipe.Vector(coords_x[i], ycoord)
				else
					right = ipe.Vector(coords_x[i], ycoord)
					left = ipe.Vector(coords_x[j], ycoord)
				end
				-- add the arc to ipe
				add_arc(model, left, right)
			end
		end
	end
end
