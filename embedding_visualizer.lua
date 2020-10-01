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

function table_length(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

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

-- parse input data while looking for errors in it
function parse_data(__arr, __inv_arr, __edge_list, model)
	if __edge_list == "" then
		model:warning("No edges were given.")
	end
	if __arr == "" and __inv_arr == "" then
		model:warning("No linear arrangement, nor an inverse linear arrangement, were given.")
		return false
	end
	if __arr ~= "" and __inv_arr ~= "" then
		model:warning("Both linear arrangement and inverse linear arrangement were given. Please, input only one of the two.")
		return false
	end
	
	local edge_list = split_string(__edge_list, " ")
	local arr = split_string(__arr, " ")
	local inv_arr = split_string(__inv_arr, " ")
	
	-- description of the input data
	local has_zero = false
	local use_arr = false
	local use_inv_arr = false
	
	-- number of edges
	local mx2 = #edge_list
	
	-- number of vertices
	local n = 0
	if __arr ~= "" then
		n = #arr
		use_arr = true
	end
	if __inv_arr ~= "" then
		n = #inv_arr
		use_inv_arr = true
	end
	
	-- 1.1. The number of elements in edge_list must be even
	if mx2%2 == 1 then
		model:warning("List of edges contains an odd number of elements.")
		return false
	end
	
	-- 1.2. retrieve the vertex set by parsing the list of edges.
	local vertex_set = {}
	for i = 1,mx2,2 do
		v1 = edge_list[i]
		v2 = edge_list[i + 1]
		if vertex_set[v1] == nil then vertex_set[v1] = true end
		if vertex_set[v2] == nil then vertex_set[v2] = true end
	end
	
	-- actual arrangament and inverse arrangement
	local func_pi = {}
	local func_inv_pi = {}
	
	-- 2. construct arrangement
	
	if __arr ~= "" then
		----------------------------
		-- parse linear arrangement
		
		-- 2.2. does the arrangement contain a zero?
		-- 2.3. make sure there are as many different positions as vertices
		local pos_set = {}
		for i = 1,n do
			position_str = arr[i]
			pos = tonumber(position_str)
			if pos == nil then
				model:warning("The arrangement containts non-numerical values: only numberical values are allowed in the arrangement!")
				return false
			end
			if pos == 0 then has_zero = true end
			if pos_set[pos] == nil then
				pos_set[pos] = true
			else
				model:warning("Repeated position '" .. pos .. "'.")
				return false
			end
		end
		
		-- 2.4. sort the vertex set lexicographically
		a = {}
		for n in pairs(vertex_set) do table.insert(a, n) end
		table.sort(a,
			function(s1,s2)
				if #s1 < #s2 then return true end
				if #s1 > #s2 then return false end
				return s1 < s2
			end
		)
		
		-- 2.5. construct the arrangement
		for i = 1,n do
			position_str = arr[i]
			pos = tonumber(position_str)
			if has_zero then pos = pos + 1 end
			
			v = a[i] -- the i-th vertex in the lexicographic order
			func_pi[v] = pos
			func_inv_pi[pos] = v
		end
	else
		----------------------------
		-- parse inverse linear arrangement
		
		for i = 1,n do
			v = inv_arr[i]
			func_pi[v] = i		-- pi[v] = i <-> position of 'v' is 'i'
			func_inv_pi[i] = v	-- inv_pi[i] = v <-> position of 'v' is 'i'
		end
	end
	
	-- 3. make sure there are as many labels as vertices
	vs_len = table_length(vertex_set)
	if vs_len > n then
		model:warning("Error: there are more labels than vertices in the sequence")
		return false
	end
	if vs_len < n then
		model:warning("Error: there are less labels than vertices in the sequence")
		return false
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
		v1 = edge_list[i]
		v2 = edge_list[i + 1]
		
		-- 4. check correctness of edges
		if v1 == v2 then
			model:warning("Self-loop " .. "{" .. v1 .. "," .. v2 .. "}.")
			return false
		end
		if vertex_set[v1] == nil then
			model:warning("Vertex " .. v1 .. " does not exist in the embedding.")
			return false
		end
		if vertex_set[v2] == nil then
			model:warning("Vertex " .. v2 .. " does not exist in the embedding.")
		end
		
		-- 5. if the edge was not added before, add it now to the matrix
		p1 = func_pi[v1]
		p2 = func_pi[v2]
		if adj_matrix[p1][p2] == false then
			adj_matrix[p1][p2] = true
			adj_matrix[p2][p1] = true
		else
			model:warning("Multiedges were found {" .. v1 .. "," .. v2 .. "}.")
			return false
		end
	end
	
	return
		true, func_pi, func_inv_pi, adj_matrix,
		{_use_arr = use_arr, _use_inv_arr = use_inv_arr, _has_zero = has_zero}
end

function midpoint(x1,x2)
	local midx = (x1.x + x2.x)/2
	local midy = (x1.y + x2.y)/2
	return ipe.Vector(midx, midy)
end

function make_arc(model, left, right)
	-- arc's center
	local C = midpoint(left, right)
	-- radius of the arc (assumes that the points' location only varies in x)
	local r = right.x - C.x
	-- make arc object
	local arc = ipe.Arc(ipe.Matrix(r, 0, 0, r, C.x, C.y), right,left)
	-- prepare binding
	local arc_seg = {type="arc", right, left, arc = arc}
	local curve = {type="curve", closed = false, arc_seg}
	-- make Path object
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
local xoffset = 64 -- distance between consecutive points
local xstart = 24  -- starting x coordinate
local ycoord = 500 -- height of the points

-- prompt the user asking where to put the label next to selected objects
function run(model)
	local d = ipeui.Dialog(model.ui:win(), "Describe graph and sequence")
	
	d:add("label1", "label", {label="Edge list"}, 1, 1)
	d:add("edges", "input", {}, 1, 2, 1, 4)
	
	d:add("label3", "label", {label="Arrangement"}, 2, 1)
	d:add("arrangement", "input", {}, 2, 2)
	
	d:add("label2", "label", {label="Inv. Arrang."}, 2, 3)
	d:add("inv_arrangement", "input", {}, 2, 4)
	
	d:add("label2", "label", {label="X offset"}, 3, 1)
	d:add("xoffset", "input", {}, 3, 2)
	
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	if not d:execute() then
		return
	end
	
	-- input data
	local edge_list = d:get("edges")
	local arrangement = d:get("arrangement")
	local inv_arrangement = d:get("inv_arrangement")
	
	-- parse the data
	local
		success, arr, inv_arr, adj_matrix,
		input_data_descr
		=
		parse_data(arrangement, inv_arrangement, edge_list, model)
	
	local input_offset = d:get("xoffset")
	if input_offset ~= "" then
		xoffset = tonumber(input_offset)
		if xoffset == nil then
			model:warning("Input offset is not numerical.")
			return
		end
	end
	
	-- if errors were found...
	if success == false then
		return
	end
	
	------
	-- nothing is wrong with the data!
	
	local n = table_length(arr)	-- number of vertices
	
	-- make coordinates
	local coords_x = {}
	for i = 1,n do
		v_i = inv_arr[i]
		coords_x[v_i] = i*xoffset + xstart
	end
	
	-- make labels
	for i = 1,n do
		v_i = inv_arr[i]
		
		-- create the text label
		local pos = ipe.Vector(coords_x[v_i] - 4, ycoord - 8)
		local text = ipe.Text(model.attributes, v_i, pos)
		-- add the text label to the document
		model:creation("create label", text)
	end
	
	-- make labels for the positions
	local has_zero = input_data_descr["_has_zero"]
	for i = 1,n do
		v_i = inv_arr[i]
		
		local contents = ""
		if has_zero then
			contents = tostring(i - 1)
		else
			contents = tostring(i)
		end
		
		-- create the text label
		local pos = ipe.Vector(coords_x[v_i] - 4, ycoord - 16)
		local text = ipe.Text(model.attributes, contents, pos)
		-- add the text label to the document
		model:creation("create label", text)
	end
	
	-- create arcs
	for p_i = 1,n do
		for p_j = p_i+1,n do
			if adj_matrix[p_i][p_j] == true then
				v_i = inv_arr[p_i]
				v_j = inv_arr[p_j]
				
				-- choose right and left points
				local right = nil
				local left = nil
				if arr[v_i] < arr[v_j] then
					right = ipe.Vector(coords_x[v_j], ycoord)
					left = ipe.Vector(coords_x[v_i], ycoord)
				else
					right = ipe.Vector(coords_x[v_i], ycoord)
					left = ipe.Vector(coords_x[v_j], ycoord)
				end
				-- add the arc to ipe
				add_arc(model, left, right)
			end
		end
	end
end
