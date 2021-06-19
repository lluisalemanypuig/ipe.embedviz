function next_multiple_four(f)
	ff = math.floor(f)
	return ff + 4 - ff%4
end

function bool_to_int(value)
	return value and 1 or 0
end

function table_length(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

function has_value(tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

-- functions to parse the input string
function find_valid(str, delims, i)
	while
		i <= #str and
		has_value(delims, string.sub(str, i,i))
	do
		if string.sub(str, i,i) == "\\" then
			i = i + 1
		end
		i = i + 1
	end
	return i
end
function find_invalid(str, delims, i)
	while
		i <= #str and
		not has_value(delims, string.sub(str, i,i))
	do
		if string.sub(str, i,i) == "\\" then
			i = i + 1
		end
		i = i + 1
	end
	return i
end

function find_first_trailing_space(str)
	local i = #str
	while string.sub(str, i,i) == " " do
		i = i - 1
	end
	return i + 1
end

function parse_input(input, delims)
	if delims == nil then
		delims = {",", "|", " "}
	end

	local INPUT = {}
	local i = find_valid(input, delims, 1)
	i = i - 1
	
	while i <= #input do
		local j = find_invalid(input, delims, i + 1)
		local word = string.sub(input, i+1, j - 1)
		
		if word ~= "" then
			local first_trailing_space = find_first_trailing_space(word)
			word = string.sub(word, 1, first_trailing_space-1)
			table.insert(INPUT, word)
		end
		i = find_invalid(input, delims, j)
	end
	return INPUT
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--[[
Parses a head vector

PARAMETERS
..........
* model : the IPE model, where to write the warnings, if any.
* __head_vector : the "raw" head vector, as taken from the dialog box.

RETURNS
.......

A pair (bool, map). The Boolean indicates success, the map contains:

* n : an integer value, the number of vertices of the graph

* arrangement : a table relating every vertex to its position in the sequence.
	This table must be indexed using integers, and the returned value is an
	integer number

	arrangement[u] = p
	-> 'u' is an integer,
	-> 'p' is an integer

* inverse_arrangement : a table relating every position in the sequence to its
	vertex. This table must be indexed using integers, and the returned value is
	an integer number

	inverse_arrangement[p] = u
	-> 'p' is an integer
	-> 'u' is an integer,

* adjacency_matrix : the adjacency matrix of the graph described using the head
	vector. The matrix must be indexed using integer numbers. The value stored
	in each cell is a Boolean value.

	adjacency_matrix[i][j] = true <-> the vertices i and j are adjacent in the
		graph.

* root_vertices : a table relating vertices to whether they are root vertices or
	not. This table must be indexed using integer numbers. The returned value is
	a Boolean value.
	
	root_vertices[u] = true <-> vertex u is a root vertex
--]]
function parse_head_vector(model, __head_vector)
	local head_vector = parse_input(__head_vector)
	
	-- number of vertices
	local n = #head_vector
	
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
	local root_vertices = {}
	
	for position = 1,n do
		local parent_str = head_vector[position]
		local parent_position = tonumber(parent_str)
		
		if parent_position == nil then
			model:warning("Non-numeric values " .. parent_str .. " are not allowed in the linear sequence.")
			return false
		end
		if parent_position < 0 then
			model:warning("Negative values " .. parent_str .. " are not allowed in the linear sequence.")
			return false
		end
		if parent_position == parent then
			model:warning("Found a self loop at position " .. tostring(position))
			return false
		end
		
		if parent_position == 0 then
			root_vertices[position] = true
		
		elseif parent_position > 0 then
			root_vertices[position] = false
			
			--adj_matrix[position][parent_position] = true
			adj_matrix[parent_position][position] = true
		end
		
		-- arrangement and inverse arrangement are the identity function
		func_pi[position] = position
		func_inv_pi[position] = position
	end
	
	-- success
	return
		true,
		{
			n = n,
			arrangement = func_pi,
			inverse_arrangement = func_inv_pi,
			adjacency_matrix = adj_matrix,
			root_vertices = root_vertices
		}
end

--[[
Parses an edge list

PARAMETERS
..........
* model : the IPE model, where to write the warnings, if any.
* __edge_list : the "raw" edge list, as taken from the dialog box.

RETURNS
.......

A pair (bool, map). The Boolean indicates success, the map contains:
* n : an integer value, the number of vertices of the graph

* adjacency_matrix : the adjacency matrix of the graph described using the edge
	list. The matrix must be indexed using integers. The value stored
	in each cell is a Boolean value.

	adjacency_matrix[i][j] = true <-> the vertices i and j are adjacent in the
		graph.
--]]
function parse_edge_list(model, __edge_list)
	local edge_list = parse_input(__edge_list)
	
	-- twice the number of edges
	local mx2 = #edge_list

	-- the number of elements in edge_list must be even
	if mx2%2 == 1 then
		model:warning("List of edges contains an odd number of elements.")
		return false
	end
	
	-- minimum vertex index value
	local least_idx_value = 99999
	local largest_idx_value = 0
	
	----------------------------------------------------------------------------
	-- ensure that every index is a non-integer value,
	-- construct the vertex set
	local vertex_set = {}
	for i = 1,mx2,2 do
		-- vertices as strings
		local v1_str = edge_list[i]
		local v2_str = edge_list[i + 1]
		if vertex_set[v1_str] == nil then vertex_set[v1_str] = true end
		if vertex_set[v2_str] == nil then vertex_set[v2_str] = true end
	end
	-- sort the vertex set lexicographically
	local a = {}
	for i,v in pairs(vertex_set) do
		table.insert(a, i)
		
		local idx_v = tonumber(i)
		if idx_v == nil or idx_v < 0 then
			model:warning("Value " .. v .. " is not a valid non-negative integer number")
		end
		
		if least_idx_value > idx_v then
			least_idx_value = idx_v
		end
		if largest_idx_value < idx_v then
			largest_idx_value = idx_v
		end
	end
	table.sort(a,
		function(s1,s2)
			if #s1 < #s2 then return true end
			if #s1 > #s2 then return false end
			return s1 < s2
		end
	)
	----------------------------------------------------------------------------
	
	-- map every string to an index using the (sorted) list of (string) vertices
	-- so that we can build the adjacency matrix later
	local length_vertex_set = table_length(vertex_set)
	local STRvertex_to_INTvertex = {}
	for i = 1,length_vertex_set do
		local str_v1 = a[i]
		local idx_v1 = tonumber(str_v1)
		if least_idx_value == 0 then
			idx_v1 = idx_v1 + 1
		end
		
		STRvertex_to_INTvertex[str_v1] = idx_v1
	end
	
	-- the number of vertices
	local n = largest_idx_value - least_idx_value + 1
	
	-- allocate adjacency matrix
	local adjacency_matrix = {}
	for i = 1,n do
		adjacency_matrix[i] = {}
		for j = 1,n do
			adjacency_matrix[i][j] = false
		end
	end
	
	-- fill adjacency matrix
	for i = 1,mx2,2 do
		-- 'v1' and 'v2' are strings
		local str_v1 = edge_list[i]
		local str_v2 = edge_list[i + 1]
		-- 'idx_v1' and 'idx_v2' are integers
		local idx_v1 = STRvertex_to_INTvertex[str_v1]
		local idx_v2 = STRvertex_to_INTvertex[str_v2]
		
		-- check correctness of edges
		if idx_v1 == idx_v2 then
			model:warning("Self-loop " .. "{" .. str_v1 .. "," .. str_v2 .. "}.")
			return false
		end
		
		-- if the edge was not added before, add it now to the matrix
		if not adjacency_matrix[idx_v1][idx_v2] then
			adjacency_matrix[idx_v1][idx_v2] = true
			adjacency_matrix[idx_v2][idx_v1] = true
		else
			model:warning("Multiedges were found {" .. str_v1 .. "," .. str_v2 .. "}.")
			return false
		end
	end
	
	-- success
	return
		true,
		{
			n = n,
			adjacency_matrix = adjacency_matrix
		}
end

--[[
Parses a linear arrangement

PARAMETERS
..........
* model : the IPE model, where to write the warnings, if any.
* N : number of vertices of the graph
* __arr : the "raw" arrangement, as taken from the dialog box.

RETURNS
.......

A pair (bool, map). The Boolean indicates success, the map contains:
* n : an integer value, the number of vertices of the graph

* arrangement : a table relating every vertex to its position in the sequence.
	This table must be indexed using integers, and the returned value is an
	integer number

	arrangement[u] = p
	-> 'u' is an integer
	-> 'p' is an integer

* inverse_arrangement : a table relating every position in the sequence to
	its vertex. This table must be indexed using integers, and the returned
	value is an integer number

	inverse_arrangement[p] = u
	-> 'p' is an integer
	-> 'u' is an integer
--]]
function parse_linear_arrangement(mdel, N, __arr)
	-- this is a "list" of strings
	local arrangement = parse_input(__arr)
	
	if arrangement[1] == "identity" then
		local func_pi = {}
		local func_inv_pi = {}
		for position = 1,N do
			func_pi[position] = position
			func_inv_pi[position] = position
		end

		-- success
		return
			true,
			{
				n = N,
				arrangement = func_pi,
				inverse_arrangement = func_inv_pi
			}
	end
	
	-- number of vertices
	local n = #arrangement
	
	if n ~= N then
		model:warning("Size of the arrangement '" .. tostring(n) .. "' is not equal to the number of vertices '" .. tostring(N) .. "'.")
		return false
	end
	
	-- actual linear arranagment and inverse linear arrangement functions
	local func_pi = {}
	local func_inv_pi = {}
	-- minimum position used for the vertices: used to normalise the positions
	-- to the range [1,n]
	local least_position_value = 9999
	
	-- ensure correctness of the input data
	local position_set = {}
	for vertex = 1,n do
		local position_str = arrangement[vertex]
		local position = tonumber(position_str)
		
		-- only non-negative integers!
		if position == nil or position < 0 then
			model:warning("Value " .. position_str .. " is not a valid non-negative integer number")
			return false
		end
		
		-- keep track of the least position
		if least_position_value > position then
			least_position_value = position
		end
		
		-- ensure no collisions of vertices to the same collision
		if position_set[position] == nil then
			position_set[position] = true
		else
			model:warning("Repeated position in arrangement: " .. position)
			return false
		end
	end
	
	-- construct the arrangement
	for vertex = 1,n do
		local position_str = arrangement[vertex]
		-- normalised position
		local position = tonumber(position_str) - (least_position_value - 1)
		
		-- pi[vertex] = position <-> position of 'vertex' is 'position'
		func_pi[vertex] = position
		-- inv_pi[position] = vertex <-> position of 'vertex' is 'position'
		func_inv_pi[position] = vertex
	end

	-- success
	return
		true,
		{
			n = n,
			arrangement = func_pi,
			inverse_arrangement = func_inv_pi
		}
end

--[[
Parses an inverse linear arrangement

PARAMETERS
..........
* model : the IPE model, where to write the warnings, if any.
* N : number of vertices of the graph
* __inv_arr : the "raw" inverse arrangement, as taken from the dialog box.

RETURNS
.......

A pair (bool, map). The Boolean indicates success, the map contains:
* n : an integer value, the number of vertices of the graph

* arrangement : a table relating every vertex to its position in the sequence.
	This table must be indexed using integers, and the returned value is an
	integer number

	arrangement[u] = p
	-> 'u' is an integer
	-> 'p' is an integer

* inverse_arrangement : a table relating every position in the sequence to
	its vertex. This table must be indexed using integers, and the returned
	value is an integer number

	inverse_arrangement[p] = u
	-> 'p' is an integer
	-> 'u' is an integer
--]]
function parse_inverse_linear_arrangement(model, N, __inv_arr)
	-- this is a "list" of strings
	local inverse_arrangement = parse_input(__inv_arr)
	
	if inverse_arrangement[1] == "identity" then
		local func_pi = {}
		local func_inv_pi = {}
		for position = 1,N do
			func_pi[position] = position
			func_inv_pi[position] = position
		end

		-- success
		return
			true,
			{
				n = N,
				arrangement = func_pi,
				inverse_arrangement = func_inv_pi
			}
	end
	
	-- number of vertices
	local n = #inverse_arrangement
	
	if n ~= N then
		model:warning("Size of the arrangement '" .. tostring(n) .. "' is not equal to the number of vertices '" .. tostring(N) .. "'.")
		return false
	end
	
	-- ensure correctness of the input data
	local vertex_set = {}
	local least_vertex_value = 9999
	for position = 1,n do
		local vertex_str = inverse_arrangement[position]
		local vertex = tonumber(vertex_str)
		
		-- only non-negative integers!
		if vertex == nil or vertex < 0 then
			model:warning("Value " .. vertex_str .. " is not a valid non-negative integer number")
			return false
		end
		
		-- keep track of the least position
		if least_vertex_value > vertex then
			least_vertex_value = vertex
		end
		
		-- ensure no collisions of vertices to the same collision
		if vertex_set[vertex] == nil then
			vertex_set[vertex] = true
		else
			model:warning("Repeated vertex in inverse arrangement: " .. vertex)
			return false
		end
	end
	
	-- construct the arrangement
	local func_pi = {}
	local func_inv_pi = {}
	for position = 1,n do
		local vertex_str = inverse_arrangement[position]
		-- normalised vertex
		local vertex = tonumber(vertex_str) - (least_vertex_value - 1)
		
		-- pi[vertex] = position <-> vertex of 'position' is 'vertex'
		func_pi[vertex] = position
		-- inv_pi[position] = vertex <-> vertex of 'position' is 'vertex'
		func_inv_pi[position] = vertex
	end

	-- success
	return
		true,
		{
			n = n,
			arrangement = func_pi,
			inverse_arrangement = func_inv_pi
		}
end

--[[
Parses the labels given for every vertex

PARAMETERS
..........
* model : the IPE model, where to write the warnings, if any.
* __vertex_labels : the "raw" vertex labels, as taken from the dialog box.

RETURNS
.......

* INTvertex_to_STRvertex : a table relating every vertex id to a string.
	The table must be referenced using integer values. The value stored in every
	cell is a string.

--]]
function parse_vertex_labels(model, __vertex_labels)
	-- this is a "list" of strings
	local vertex_labels = parse_input(__vertex_labels, {"&"})
	
	-- amount of labels given
	local num_labels = table_length(vertex_labels)
	
	local INTvertex_to_STRvertex = {}
	for i = 1,num_labels do
		INTvertex_to_STRvertex[i] = vertex_labels[i]
	end
	
	return true, {INTvertex_to_STRvertex = INTvertex_to_STRvertex}
end

function calculate_labels_dimensions
(
	model,
	automatic_spacing,
	n,
	INTvertex_to_STRvertex,
	xoffset
)
	local vertex_labels_width = {}
	local vertex_labels_height = {}
	local vertex_labels_depth = {}
	local position_labels_width = {}
	local position_labels_height = {}
	local position_labels_depth = {}
	
	if not automatic_spacing then
		-- assign width using the xoffset
		for idx_v = 1,n do
			vertex_labels_width[idx_v] = xoffset
			vertex_labels_height[idx_v] = 7
			vertex_labels_depth[idx_v] = 0
			
			if idx_v < 10 then
				position_labels_width[idx_v] = 4
			else
				position_labels_width[idx_v] = 6
			end
			position_labels_height[idx_v] = 7
			position_labels_depth[idx_v] = 0
		end
	else
		local p = model:page()
		
		-- first add all labels to the model, I really couldn't care less where
		local num_objects_initial = #p
		for idx_v = 1,n do
			local str_v = INTvertex_to_STRvertex[idx_v]
			local pos = ipe.Vector(50, 50)
			local text = ipe.Text(model.attributes, str_v, pos)
			model:creation("Added vertex label", text)
		end
		-- add the position numbers too!
		local num_objects_vertex_labels = #p
		for idx_v = 1,n do
			local str_v = tostring(idx_v)
			local pos = ipe.Vector(50, 50)
			local text = ipe.Text(model.attributes, str_v, pos)
			model:creation("Added position label", text)
		end
		
		-- now run LaTeX
		success, what, result_code, logfile = model.doc:runLatex()
		if not success then
			model:warning("Latex did not compile! Error message:\n\n" .. what .. "\n\nSee console for details.")
			print("***** WHAT *****")
			print(what)
			print("***** Result code *****")
			print(result_code)
			print("***** Log file *****")
			print(logifle)
		else
			-- this is needed if we don't want IPE to crash!
			model.ui:setResources(model.doc)
		end
		
		-- now retrieve the vertex labels's width, height and depth
		for i = num_objects_initial+1,#p do
			local idx_v = i - num_objects_initial
			width, height, depth = p[i]:dimensions()
			vertex_labels_width[idx_v] = width
			vertex_labels_height[idx_v] = height
			vertex_labels_depth[idx_v] = depth
		end
		-- now retrieve the position labels's width, height and depth
		for i = num_objects_vertex_labels+1,#p do
			local idx_v = i - num_objects_vertex_labels
			width, height, depth = p[i]:dimensions()
			position_labels_width[idx_v] = width
			position_labels_height[idx_v] = height
			position_labels_depth[idx_v] = depth
		end
		
		-- delete the labels added (this is not efficient, but
		-- we're expecting a low number of labels)
		while #p > num_objects_initial do
			p:remove(#p)
		end
	end
	
	local vertex_labels_max_width = 0
	local vertex_labels_max_height = 0
	local vertex_labels_max_depth = 0
	
	local position_labels_max_width = 0
	local position_labels_max_height = 0
	local position_labels_max_depth = 0
	for idx_v = 1,n do
		-- vertex labels
		local width_v = vertex_labels_width[idx_v]
		if vertex_labels_max_width < width_v then
			vertex_labels_max_width = width_v
		end
		
		local height_v = vertex_labels_height[idx_v]
		if vertex_labels_max_height < height_v then
			vertex_labels_max_height = height_v
		end
		
		local depth_v = vertex_labels_depth[idx_v]
		if vertex_labels_max_depth < depth_v then
			vertex_labels_max_depth = depth_v
		end
		
		-- position labels
		local width_v = position_labels_width[idx_v]
		if position_labels_max_width < width_v then
			position_labels_max_width = width_v
		end
		
		local height_v = position_labels_height[idx_v]
		if position_labels_max_height < height_v then
			position_labels_max_height = height_v
		end
		
		local depth_v = position_labels_depth[idx_v]
		if position_labels_max_depth < depth_v then
			position_labels_max_depth = depth_v
		end
	end
	
	return
		vertex_labels_width, vertex_labels_height, vertex_labels_depth,
		vertex_labels_max_width, vertex_labels_max_height, vertex_labels_max_depth,
		position_labels_width, position_labels_height, position_labels_depth,
		position_labels_max_width, position_labels_max_height, position_labels_max_depth
end
