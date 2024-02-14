function bipartite_calculate_labels_xcoords
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

function bipartite_calculate_vertices_xcoords
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

function bipartite_add_vertex_and_position_labels
(
	model, n, inverse_arrangement,
	color_per_vertex, INTvertex_to_STRvertex,
	labels_xcoords, vertices_ycoord_y0, vertices_ycoord_y1,
	vertex_labels_width, vertex_labels_max_height, vertex_labels_max_depth,
	position_labels_width,
	automatic_spacing
)
	
	local total_height = vertex_labels_max_height + vertex_labels_max_depth
	
	local labels_ycoord_y0 = next_multiple_four(vertices_ycoord_y0 - 4 - vertex_labels_max_height) - 4
	local labels_ycoord_y1 = next_multiple_four(vertices_ycoord_y1 + 4 + vertex_labels_max_depth)
	
	local position_labels_ycoord_y0 = next_multiple_four(labels_ycoord_y0 - total_height) - 4
	local position_labels_ycoord_y1 = next_multiple_four(labels_ycoord_y1 + total_height) + vertex_labels_max_depth
	
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		
		-- create the text label for the vertices (first row!)
		local label_pos = nil
		if color_per_vertex[idx_v] == "red" then
			label_pos = ipe.Vector(labels_xcoords[idx_v], labels_ycoord_y0)
		else
			label_pos = ipe.Vector(labels_xcoords[idx_v], labels_ycoord_y1)
		end
		local str_v = INTvertex_to_STRvertex[idx_v]
		local text = ipe.Text(model.attributes, str_v, label_pos)
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
			x_coord = labels_xcoords[idx_v] + vertex_labels_width[idx_v]/2 - position_labels_width[idx_v]/2
		else
			x_coord = labels_xcoords[idx_v]
		end
		local pos_pos = ipe.Vector(x_coord, position_labels_ycoord_y0)
		
		local text = ipe.Text(model.attributes, contents, pos_pos)
		model:creation("Added label", text)
	end
	
	return position_labels_ycoord_y0, position_labels_ycoord_y1
end

function bipartite_add_vertices_marks
(
	model, n, inverse_arrangement,
	xcoords, vertices_ycoords,
	adjacency_matrix, color_per_vertex
)
	
	-- retrieve old stroke color
	local prev_stroke_color = model.attributes["stroke"]
	
	-- draw vertices
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		model.attributes["stroke"] = color_per_vertex[idx_v]
		add_mark(model, ipe.Vector(xcoords[idx_v], vertices_ycoords[idx_v]))
	end
	
	-- set color properties back to normal
	model.attributes["stroke"] = prev_stroke_color
end

-- Draw the data given in the input.
function bipartite_draw_data(model, data_to_be_drawn, dimensions, coordinates)
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
	
	local height = coordinates["height"]
	local xstart = coordinates["xcoord"]
	local vertices_ycoord_y0 = coordinates["ycoord"]
	local vertices_ycoord_y1 = vertices_ycoord_y0 + height
	
	local vertices_ycoords = {}
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		if color_per_vertex[idx_v] == "red" then
			vertices_ycoords[idx_v] = vertices_ycoord_y0
		else
			vertices_ycoords[idx_v] = vertices_ycoord_y1
		end
	end
	
	-- 1. Calculate labels x-coordinates ...
	local labels_xcoords =
	bipartite_calculate_labels_xcoords
	(
		model, n, inverse_arrangement,
		xstart, vertex_labels_width,
		automatic_spacing
	)
	-- ... add vertex labels
	local position_labels_ycoord_y0, position_labels_ycoord_y1 =
	bipartite_add_vertex_and_position_labels
	(
		model, n, inverse_arrangement,
		color_per_vertex, INTvertex_to_STRvertex,
		labels_xcoords, vertices_ycoord_y0, vertices_ycoord_y1,
		vertex_labels_width, vertex_labels_max_height, vertex_labels_max_depth,
		position_labels_width,
		automatic_spacing
	)
	
	-- 2. Calculate positions of every vertex (marks) ...
	local vertices_xcoords =
	bipartite_calculate_vertices_xcoords
	(
		model, n, inverse_arrangement,
		xstart, labels_xcoords, vertex_labels_width,
		automatic_spacing
	)
	
	-- 3. Add a circle around every root vertex, if any
	circle_root_vertices
	(
		model, n, inverse_arrangement,
		root_vertices, vertices_xcoords, vertices_ycoords
	)
	
	-- 4. Add the line segments between the positions
	local max_diameter = 0
	for v_i = 1,n do
		for v_j = v_i+1,n do
			if adjacency_matrix[v_i][v_j] or adjacency_matrix[v_j][v_i] then

				-- choose segment points
				local P = ipe.Vector(vertices_xcoords[v_i], vertices_ycoords[v_i])
				local Q = ipe.Vector(vertices_xcoords[v_j], vertices_ycoords[v_j])
				
				add_segment(model, P, Q)
			end
		end
	end
	
	-- 5. Calculate minimum and maximum x-coordinates of this embedding
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
	
	-- 6. Draw visual guides (line segments)
	
	local xoffset = vertex_labels_max_width/2
	add_segment(model, ipe.Vector(min_x - xoffset, vertices_ycoord_y0), ipe.Vector(max_x + xoffset, vertices_ycoord_y0))
	add_segment(model, ipe.Vector(min_x - xoffset, vertices_ycoord_y1), ipe.Vector(max_x + xoffset, vertices_ycoord_y1))
	
	-- ... add vertices (marks)
	bipartite_add_vertices_marks
	(
		model, n, inverse_arrangement,
		vertices_xcoords, vertices_ycoords,
		adjacency_matrix, color_per_vertex
	)
	
	-- 7. Calculate metrics
	if calculate_C then
		local total_height = vertex_labels_max_height + vertex_labels_max_depth
		local y = next_multiple_four(vertices_ycoord_y0 - 4 - vertex_labels_max_height) - 4
		y = next_multiple_four(y - total_height) - 4
		y = next_multiple_four(y - total_height) - 4
		
		bipartite_number_of_edge_crossings(model, n, adjacency_matrix, arrangement, color_per_vertex, xstart + 4, y)
	end
	
	return (max_x - min_x)
end
