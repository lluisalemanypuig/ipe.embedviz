
function linear_calculate_labels_xcoords
(
	model, n, inverse_arrangement,
	xstart, vertex_labels_width, automatic_spacing
)
	local xcoords = {}
	if automatic_spacing then
		for i = 1,n do
			-- vertex index at position 'i'
			local idx_v = inverse_arrangement[i]
			
			-- calculate x_coord for v_i
			if i == 1 then
				xcoords[idx_v] = next_multiple_four(xstart)
			else
				-- vertex index at position 'i-1'
				idx_v1 = inverse_arrangement[i - 1]
				local x_plus_width = xcoords[idx_v1] + vertex_labels_width[idx_v1]
				
				xcoords[idx_v] = next_multiple_four(x_plus_width) + 4
			end
		end
	else
		for i = 1,n do
			-- vertex index at position 'i'
			local idx_v = inverse_arrangement[i]
			
			-- calculate x_coord for v_i
			if i == 1 then
				xcoords[idx_v] = next_multiple_four(xstart)
			else
				-- vertex index at position 'i-1'
				idx_v1 = inverse_arrangement[i - 1]
				local x_plus_width = xcoords[idx_v1] + vertex_labels_width[idx_v1]
				
				xcoords[idx_v] = next_multiple_four(x_plus_width)
			end
		end
	end
	return xcoords
end

function linear_calculate_vertices_xcoords
(
	model, n, inverse_arrangement,
	xstart, labels_xcoords, vertex_labels_width, automatic_spacing
)
	local xcoords = {}
	
	if automatic_spacing then
		for i = 1,n do
			-- vertex index at position 'i'
			local idx_v = inverse_arrangement[i]
			xcoords[idx_v] = labels_xcoords[idx_v] + vertex_labels_width[idx_v]/2
		end
	else
		for i = 1,n do
			-- vertex index at position 'i'
			local idx_v = inverse_arrangement[i]
			xcoords[idx_v] = labels_xcoords[idx_v]
			if i < 10 then
				xcoords[idx_v] = xcoords[idx_v] + 3
			else
				xcoords[idx_v] = xcoords[idx_v] + 6
			end
		end
	end
	
	return xcoords
end

function linear_add_vertices_marks
(
	model, n, inverse_arrangement,
	xcoords, vertices_ycoord,
	adjacency_matrix, color_per_vertex
)
	
	-- retrieve old stroke color
	local prev_stroke_color = model.attributes["stroke"]
	
	-- draw vertices
	for i = 1,n do
		model.attributes["stroke"] = color_per_vertex[i]
		add_mark(model, ipe.Vector(xcoords[i], vertices_ycoord))
	end
	
	-- set color properties back to normal
	model.attributes["stroke"] = prev_stroke_color
end

function linear_add_vertex_and_position_labels
(
	model,
	n, inverse_arrangement,
	INTvertex_to_STRvertex,
	xcoords, vertices_ycoord,
	vertex_labels_width, vertex_labels_max_height, vertex_labels_max_depth,
	position_labels_width,
	automatic_spacing
)
	local total_height = vertex_labels_max_height + vertex_labels_max_depth
	local labels_ycoord = next_multiple_four(vertices_ycoord - 4 - vertex_labels_max_height) - 4
	local position_labels_ycoord = next_multiple_four(labels_ycoord - total_height) - 4
	
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		
		-- create the text label for the vertices (first row!)
		local pos = ipe.Vector(xcoords[i], labels_ycoord)
		local str_v = INTvertex_to_STRvertex[i]
		local text = ipe.Text(model.attributes, str_v, pos)
		model:creation("Added label", text)
		
		-- create the text label for the positions (second row!)
		local contents = ""
		if uses_zero then
			contents = tostring(i - 1)
		else
			contents = tostring(i)
		end
		
		local x_coord = 0
		if automatic_spacing then
			x_coord =
			xcoords[idx_v] + vertex_labels_width[idx_v]/2 - position_labels_width[idx_v]/2
		else
			x_coord = xcoords[idx_v]
		end
		local pos = ipe.Vector(x_coord, position_labels_ycoord)
		local text = ipe.Text(model.attributes, contents, pos)
		model:creation("Added label", text)
	end
	
	return position_labels_ycoord
end

-- Draw the data given in the input.
function linear_draw_data(model, data_to_be_drawn, dimensions, coordinates)
	
	-- data to be drawn
	local n = data_to_be_drawn["n"]
	local arrangement = data_to_be_drawn["arrangement"]
	local inverse_arrangement = data_to_be_drawn["inverse_arrangement"]
	local adjacency_matrix = data_to_be_drawn["adjacency_matrix"]
	local root_vertices = data_to_be_drawn["root_vertices"]
	local INTvertex_to_STRvertex = data_to_be_drawn["INTvertex_to_STRvertex"]
	local automatic_spacing = data_to_be_drawn["automatic_spacing"]
	local calculate_D = data_to_be_drawn["calculate_D"]
	local calculate_C = data_to_be_drawn["calculate_C"]
	local color_per_vertex = data_to_be_drawn["color_per_vertex"]
	
	local vertex_labels_width = dimensions["vertex_labels_width"]
	local vertex_labels_height = dimensions["vertex_labels_height"]
	local vertex_labels_depth = dimensions["vertex_labels_depth"]
	local vertex_labels_max_width = dimensions["vertex_labels_max_width"]
	local vertex_labels_max_height = dimensions["vertex_labels_max_height"]
	local vertex_labels_max_depth = dimensions["vertex_labels_max_depth"]
	
	local position_labels_width = dimensions["position_labels_width"]
	local position_labels_height = dimensions["position_labels_height"]
	local position_labels_depth = dimensions["position_labels_depth"]
	local position_labels_max_width = dimensions["position_labels_max_width"]
	local position_labels_max_height = dimensions["position_labels_max_height"]
	local position_labels_max_depth = dimensions["position_labels_max_depth"]
	
	local xstart = coordinates["xcoord"]
	local vertices_ycoord = coordinates["ycoord"]
	
	-- 1. Calculate labels x-coordinates ...
	local labels_xcoords =
	linear_calculate_labels_xcoords
	(
		model, n, inverse_arrangement,
		xstart, vertex_labels_width,
		automatic_spacing
	)
	-- ... add vertex labels
	local position_labels_ycoord =
	linear_add_vertex_and_position_labels
	(
		model, n, inverse_arrangement,
		INTvertex_to_STRvertex,
		labels_xcoords, vertices_ycoord,
		vertex_labels_width, vertex_labels_max_height, vertex_labels_max_depth,
		position_labels_width,
		automatic_spacing
	)
	
	-- 2. Calculate positions of every vertex (marks) ...
	local vertices_xcoords =
	linear_calculate_vertices_xcoords
	(
		model, n, inverse_arrangement,
		xstart, labels_xcoords, vertex_labels_width,
		automatic_spacing
	)
	
	-- 3. Add a circle around every root vertex, if any
	if true then
		local vertices_ycoords = {}
		for i = 1,n do
			vertices_ycoords[i] = vertices_ycoord
		end
		circle_root_vertices
		(
			model, n, inverse_arrangement,
			root_vertices, vertices_xcoords, vertices_ycoords
		)
	end
	
	-- 4. Add the arcs between the positions
	local max_diameter = 0
	for v_i = 1,n do
		for v_j = v_i+1,n do
			if adjacency_matrix[v_i][v_j] or adjacency_matrix[v_j][v_i] then
				local length = 0
				
				-- choose right and left points
				local right = nil
				local left = nil
				if arrangement[v_i] < arrangement[v_j] then
					left = ipe.Vector(vertices_xcoords[v_i], vertices_ycoord)
					right = ipe.Vector(vertices_xcoords[v_j], vertices_ycoord)
					
					length = vertices_xcoords[v_j] - vertices_xcoords[v_i]
				else
					left = ipe.Vector(vertices_xcoords[v_j], vertices_ycoord)
					right = ipe.Vector(vertices_xcoords[v_i], vertices_ycoord)
					
					length = vertices_xcoords[v_i] - vertices_xcoords[v_j]
				end
				
				if max_diameter < length then
					max_diameter = length
				end
				
				-- add the arc to ipe
				local mirror_arc_for_correct_direction_of_arrows
				if adjacency_matrix[v_i][v_j] and adjacency_matrix[v_j][v_i] then
					mirror_arc_for_correct_direction_of_arrows = false
				elseif adjacency_matrix[v_i][v_j] then
					mirror_arc_for_correct_direction_of_arrows = true
				else
					mirror_arc_for_correct_direction_of_arrows = false
				end
				
				add_arc(model, left, right, mirror_arc_for_correct_direction_of_arrows)
			end
		end
	end
	
	-- ... add vertices (marks)
	linear_add_vertices_marks
	(
		model, n, inverse_arrangement,
		vertices_xcoords, vertices_ycoord,
		adjacency_matrix, color_per_vertex
	)
	
	-- 5. Calculate metrics
	if calculate_D then
		sum_of_edge_lengths(model, n, adjacency_matrix, arrangement, xstart + 4, position_labels_ycoord - 8)
		position_labels_ycoord = position_labels_ycoord - 8
	end
	
	if calculate_C then
		number_of_edge_crossings(model, n, adjacency_matrix, arrangement, xstart + 4, position_labels_ycoord - 8)
		position_labels_ycoord = position_labels_ycoord - 8
	end
	
	-- 6. Calculate width of this embedding
	local min_x = 9999999999
	local max_x = 0
	for i = 1,n do
		if max_x < vertices_xcoords[i] then
			max_x = vertices_xcoords[i]
		end
		if min_x > vertices_xcoords[i] then
			min_x = vertices_xcoords[i]
		end
	end
	
	return max_diameter//2, position_labels_ycoord, (max_x - min_x)
end
