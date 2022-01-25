function get_from_dialog(model, d, n, arr_str, invarr_str)
	local __arrangement = d:get(arr_str)
	local __inverse_arrangement = d:get(invarr_str)
	
	local result_from_arrangement = nil
	local result_from_inverse_arrangement = nil
	
	if __arrangement ~= "" then
		local success, res = parse_linear_arrangement(model, n, __arrangement)
		if not success then
			model:warning("Something failed while parsing the linear arrangement.")
			return false
		end
		result_from_arrangement = res
	end
	
	if __inverse_arrangement ~= "" then
		local success, res = parse_inverse_linear_arrangement(model, n, __inverse_arrangement)
		if not success then
			model:warning("Something failed while parsing the inverse linear arrangement.")
			return false
		end
		result_from_inverse_arrangement = res
	end
	
	return
	{
		arrangement = result_from_arrangement,
		inverse_arrangement = result_from_inverse_arrangement
	}
end

function make_arrgmnt_invarrgmnt(
	idx,
	build_type, -- either "head_vector" or "edge_list"
	result_from_build,
	result_from_arrangement,
	result_from_inverse_arrangement,
	make_defaults
)
	
	if build_type ~= "head_vector" and build_type ~= "edge_list" then
		print("Internal error: wrong build type '" .. build_type .. "'.")
		return false
	end

	local has_arrangement = (result_from_arrangement ~= nil)
	local has_inverse_arrangement = (result_from_inverse_arrangement ~= nil)
	local n = result_from_build["n"]

	if has_arrangement and has_inverse_arrangement then
		-- ensure that the arrangement and the inverse arrangement agree
		local A_arrangement = result_from_arrangement["arrangement"]
		local B_arrangement = result_from_inverse_arrangement["arrangement"]
		local msg = ""
		for i = 1,n do
			if A_arrangement[i] ~= B_arrangement[i] then
				msg = msg .. "\n* Vertex " .. tostring(i) .. " is mapped to different positions.\n	- Arrangement maps it to '" .. tostring(A_arrangement[i]) .. "'.\n	- Inverse arrangement maps it to '" .. tostring(B_arrangement[i]) .. "'."
			end
		end
		if msg ~= "" then
			model:warning("Warnings in row " .. tostring(idx) .. ":" .. msg)
			return false
		end
	end

	-- 0 0
	if not has_arrangement and not has_inverse_arrangement then
		if make_defaults then
			-- head vector
			if build_type == "head_vector" then
				return true,
				{
					arrangement			= result_from_build["arrangement"],
					inverse_arrangement = result_from_build["inverse_arrangement"]
				}
			end

			-- edge_list
			local arrangement = {}
			local inverse_arrangement = {}
			for i = 1,n do
				arrangement[i] = i
				inverse_arrangement[i] = i
			end
			return true,
			{
				arrangement			= result_from_build["arrangement"],
				inverse_arrangement = result_from_build["inverse_arrangement"]
			}
		end

		-- nothin wrong, simply nothing to do
		return false
	end

	-- 1 0
	if has_arrangement and not has_inverse_arrangement then
		return true,
		{
			arrangement				= result_from_arrangement["arrangement"],
			inverse_arrangement		= result_from_arrangement["inverse_arrangement"]
		}
	end

	-- 0 1
	if not has_arrangement and has_inverse_arrangement then
		return true,
		{
			arrangement				= result_from_inverse_arrangement["arrangement"],
			inverse_arrangement		= result_from_inverse_arrangement["inverse_arrangement"]
		}
	end

	-- 1 1
	if has_arrangement and has_inverse_arrangement then
		return true,
		{
			arrangement				= result_from_arrangement["arrangement"],
			inverse_arrangement		= result_from_arrangement["inverse_arrangement"]
		}
	end
end

function parse_data(d, model)
	-- retrieve some of the input data from the dialog
	local __head_vector = d:get("head_vector")
	local __edge_list = d:get("edge_list")
	-- decoration data
	local __vertex_labels = d:get("labels_list")
	local __automatic_spacing = d:get("automatic_spacing")
	-- metrics
	local __calculate_D = d:get("calculate_D")
	local __calculate_C = d:get("calculate_C")
	local __bicolor_vertices = d:get("bicolor_vertices")
	-- what kind of arrangement is to be drawn
	local __draw_linear = d:get("linear_embedding")
	local __draw_circular = d:get("circular_embedding")
	local __draw_bipartite = d:get("bipartite_embedding")
	
	----------------------------------------------------------------------------
	-- -1. Ensure that at least one type of embedding is selected
	if not __draw_linear and not __draw_circular then
		model:warning("You must select at least one type of embedding to be drawn.")
		return false
	end
	
	----------------------------------------------------------------------------
	-- 0. In case some offset (or radius) were given, check that it is a valid numeric value
	local __xoffset = nil
	
	local __input_offset = d:get("xoffset")
	if __input_offset ~= "" then
		__xoffset = tonumber(__input_offset)
		if __xoffset == nil then
			model:warning("Input offset is not numeric.")
			return false
		end
		if __xoffset == 0 then
			model:warning("Input offset cannot be 0.")
			return false
		end
	end
	
	local __radius = nil
	local __input_radius = d:get("radius")
	if __input_radius ~= "" then
		__radius = tonumber(__input_radius)
		if __radius == nil then
			model:warning("Input radius is not numeric.")
			return false
		end
		if __radius == 0 then
			model:warning("Input radius cannot be 0.")
			return false
		end
	end
	
	----------------------------------------------------------------------------
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
	
	----------------------------------------------------------------------------
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
	
	----------------------------------------------------------------------------
	-- ensure there is only one source of data
	
	local has_head_vector = (result_from_head_vector ~= nil)
	local has_edge_list = (result_from_edge_list ~= nil)
	if has_head_vector and has_edge_list then
		model:warning("You can't use head vector and edge list at the same time")
		return false
	end
	-- ensure there is at least one source of data
	if not has_head_vector and not has_edge_list then
		model:warning("Missing both head vector and list of edges. I need, at least, one of the two.")
		return false
	end

	local build_type = ""
	local result_from_build = nil
	if has_head_vector and not has_edge_list then
		build_type = "head_vector"
		result_from_build = result_from_head_vector
	end
	if not has_head_vector and has_edge_list then
		build_type = "edge_list"
		result_from_build = result_from_edge_list
	end

	-- number of vertices of the graph
	local n = 0
	if has_head_vector then
		n = result_from_head_vector["n"]
	else
		n = result_from_edge_list["n"]
	end
	
	----------------------------------------------------------------------------
	-- 3. retrieve arrangements
	-- 4. retrieve inverse arrangements
	
	-- always retrieve the first arrangement
	local result_from_arrangement_1 = nil
	local result_from_inverse_arrangement_1 = nil
	local RES = get_from_dialog(model, d, n, "arrangement_1", "inverse_arrangement_1")
	result_from_arrangement_1 = RES["arrangement"]
	result_from_inverse_arrangement_1 = RES["inverse_arrangement"]
	
	local result_from_arrangement_2 = nil
	local result_from_inverse_arrangement_2 = nil
	local RES = get_from_dialog(model, d, n, "arrangement_2", "inverse_arrangement_2")
	result_from_arrangement_2 = RES["arrangement"]
	result_from_inverse_arrangement_2 = RES["inverse_arrangement"]
	
	local result_from_arrangement_3 = nil
	local result_from_inverse_arrangement_3 = nil
	local RES = get_from_dialog(model, d, n, "arrangement_3", "inverse_arrangement_3")
	result_from_arrangement_3 = RES["arrangement"]
	result_from_inverse_arrangement_3 = RES["inverse_arrangement"]
	
	local result_from_arrangement_4 = nil
	local result_from_inverse_arrangement_4 = nil
	local RES = get_from_dialog(model, d, n, "arrangement_4", "inverse_arrangement_4")
	result_from_arrangement_4 = RES["arrangement"]
	result_from_inverse_arrangement_4 = RES["inverse_arrangement"]
	
	local some_arrangement =
		(result_from_arrangement_1 ~= nil) or
		(result_from_inverse_arrangement_1 ~= nil) or
		(result_from_arrangement_2 ~= nil) or
		(result_from_inverse_arrangement_2 ~= nil) or
		(result_from_arrangement_3 ~= nil) or
		(result_from_inverse_arrangement_3 ~= nil) or
		(result_from_arrangement_4 ~= nil) or
		(result_from_inverse_arrangement_4 ~= nil)
	
	if has_edge_list and not some_arrangement then
		model:warning("When using the edge list you must specify at least one arrangement or an inverse arrangement.")
		return false
	end
	
	----------------------------------------------------------------------------
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
	
	local has_vertex_labels = (result_from_vertex_labels ~= nil)
	
	----------------------------------------------------------------------------
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

	local base_data = nil
	if has_head_vector and not has_edge_list then
		-- make base data
		base_data =
		{
			adjacency_matrix		= result_from_head_vector["adjacency_matrix"],
			root_vertices			= result_from_head_vector["root_vertices"]
		}
	elseif not has_head_vector and has_edge_list then
		-- we can't (yet) indicate root vertices in an edge list
		local root_vertices = {}
		for i = 1,n do
			root_vertices[i] = false
		end
		-- make base data
		base_data =
		{
			adjacency_matrix		= result_from_edge_list["adjacency_matrix"],
			root_vertices			= root_vertices
		}
	end
	
	-- data given explicitly by the user
	local is_row_1_explicit = d:get("arrangement_1") ~= "" or d:get("inverse_arrangement_1") ~= ""
	local is_row_2_explicit = d:get("arrangement_2") ~= "" or d:get("inverse_arrangement_2") ~= ""
	local is_row_3_explicit = d:get("arrangement_3") ~= "" or d:get("inverse_arrangement_3") ~= ""
	local is_row_4_explicit = d:get("arrangement_4") ~= "" or d:get("inverse_arrangement_4") ~= ""
	local num_explicit = bool_to_int(is_row_1_explicit) + bool_to_int(is_row_2_explicit) + bool_to_int(is_row_3_explicit) + bool_to_int(is_row_4_explicit)

	local result_arrangement_arrays = {
		result_from_arrangement_1, result_from_arrangement_2,
		result_from_arrangement_3, result_from_arrangement_4
	}
	local result_inverse_arrangement_arrays = {
		result_from_inverse_arrangement_1, result_from_inverse_arrangement_2,
		result_from_inverse_arrangement_3, result_from_inverse_arrangement_4
	}
	local make_defaults = {}
	make_defaults[1] = true
	if num_explicit > 0 and not is_row_1_explicit then
		make_defaults[1] = false
	end
	make_defaults[2] = false
	make_defaults[3] = false
	make_defaults[4] = false

		local size = 0
	local arrangement_array = {}
	local inverse_arrangement_array = {}

	for i = 1,4 do
		local succ, arr_invarr = make_arrgmnt_invarrgmnt(
			i,
			build_type,
			result_from_build,
			result_arrangement_arrays[i],
			result_inverse_arrangement_arrays[i],
			make_defaults[i]
		)
		if succ then
			size = size + 1
			arrangement_array[size] = arr_invarr["arrangement"]
			inverse_arrangement_array[size] = arr_invarr["inverse_arrangement"]
		end
	end

	return true,
	{
		xoffset					= __xoffset,
		radius					= __radius,
		n						= n,
		adjacency_matrix		= base_data["adjacency_matrix"],
		root_vertices			= base_data["root_vertices"],
		INTvertex_to_STRvertex	= INTvertex_to_STRvertex,
		automatic_spacing		= __automatic_spacing,
		calculate_D				= __calculate_D,
		calculate_C				= __calculate_C,
		bicolor_vertices		= __bicolor_vertices,
		draw_linear				= __draw_linear,
		draw_circular			= __draw_circular,
		draw_bipartite			= __draw_bipartite,
		num_arrangements		= size,
		arrangements			= arrangement_array,
		inverse_arrangements	= inverse_arrangement_array
	}
end
