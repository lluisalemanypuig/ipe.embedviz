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

------------------------------------------------------------------------
------------------------------------------------------------------------

label = "Embedding visualizer"

about = [[
Tool for drawing (linear) embeddings of graphs.
]]

-- VARIABLES
local xoffset = 16 -- default distance between consecutive points
local xstart = 24  -- starting x coordinate
local ycoord = 500 -- height of the points

------------------------------------------------------------------------
------------------------------------------------------------------------
--- AUXILIARY FUNCTIONS

function next_multiple_four(f)
	return math.floor(f) + 4 - math.floor(f)%4
end

function table_length(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- functions to parse the input string
function find_valid(str, i)
	while
	i <= #str and
	(
		string.sub(str, i,i) == " " or
		string.sub(str, i,i) == "," or
		string.sub(str, i,i) == "|"
	)
	do
		i = i + 1
	end
	return i
end
function find_invalid(str, i)
	while
	i <= #str and
	string.sub(str, i,i) ~= " " and
	string.sub(str, i,i) ~= "," and
	string.sub(str, i,i) ~= "|"
	do
		i = i + 1
	end
	return i
end
function parse_input(input)
	local Vertices = {}
	local i = find_valid(input, 1)
	while i <= #input do
		local j = find_invalid(input, i + 1)
		local word = string.sub(input, i, j - 1)
		table.insert(Vertices, word)
		i = find_valid(input, j)
	end
	return Vertices
end

------------------------------------------------------------------------
------------------------------------------------------------------------
--- PARSE INPUT DATA

function parse_data_case1(__linear_sequence, d, model)
	local lin_seq = parse_input(__linear_sequence)
	
	-- number of vertices
	local n = #lin_seq
	
	-- allocate adjacency matrix
	local adj_matrix = {}
	for i = 1,n do
		adj_matrix[i] = {}
		for j = 1,n do
			adj_matrix[i][j] = false
		end
	end
	
	-- construct arrangement and linear arrangement
	local func_pi = {}
	local func_inv_pi = {}
	local root_vertex = nil
	
	local sequence_contains_zero = false
	for pos = 1,n do
		local parent_ref_str = lin_seq[pos]
		local parent_pos = tonumber(parent_ref_str)
		if parent_pos == nil then
			model:warning("Non-numeric values are not allowed in the linear sequence.")
			return false
		end
		
		if parent_pos < 0 then
			model:warning("Negative values are not allowed in the linear sequence.")
			return false
		end
		
		local this_vertex_str = tostring(pos)
		if parent_pos == 0 then
			sequence_contains_zero = true
			root_vertex = pos
			
			-- arrangement and inverse arrangement are the identity function
			func_pi[this_vertex_str] = pos
			func_inv_pi[pos] = this_vertex_str
		end
		
		if parent_pos > 0 then
			adj_matrix[pos][parent_pos] = true
			adj_matrix[parent_pos][pos] = true
			
			-- arrangement and inverse arrangement are the identity function
			func_pi[this_vertex_str] = pos
			func_inv_pi[pos] = this_vertex_str
		end
	end
	
	return
		-- success
		true,
		{
			-- the relevant data for this case
			arr = func_pi,
			inv_arr = func_inv_pi,
			adj_matrix = adj_matrix,
			root = root_vertex,
			-- description of the data
			uses_zero = sequence_contains_zero,
			n = n,
			-- others
			automatic_spacing = d:get("automatic_spacing")
		}
end

function parse_data_case2(__edge_list, __arr, __inv_arr, d, model)
	local has_zero = false
	local use_arr = false
	local use_inv_arr = false
	
	local arr = nil
	local inv_arr = nil
	
	if __arr ~= "" then
		use_arr = true
		arr = parse_input(__arr)
	end
	if __inv_arr ~= "" then
		use_inv_arr = true
		inv_arr = parse_input(__inv_arr)
	end
	
	if not use_arr and not use_inv_arr then
		model:warning("No linear arrangement, nor an inverse linear arrangement, were given.")
		return false
	end
	if use_arr and use_inv_arr then
		model:warning("Both linear arrangement and inverse linear arrangement were given. Please, input only one of the two.")
		return false
	end
	
	local edge_list = parse_input(__edge_list)
	
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
		local v1 = edge_list[i]
		local v2 = edge_list[i + 1]
		if vertex_set[v1] == nil then vertex_set[v1] = true end
		if vertex_set[v2] == nil then vertex_set[v2] = true end
	end
	
	-- actual arrangament and inverse arrangement
	local func_pi = {}
	local func_inv_pi = {}
	
	-- 2. construct arrangement and inverse arrangement
	
	if use_arr then
		----------------------------
		-- parse linear arrangement
		
		-- 2.2. does the arrangement contain a zero?
		-- 2.3. make sure there are as many different positions as vertices
		local pos_set = {}
		for i = 1,n do
			local position_str = arr[i]
			local pos = tonumber(position_str)
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
		local a = {}
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
			local position_str = arr[i]
			local pos = tonumber(position_str)
			if has_zero then pos = pos + 1 end
			
			local v = a[i] -- the i-th vertex in the lexicographic order
			func_pi[v] = pos
			func_inv_pi[pos] = v
		end
	end
	if use_inv_arr then
		-----------------------------------
		-- parse inverse linear arrangement
		for i = 1,n do
			local v = inv_arr[i] -- 'v' is a STRING
			func_pi[v] = i		-- pi[v] = i <-> position of 'v' is 'i'
			func_inv_pi[i] = v	-- inv_pi[i] = v <-> position of 'v' is 'i'
		end
	end
	
	-- 3. make sure there are as many labels as vertices
	local vs_len = table_length(vertex_set)
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
		local v1 = edge_list[i]
		local v2 = edge_list[i + 1]
		
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
		local p1 = func_pi[v1]
		local p2 = func_pi[v2]
		if adj_matrix[p1][p2] == false then
			adj_matrix[p1][p2] = true
			adj_matrix[p2][p1] = true
		else
			model:warning("Multiedges were found {" .. v1 .. "," .. v2 .. "}.")
			return false
		end
	end
	
	return
		-- success
		true,
		{
			-- the relevant data for this case
			arr = func_pi,
			inv_arr = func_inv_pi,
			adj_matrix = adj_matrix,
			root = nil,
			-- description of the data
			uses_zero = has_zero,
			n = n,
			-- others
			automatic_spacing = d:get("automatic_spacing")
		}
end

-- parse input data while looking for errors in it
function parse_data(d, model)
	-- retrieve the input data from the dialog
	local __linear_sequence = d:get("linear_sequence")
	local __edge_list = d:get("edges")
	local __arrangement = d:get("arrangement")
	local __inv_arrangement = d:get("inv_arrangement")
	
	-- Decide what to use: either list of edges (and arrangement or inverse
	-- linear arrangement), or a linear sequence describing the graph.
	local use_edges = false
	local use_sequence = false
	if __linear_sequence ~= "" then
		use_sequence = true
	end
	if __edge_list ~= "" then
		use_edges = true
	end
	
	-- check that we only have one of the two possible sets of input data
	if not use_sequence and not use_edges then
		model:warning("Empty input: enter the linear sequence or the list of edges.")
		return false
	end
	if use_sequence and use_edges then
		model:warning("Too much data: enter the linear sequence or the list of edges.")
		return false
	end
	
	-- CASE 1
	-- use only the linear sequence
	if use_sequence then
		return parse_data_case1(__linear_sequence, d, model)
	end
	
	-- CASE 2
	-- use only the edge list
	if use_edges then
		return parse_data_case2(__edge_list, __arrangement, __inv_arrangement, d, model)
	end
end

------------------------------------------------------------------------
------------------------------------------------------------------------

function midpoint(x1,x2)
	local midx = (x1.x + x2.x)/2
	local midy = (x1.y + x2.y)/2
	return ipe.Vector(midx, midy)
end

function add_arc(model, left, right)
	-- MAKE ARC
	
	-- arc's center
	local C = midpoint(left, right)
	-- radius of the arc (assumes that the points' location only varies in x)
	local r = right.x - C.x
	-- make matrix of the arc
	local matrix_arc = ipe.Arc(ipe.Matrix(r, 0, 0, r, C.x, C.y), right,left)
	-- prepare binding
	local arc_as_table = {type="arc", right, left, arc = matrix_arc}
	local arc_as_curve = {type="curve", closed = false, arc_as_table}
	-- make Path object
	local path = ipe.Path(model.attributes, {arc_as_curve})
	
	-- ADD ARC
	model:creation("Added arc", path)
end

--[[
Draw the data given in the input.

Fields:
	- arr: The arrangement to draw. This is a table: arr[s].
		* 's' is a STRING value (the name of a vertex).
		* arr[s] contains a NUMERIC value, used to work out the position
		of a given vertex.
		
	- inv_arr: The inverse arrangement. This is a table: inv_arr[i].
		* 'i' must be a NUMERIC value, from 1 to n.
		* inv_arr[i] contains a STRING (the name of a vertex). This is
		used to draw below every mark in the arrangement the name of the
		vertex.
	
	- adj_matrix: the adjacency matrix. This is a matrix: adj_matrix[i][j].
		* 'i' and 'j' must be NUMERIC values from 1 to n.
		* The value adj_matrix[i][j] is there is an arc between positions
		'i' and 'j'.
	
	- n: a NUMERIC value, the number of vertices.
	
	- uses_zero: a BOOLEAN value, indicates whether the smallest vertex
		index is 0 or not.
--]]
function draw_data(model, data_to_be_drawn)
	local arr = data_to_be_drawn["arr"]
	local inv_arr = data_to_be_drawn["inv_arr"]
	local adj_matrix = data_to_be_drawn["adj_matrix"]
	local root_vertex = data_to_be_drawn["root"]
	local uses_zero = data_to_be_drawn["uses_zero"]
	local n = data_to_be_drawn["n"]
	local automatic_spacing = data_to_be_drawn["automatic_spacing"]
	
	local p = model:page()
	local prev_Nobj = #p
	
	-- first, calculate widths of the labels
	
	local labels_width = {}
	if automatic_spacing then
		print("Do hard work")
		
		-- first add all labels to the model, I really couldn't care less where
		for i = 1,n do
			v_i = inv_arr[i]
			local pos = ipe.Vector(50, 50)
			local text = ipe.Text(model.attributes, v_i, pos)
			model:creation("Added label", text)
		end
		-- now run LaTeX
		success, what, result_code, logfile = model.doc:runLatex()
		if not success then
			model:warning("Latex did not compile! " .. what)
		end
		-- now retrieve the object's width and assign it to
		-- the corresponding labels
		for i = prev_Nobj+1,#p do
			v_i = inv_arr[i - prev_Nobj]
			label_obj = p[i]
			labels_width[v_i] = label_obj:get("width")
		end
		-- delete the labels added (I know this is not efficient, but
		-- I'm expecting a low number of labels)
		local cur_Nobj = #p
		while #p > cur_Nobj do
			p:remove(#p)
		end
	else
		-- assign width using the xoffset
		for i = 1,n do
			v_i = inv_arr[i]
			labels_width[v_i] = xoffset
		end
	end
	
	-- second, add the labels, the marks (black dots), and the labels
	
	local xcoords = {}
	for i = 1,n do
		v_i = inv_arr[i]
		
		-- calculate x_coord for v_i
		if i == 1 then
			xcoords[v_i] = xstart
		else
			v_i_1 = inv_arr[i - 1]
			local x_plus_width = xcoords[v_i_1] + labels_width[v_i_1]
			xcoords[v_i] = next_multiple_four(x_plus_width) + 4
		end
		
		-- create the text label for the vertices with the correct position
		local pos = ipe.Vector(xcoords[v_i] - 4, ycoord - 12)
		local text = ipe.Text(model.attributes, v_i, pos)
		model:creation("Added label", text)
		
		-- create the mark
		mark_pos = ipe.Vector(xcoords[v_i], ycoord)
		mark = ipe.Reference(model.attributes, "mark/disk(sx)", mark_pos)
		model:creation("Added mark", mark)
		
		-- create the text label for the positions
		local contents = ""
		if uses_zero then
			contents = tostring(i - 1)
		else
			contents = tostring(i)
		end
		local pos = ipe.Vector(xcoords[v_i] - 4, ycoord - 20)
		local text = ipe.Text(model.attributes, contents, pos)
		model:creation("Added label", text)
	end
	
	-- third, add a rectangle around the root vertex, if any
	
	if root_vertex ~= nil then
		R = inv_arr[root_vertex]
		local left_point = ipe.Vector(xcoords[R] - 4, ycoord)
		local right_point = ipe.Vector(xcoords[R] + 4, ycoord)
		add_arc(model, left_point, right_point)
		add_arc(model, right_point, left_point)
	end
	
	-- fourth, add the arcs between the positions
	
	for p_i = 1,n do
		for p_j = p_i+1,n do
			if adj_matrix[p_i][p_j] == true then
				v_i = inv_arr[p_i]
				v_j = inv_arr[p_j]
				
				-- choose right and left points
				local right = nil
				local left = nil
				if arr[v_i] < arr[v_j] then
					left = ipe.Vector(xcoords[v_i], ycoord)
					right = ipe.Vector(xcoords[v_j], ycoord)
				else
					left = ipe.Vector(xcoords[v_j], ycoord)
					right = ipe.Vector(xcoords[v_i], ycoord)
				end
				-- add the arc to ipe
				add_arc(model, left, right)
			end
		end
	end
	
	-- fifth, select the objects created so that they can be
	-- moved easily
	
	p:deselectAll()
	for i = prev_Nobj+1,#p do
		p:setSelect(i, 1)
	end
end

------------------------------------------------------------------------
------------------------------------------------------------------------

function run(model)
	local d = ipeui.Dialog(
		model.ui:win(),
		"Graph input -- linear sequence or list of edges and arrangement"
	)
	
	--------------------------------------------------------------------
	-- construct the dialog
	
	-- LINEAR SEQUENCE   ##########################
	
	local row = 1
	d:add("label4", "label", {label="Linear sequence"}, row, 1)
	--                                            SPAN: from column 1 to column 4
	d:add("linear_sequence", "input", {}, row, 2, 1, 4)
	
	-- EDGE LIST         ##########################
	
	row = row + 1
	d:add("label1", "label", {label="Edge list"}, row, 1)
	d:add("edges", "input", {}, row, 2, 1, 4)
	
	-- ARRANGEMENT  ###########    INVERSE ARRANGEMENT  ###########
	
	row = row + 1
	d:add("label2", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement", "input", {}, row, 2)
	
	d:add("label3", "label", {label="Inv. Arrang."}, row, 3)
	d:add("inv_arrangement", "input", {}, row, 4)
	
	-- X OFFSET ##############   USE AUTOMATIC ALIGNMENT (HERE A CHECK BOX)
	
	row = row + 1
	d:add("label4", "label", {label="X offset"}, row, 1)
	d:add("xoffset", "input", {}, row, 2)
	
	d:add(
		"automatic_spacing",
		"checkbox",
		{label="Use automatic spacing"},
		row, 3,
	-- SPAN: from column 3 to column 4
	   3, 4)
	
	-- BUTTONS
	
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	--------------------------------------------------------------------
	
	-- "execute" the dialog
	if not d:execute() then
		return
	end
	
	-- in case some offset was given, check that it
	-- is a non-null numeric value
	local input_offset = d:get("xoffset")
	if input_offset ~= "" then
		xoffset = tonumber(input_offset)
		if xoffset == nil then
			model:warning("Input offset is not numerical.")
			return
		end
		if xoffset == 0 then
			model:warning("Input offset cannot be 0.")
			return
		end
	end
	
	-- parse and convert the data from the boxes
	local success, converted_data = parse_data(d, model)
	
	-- if errors were found...
	if success == false then
		return
	end
	
	-- from this point we can assume that the input data is formatted
	-- correctly, and that has been correctly retrieved into the
	-- variables above.
	
	draw_data(model, converted_data)
end
