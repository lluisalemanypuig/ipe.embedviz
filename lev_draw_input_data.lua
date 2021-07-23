local function bounding_box(p)
	local box = ipe.Rect()
	for i,obj,sel,layer in p:objects() do
		if sel then box:add(p:bbox(i)) end
	end
	return box
end

function midpoint(x1,x2)
	local midx = (x1.x + x2.x)/2
	local midy = (x1.y + x2.y)/2
	return ipe.Vector(midx, midy)
end

function add_arc(model, left, right, mirror_arc)
	-- MAKE ARC
	
	-- arc's center
	local C = midpoint(left, right)
	-- radius of the arc (assumes that the points' location only varies in x)
	local r = right.x - C.x
	-- make matrix of the arc
	local matrix_arc = ipe.Arc(ipe.Matrix(r, 0, 0, r, C.x, C.y), right,left)
	-- prepare binding
	local arc_as_table = {type="arc", right,left, arc = matrix_arc}
	--    this is actually a table that represents a SHAPE
	local arc_as_curve = {type="curve", closed = false, arc_as_table}
	-- make Path object
	local path = ipe.Path(model.attributes, {arc_as_curve})
	
	-- ADD ARC
	model:creation("Added arc", path)
	
	if mirror_arc then
		-- mirror the arc if needed
		local matrix = ipe.Matrix(-1, 0, 0, 1, 0, 0)
		local p = model:page()
		local origin
		if model.snap.with_axes then
			origin = model.snap.origin
		else
			local box = bounding_box(p)
			origin = 0.5 * (box:bottomLeft() + box:topRight())
		end
		local transform_matrix = ipe.Translation(origin) * matrix * ipe.Translation(-origin)
		
		local p = model:page()
		p:transform(#p, transform_matrix)
	end
end

function add_circle(model, center, radius)
	-- MAKE CIRCLE
	
	-- prepare binding
	--	 this is actually a table that represents a SHAPE
	local circle_as_curve = {type="ellipse", ipe.Matrix(radius, 0, 0, radius, center.x, center.y)}
	-- make Path object
	local path = ipe.Path(model.attributes, {circle_as_curve})
	
	-- ADD ARC
	model:creation("Added circle", path)
end

function calculate_labels_xcoords
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

function calculate_vertices_xcoords
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

function add_vertices_marks
(
	model, n, inverse_arrangement,
	xcoords, vertices_ycoord,
	adjacency_matrix, bicolor_vertices
)
	local color_per_vertex = {}
	for i = 1,n do
		color_per_vertex[i] = "black"
	end
	
	-- bicolor the vertices of the graph, if possible
	if bicolor_vertices then
		color_per_vertex[1] = "red"
		
		local q = Queue.new()
		Queue.push_right(q, 1)
		while Queue.size(q) > 0 do
			local u = Queue.pop_left(q)
			
			for j = 1,n do
				if adjacency_matrix[u][j] or adjacency_matrix[j][u] then
					if color_per_vertex[j] == "black" then
						if color_per_vertex[u] == "red" then
							color_per_vertex[j] = "green"
						else
							color_per_vertex[j] = "red"
						end
						Queue.push_right(q, j)
					end
				end
			end
		end
	end
	
	-- retrieve old stroke color
	local prev_stroke_color = model.attributes["stroke"]
	
	-- draw vertices
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		model.attributes["stroke"] = color_per_vertex[idx_v]
		local mark_pos = ipe.Vector(xcoords[idx_v], vertices_ycoord)
		local mark = ipe.Reference(model.attributes, "mark/disk(sx)", mark_pos)
		model:creation("Added mark", mark)
	end
	
	-- set color properties back to normal
	model.attributes["stroke"] = prev_stroke_color
end

function add_vertex_and_position_labels
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
		local pos = ipe.Vector(xcoords[idx_v], labels_ycoord)
		local str_v = INTvertex_to_STRvertex[idx_v]
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

function circle_root_vertices
(
	model,
	n, inverse_arrangement,
	root_vertices,
	xcoords, vertices_ycoord
)
	for i = 1,n do
		local v_i = inverse_arrangement[i]
		if root_vertices[v_i] then
			add_circle(model, ipe.Vector(xcoords[v_i], vertices_ycoord), 4)
		end
	end
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
function draw_data(model, data_to_be_drawn, coordinates)
	-- properties of this drawing
	
	local drawing_height = 0
	
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
	local bicolor_vertices = data_to_be_drawn["bicolor_vertices"]
	
	local vertex_labels_width = data_to_be_drawn["vertex_labels_width"]
	local vertex_labels_height = data_to_be_drawn["vertex_labels_height"]
	local vertex_labels_depth = data_to_be_drawn["vertex_labels_depth"]
	local vertex_labels_max_width = data_to_be_drawn["vertex_labels_max_width"]
	local vertex_labels_max_height = data_to_be_drawn["vertex_labels_max_height"]
	local vertex_labels_max_depth = data_to_be_drawn["vertex_labels_max_depth"]
	
	local position_labels_width = data_to_be_drawn["position_labels_width"]
	local position_labels_height = data_to_be_drawn["position_labels_height"]
	local position_labels_depth = data_to_be_drawn["position_labels_depth"]
	local position_labels_max_width = data_to_be_drawn["position_labels_max_width"]
	local position_labels_max_height = data_to_be_drawn["position_labels_max_height"]
	local position_labels_max_depth = data_to_be_drawn["position_labels_max_depth"]
	
	local xstart = coordinates["xstart"]
	local vertices_ycoord = coordinates["ycoord"]
	
	-- 1. Calculate labels x-coordinates ...
	local labels_xcoords =
	calculate_labels_xcoords
	(
		model, n, inverse_arrangement,
		xstart, vertex_labels_width,
		automatic_spacing
	)
	-- ... add vertex labels
	local position_labels_ycoord =
	add_vertex_and_position_labels
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
	calculate_vertices_xcoords
	(
		model, n, inverse_arrangement,
		xstart, labels_xcoords, vertex_labels_width,
		automatic_spacing
	)
	-- ... add vertices (marks)
	add_vertices_marks
	(
		model, n, inverse_arrangement,
		vertices_xcoords, vertices_ycoord,
		adjacency_matrix, bicolor_vertices
	)
	
	-- 3. Add a circle around every root vertex, if any
	circle_root_vertices
	(
		model, n, inverse_arrangement,
		root_vertices, vertices_xcoords, vertices_ycoord
	)
	
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
	
	local edges = {}
	if calculate_D or calculate_C then
		-- retrieve all edges
		for v_i = 1,n do
			for v_j = v_i+1,n do
				if adjacency_matrix[v_i][v_j] then
					table.insert(edges, {v_i,v_j})
				end
			end
		end
	end
	
	-- 5. Calculate metrics
	if calculate_D then
		local D = 0
		
		for i = 1,#edges do
			e = edges[i]
			v_i = e[1]
			v_j = e[2]
			local length = 0
			if arrangement[v_i] < arrangement[v_j] then
				length = arrangement[v_j] - arrangement[v_i]
			else
				length = arrangement[v_i] - arrangement[v_j]
			end
			D = D + length
		end
		
		position_labels_ycoord = position_labels_ycoord - 8
		local pos = ipe.Vector(xstart + 4, position_labels_ycoord)
		local str_D = "$D=" .. tostring(D) .. "$"
		local text = ipe.Text(model.attributes, str_D, pos)
		model:creation("Added sum of edge lengths label", text)
	end
	
	if calculate_C then
		local C = 0
		
		-- it's quadratic time!
		for i = 1,#edges do
			local e1 = edges[i]
			local s = e1[1]
			local t = e1[2]
			for j = i+1,#edges do
				local e2 = edges[j]
				local u = e2[1]
				local v = e2[2]
				-- only independent edges can cross
				if not (s == u or s == v or t == u or t == v) then
					local pos_s = arrangement[s]
					local pos_t = arrangement[t]
					local pos_u = arrangement[u]
					local pos_v = arrangement[v]
					
					if pos_s < pos_t then
						-- pos_s < pos_t
						if pos_u < pos_v then
							-- pos_s < pos_t * -- pos_u < pos_v
							C = C +
								bool_to_int(
								(pos_s < pos_u and pos_u < pos_t and pos_t < pos_v) or
								(pos_u < pos_s and pos_s < pos_v and pos_v < pos_t)
								)
						else
							-- pos_s < pos_t * -- pos_v < pos_u
							C = C +
								bool_to_int(
								(pos_s < pos_v and pos_v < pos_t and pos_t < pos_u) or
								(pos_v < pos_s and pos_s < pos_u and pos_u < pos_t)
								)
						end
					else
						-- pos_t < pos_s
						if pos_u < pos_v then
							-- pos_t < pos_s * -- pos_u < pos_v
							C = C +
								bool_to_int(
								(pos_t < pos_u and pos_u < pos_s and pos_s < pos_v) or
								(pos_u < pos_t and pos_t < pos_v and pos_v < pos_s)
								)
						else
							-- pos_t < pos_s * -- pos_v < pos_u
							C = C +
								bool_to_int(
								(pos_t < pos_v and pos_v < pos_s and pos_s < pos_u) or
								(pos_v < pos_t and pos_t < pos_u and pos_u < pos_s)
								)
						end
					end
				end
			end
		end
		
		position_labels_ycoord = position_labels_ycoord - 8
		local pos = ipe.Vector(xstart + 4, position_labels_ycoord)
		local str_C = "$C=" .. tostring(C) .. "$"
		local text = ipe.Text(model.attributes, str_C, pos)
		model:creation("Added number of crossings label", text)
	end
	
	return max_diameter//2, position_labels_ycoord
end
