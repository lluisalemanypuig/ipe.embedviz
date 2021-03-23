
function parse_data(d, model)
	-- retrieve the input data from the dialog
	local __head_vector = d:get("head_vector")
	local __edge_list = d:get("edge_list")
	local __arrangement = d:get("arrangement")
	local __inverse_arrangement = d:get("inverse_arrangement")
	local __vertex_labels = d:get("labels_list")
	local automatic_spacing = d:get("automatic_spacing")
	local calculate_D = d:get("calculate_D")
	
	-- 1. if there is a head vector, parse it
	local result_from_head_vector = nil
	if __head_vector ~= "" then
		local success, res = parse_head_vector(model, __head_vector)
		if not success then
			model:warning("Something failed while parsing the head vector.")
			return false
		end
		result_from_head_vector = res
	end
	
	-- 2. if there is a list of edges, parse it
	local result_from_edge_list = nil
	if __edge_list ~= "" then
		local success, res = parse_edge_list(model, __edge_list)
		if not success then
			model:warning("Something failed while parsing the edge list.")
			return false
		end
		result_from_edge_list = res
	end
	
	local has_head_vector = (result_from_head_vector ~= nil)
	local has_edge_list = (result_from_edge_list ~= nil)
	
	-- ensure there is only one source of data
	if has_head_vector and has_edge_list then
		model:warning("Can't give head vector and edge list at the same time")
		return false
	end
	-- ensure there is at least one source of data
	if not has_head_vector and not has_edge_list then
		model:warning("Missing both head vector and list of edges. I need, at least, one of the two.")
		return false
	end
	
	-- number of vertices of the graph
	local n = nil
	if has_head_vector then
		n = result_from_head_vector["n"]
	else
		n = result_from_edge_list["n"]
	end
	
	-- 3. If there is a linear arrangement, parse it
	local result_from_arrangement = nil
	if __arrangement ~= "" then
		local success, res = parse_linear_arrangement(model, n, __arrangement)
		if not success then
			model:warning("Something failed while parsing the linear arrangement.")
			return false
		end
		result_from_arrangement = res
	end
	
	-- 4. If there is an inverse linear arrangement, parse it
	local result_from_inverse_arrangement = nil
	if __inverse_arrangement ~= "" then
		local success, res = parse_inverse_linear_arrangement(model, n, __inverse_arrangement)
		if not success then
			model:warning("Something failed while parsing the inverse linear arrangement.")
			return false
		end
		result_from_inverse_arrangement = res
	end
	
	-- 5. Parse vertex labels
	local result_from_vertex_labels = nil
	if __vertex_labels ~= "" then
		local success, res = parse_vertex_labels(model, __vertex_labels)
		if not success then
			model:warning("Something failed while parsing the vertex labels.")
			return false
		end
		result_from_vertex_labels = res
	end
	
	local has_arrangement = (result_from_arrangement ~= nil)
	local has_inverse_arrangement = (result_from_inverse_arrangement ~= nil)
	local has_vertex_labels = (result_from_vertex_labels ~= nil)
	
	-- build vertex labels
	local INTvertex_to_STRvertex = {}
	if has_vertex_labels then
		local user_labels = result_from_vertex_labels["INTvertex_to_STRvertex"]
		for i = 1,n do
			if user_labels[i] ~= nil then
				INTvertex_to_STRvertex[i] = user_labels[i]
			else
				-- missing label
				INTvertex_to_STRvertex[i] = "$\\star$"
			end
		end
	else
		for i = 1,n do
			INTvertex_to_STRvertex[i] = tostring(i)
		end
	end
	
	if has_arrangement and has_inverse_arrangement then
		-- ensure that the arrangement and the inverse arrangement agree
		local A_arrangement = result_from_arrangement["arrangement"]
		local B_arrangement = result_from_inverse_arrangement["arrangement"]
		local msg = ""
		for i = 1,n do
			if A_arrangement[i] ~= B_arrangement[i] then
				msg = msg .. "\n* Vertex " .. tostring(i) .. " is mapped to different positions.\n    - Arrangement maps it to '" .. tostring(A_arrangement[i]) .. "'.\n    - Inverse arrangement maps it to '" .. tostring(B_arrangement[i]) .. "'."
			end
		end
		if msg ~= "" then
			model:warning("Warnings:" .. msg)
			return false
		end
	end
	
	-- case 1: draw a head vector
	if has_head_vector and not has_edge_list then
		
		--[[
		HEAD VECTOR +
			0
		--]]
		if not has_arrangement and not has_inverse_arrangement then
			return
				true,
				{
					n 						= result_from_head_vector["n"],
					arrangement 			= result_from_head_vector["arrangement"],
					inverse_arrangement		= result_from_head_vector["inverse_arrangement"],
					adjacency_matrix		= result_from_head_vector["adjacency_matrix"],
					root_vertices			= result_from_head_vector["root_vertices"],
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
		
		--[[
		HEAD VECTOR +
			arrangement
		--]]
		if has_arrangement and not has_inverse_arrangement then
			return
				true,
				{
					n						= result_from_head_vector["n"],
					arrangement				= result_from_arrangement["arrangement"],
					inverse_arrangement		= result_from_arrangement["inverse_arrangement"],
					adjacency_matrix		= result_from_head_vector["adjacency_matrix"],
					root_vertices			= result_from_head_vector["root_vertices"],
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
		
		--[[
		HEAD VECTOR +
			inverse arrangement
		--]]
		if not has_arrangement and has_inverse_arrangement then
			return
				true,
				{
					n						= result_from_head_vector["n"],
					arrangement				= result_from_inverse_arrangement["arrangement"],
					inverse_arrangement		= result_from_inverse_arrangement["inverse_arrangement"],
					adjacency_matrix		= result_from_head_vector["adjacency_matrix"],
					root_vertices			= result_from_head_vector["root_vertices"],
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
		
		--[[
		HEAD VECTOR +
			arrangement + inverse arrangement
		--]]
		if has_arrangement and has_inverse_arrangement then
			return
				true,
				{
					n						= result_from_head_vector["n"],
					arrangement				= result_from_arrangement["arrangement"],
					inverse_arrangement		= result_from_arrangement["inverse_arrangement"],
					adjacency_matrix		= result_from_head_vector["adjacency_matrix"],
					root_vertices			= result_from_head_vector["root_vertices"],
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
	end
	
	-- case 2: draw an edge list
	if not has_head_vector and has_edge_list then
		-- we can't (yet) indicate root vertices in an edge list
		local root_vertices = {}
		for i = 1,n do
			root_vertices[i] = false
		end
		
		--[[
		EDGE LIST +
			0
		--]]
		if not has_arrangement and not has_inverse_arrangement then
			-- build identity arrangement and inverse arrangement
			local arrangement = {}
			local inverse_arrangement = {}
			for i = 1,n do
				arrangement[i] = i
				inverse_arrangement[i] = i
			end
			return
				true,
				{
					n						= result_from_edge_list["n"],
					arrangement				= arrangement,
					inverse_arrangement		= inverse_arrangement,
					adjacency_matrix		= result_from_edge_list["adjacency_matrix"],
					root_vertices			= root_vertices,
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
		
		--[[
		EDGE LIST +
			arrangement
		--]]
		if has_arrangement and not has_inverse_arrangement then
			return
				true,
				{
					n						= result_from_edge_list["n"],
					arrangement				= result_from_arrangement["arrangement"],
					inverse_arrangement		= result_from_arrangement["inverse_arrangement"],
					adjacency_matrix		= result_from_edge_list["adjacency_matrix"],
					root_vertices			= root_vertices,
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
		
		--[[
		EDGE LIST +
			inverse arrangement
		--]]
		if not has_arrangement and has_inverse_arrangement then
			return
				true,
				{
					n						= result_from_edge_list["n"],
					arrangement				= result_from_inverse_arrangement["arrangement"],
					inverse_arrangement		= result_from_inverse_arrangement["inverse_arrangement"],
					adjacency_matrix		= result_from_edge_list["adjacency_matrix"],
					root_vertices			= root_vertices,
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
		
		--[[
		EDGE LIST +
			arrangement + inverse arrangement
		--]]
		if has_arrangement and has_inverse_arrangement then
			return
				true,
				{
					n						= result_from_edge_list["n"],
					arrangement				= result_from_arrangement["arrangement"],
					inverse_arrangement		= result_from_arrangement["inverse_arrangement"],
					adjacency_matrix		= result_from_edge_list["adjacency_matrix"],
					root_vertices			= root_vertices,
					automatic_spacing		= automatic_spacing,
					INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
					calculate_D				= calculate_D
				}
		end
	end
	
end
