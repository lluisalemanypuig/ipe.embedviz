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
