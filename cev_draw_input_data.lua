function circular_add_vertices_marks(model, n, vertices_xcoords, vertices_ycoords, color_per_vertex)

	-- retrieve old stroke color
	local prev_stroke_color = model.attributes["stroke"]
	for i = 1,n do
		model.attributes["stroke"] = color_per_vertex[i]
		add_mark(model, ipe.Vector(vertices_xcoords[i], vertices_ycoords[i]))
	end
	
	-- set color properties back to normal
	model.attributes["stroke"] = prev_stroke_color
end

function circular_calculate_vertexlabels_coords
(
	n, inverse_arrangement,
	cx, cy, R, automatic_spacing
)
	local xcoords = {}
	local ycoords = {}
	if automatic_spacing then
		
	else
		for pos = 1,n do
			local idx_v = inverse_arrangement[pos]
			local radian = (2*3.141592/n)*(pos - 1) + 3.141592/2
			
			xcoords[idx_v] = (R + 12)*math.cos(radian) + cx
			ycoords[idx_v] = (R + 12)*math.sin(radian) + cy
		end
	end
	return xcoords, ycoords
end

function circular_calculate_positionlabels_coords
(
	n, inverse_arrangement,
	cx,cy,R, automatic_spacing
)
	local xcoords = {}
	local ycoords = {}
	if automatic_spacing then
		
	else
		for pos = 1,n do
			local idx_v = inverse_arrangement[pos]
			local radian = (2*3.141592/n)*(pos - 1) + 3.141592/2
			
			xcoords[idx_v] = (R + 24)*math.cos(radian) + cx
			ycoords[idx_v] = (R + 24)*math.sin(radian) + cy
		end
	end
	return xcoords, ycoords
end

-- Draw the data given in the input.
function circular_draw_data(model, data_to_be_drawn, dimensions, coordinates)
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
	
	-- circle's centre's coordinates
	local cx = coordinates["xcoord"]
	local cy = coordinates["ycoord"]
	-- circle's radius
	local R = coordinates["radius"]
	
	add_circle(model, ipe.Vector(cx,cy), R)
	
	-- calculate:
	--     - vertices' positions
	--     - vertices' labels' positions
	--     - vertices' position labels' positions
	
	local vertices_xcoords = {}
	local vertices_ycoords = {}
	
	for pos = 1,n do
		local idx_v = inverse_arrangement[pos]
		local radian = (2*3.141592/n)*(pos - 1) + 3.141592/2
		
		vertices_xcoords[idx_v] = R*math.cos(radian) + cx
		vertices_ycoords[idx_v] = R*math.sin(radian) + cy
	end
	
	local vertexlabels_xcoords = {}
	local vertexlabels_ycoords = {}
	vertexlabels_xcoords, vertexlabels_ycoords = 
		circular_calculate_vertexlabels_coords(n, inverse_arrangement, cx,cy,R, automatic_spacing)
	
	local positionlabels_xcoords = {}
	local positionlabels_ycoords = {}
	positionlabels_xcoords, positionlabels_ycoords = 
		circular_calculate_positionlabels_coords(n, inverse_arrangement, cx,cy,R, automatic_spacing)
	
	-- calculate height labels atop
	local height_labels_inbetween = 0
	local idx_1 = inverse_arrangement[1]
	height_labels_inbetween = height_labels_inbetween + vertex_labels_height[ idx_1 ]
	height_labels_inbetween = height_labels_inbetween + 4 -- separation
	height_labels_inbetween = height_labels_inbetween + position_labels_height[ idx_1 ]
	height_labels_inbetween = height_labels_inbetween*2
	
	-- add the vertex labels
	for v = 1,n do
		-- create the text label for the vertices (first row!)
		local pos = ipe.Vector(vertexlabels_xcoords[v], vertexlabels_ycoords[v])
		local str_v = INTvertex_to_STRvertex[v]
		local text = ipe.Text(model.attributes, str_v, pos)
		model:creation("Added label", text)
	end
	
	-- add the position labels
	for p = 1,n do
		local idx_v = inverse_arrangement[p]
		
		-- (x,y)-position of the text label
		local pos = ipe.Vector(positionlabels_xcoords[idx_v], positionlabels_ycoords[idx_v])
		
		-- create the text label for the vertices (second row!)
		local str_p = tostring(p)
		local text = ipe.Text(model.attributes, str_p, pos)
		
		model:creation("Added label", text)
	end
	
	-- Add the arcs between the positions
	local max_diameter = 0
	for v_i = 1,n do
		for v_j = v_i+1,n do
			if adjacency_matrix[v_i][v_j] or adjacency_matrix[v_j][v_i] then
				local length = 0
				
				local xi = vertices_xcoords[v_i]
				local yi = vertices_ycoords[v_i]
				local xj = vertices_xcoords[v_j]
				local yj = vertices_ycoords[v_j]
				add_segment(model, ipe.Vector(xi,yi), ipe.Vector(xj,yj))
			end
		end
	end
	
	-- add marks for the vertices
	circular_add_vertices_marks(model, n, vertices_xcoords, vertices_ycoords, color_per_vertex)
	
	-- circle the root vertices
	circle_root_vertices
	(
		model, n, inverse_arrangement,
		root_vertices, vertices_xcoords, vertices_ycoords
	)
	
	-- 5. Calculate metrics
	local ycoord_metric_labels = cy - R - 34
	if calculate_D then
		sum_of_edge_lengths(model, n, adjacency_matrix, arrangement, cx - R, ycoord_metric_labels)
		ycoord_metric_labels = ycoord_metric_labels - 8
		height_labels_inbetween = height_labels_inbetween + 10
	end
	
	if calculate_C then
		number_of_edge_crossings(model, n, adjacency_matrix, arrangement, cx - R, ycoord_metric_labels)
		height_labels_inbetween = height_labels_inbetween + 10
	end
	
	-- 6. Calculate width of this embedding
	local min_x = 99999999999
	local max_x = 0
	for p = 1,n do
		local idx_v = inverse_arrangement[p]
		if max_x < positionlabels_xcoords[idx_v] then
			max_x = positionlabels_xcoords[idx_v]
		end
		if min_x > positionlabels_xcoords[idx_v] then
			min_x = positionlabels_xcoords[idx_v]
		end
	end
	
	return height_labels_inbetween, (max_x - min_x)
end
