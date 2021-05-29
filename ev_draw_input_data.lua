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
	--     this is actually a table that represents a SHAPE
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
	--     this is actually a table that represents a SHAPE
	local circle_as_curve = {type="ellipse", ipe.Matrix(radius, 0, 0, radius, center.x, center.y)}
	-- make Path object
	local path = ipe.Path(model.attributes, {circle_as_curve})
	
	-- ADD ARC
	model:creation("Added circle", path)
end

function calculate_vertices_xcoords
(
	model,
	n, inverse_arrangement,
	xstart,
	labels_width
)
	local xcoords = {}
	for i = 1,n do
		-- vertex index at position 'i'
		local idx_v = inverse_arrangement[i]
		
		-- calculate x_coord for v_i
		if i == 1 then
			local brut = xstart + labels_width[idx_v]/2
			xcoords[idx_v] = next_multiple_four(brut)
		else
			-- vertex index at position 'i-1'
			idx_v1 = inverse_arrangement[i - 1]
			local x_plus_width = xcoords[idx_v1] + labels_width[idx_v1]/2
			local brut = x_plus_width + labels_width[idx_v]/2
			
			xcoords[idx_v] = next_multiple_four(brut) + 4
		end
	end
	return xcoords
end
function calculate_labels_xcoords
(
	model,
	n, inverse_arrangement,
	xstart,
	labels_width
)
	local xcoords = {}
	for i = 1,n do
		-- vertex index at position 'i'
		local idx_v = inverse_arrangement[i]
		
		-- calculate x_coord for v_i
		if i == 1 then
			xcoords[idx_v] = next_multiple_four(xstart)
		else
			-- vertex index at position 'i-1'
			idx_v1 = inverse_arrangement[i - 1]
			local x_plus_width = xcoords[idx_v1] + labels_width[idx_v1]
			
			xcoords[idx_v] = next_multiple_four(x_plus_width) + 4
		end
	end
	return xcoords
end

function add_vertices_marks
(
	model,
	n, inverse_arrangement,
	xcoords, vertices_ycoord
)
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		local mark_pos = ipe.Vector(xcoords[idx_v], vertices_ycoord)
		local mark = ipe.Reference(model.attributes, "mark/disk(sx)", mark_pos)
		model:creation("Added mark", mark)
	end
end

function add_vertex_labels
(
	model,
	n, inverse_arrangement,
	INTvertex_to_STRvertex,
	xcoords, vertices_ycoord,
	labels_max_height, labels_max_depth
)
	local total_height = labels_max_height + labels_max_depth
	
	local labels_ycoord = next_multiple_four(vertices_ycoord - 4 - labels_max_height) - 4
	local positions_ycoord = next_multiple_four(labels_ycoord - total_height) - 4
	
	for i = 1,n do
		local idx_v = inverse_arrangement[i]
		
		-- create the text label for the vertices (first row!)
		local pos = ipe.Vector(xcoords[idx_v] - 4, labels_ycoord)
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
		local pos = ipe.Vector(xcoords[idx_v] - 4, positions_ycoord)
		local text = ipe.Text(model.attributes, contents, pos)
		model:creation("Added label", text)
	end
	
	return positions_ycoord
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
	local labels_width = data_to_be_drawn["labels_width"]
	local labels_height = data_to_be_drawn["labels_height"]
	local labels_depth = data_to_be_drawn["labels_depth"]
	local labels_max_height = data_to_be_drawn["labels_max_height"]
	local labels_max_depth = data_to_be_drawn["labels_max_depth"]
	
	local xstart = coordinates["xstart"]
	local vertices_ycoord = coordinates["ycoord"]
	
	-- 1. Calculate positions of every vertex (the marks),
	-- add labels and marks (black dots)
	local vertices_xcoords =
	calculate_vertices_xcoords
	(
		model,
		n, inverse_arrangement,
		xstart, labels_width
	)
	
	add_vertices_marks
	(
		model,
		n, inverse_arrangement,
		vertices_xcoords, vertices_ycoord
	)
	
	local labels_xcoords =
	calculate_labels_xcoords
	(
		model,
		n, inverse_arrangement,
		xstart, labels_width
	)
	
	local positions_ycoord =
	add_vertex_labels
	(
		model,
		n, inverse_arrangement,
		INTvertex_to_STRvertex,
		labels_xcoords, vertices_ycoord,
		labels_max_height, labels_max_depth
	)
	
	-- 2. Add a circle around every root vertex, if any
	circle_root_vertices
	(
		model,
		n,
		inverse_arrangement,
		root_vertices,
		vertices_xcoords, vertices_ycoord
	)
	
	-- 3. Add the arcs between the positions
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
	
	-- 4. Calculate metrics
	if calculate_D then
		local D = 0
		for v_i = 1,n do
			for v_j = v_i+1,n do
				if adjacency_matrix[v_i][v_j] then
					local length = 0
					if arrangement[v_i] < arrangement[v_j] then
						length = arrangement[v_j] - arrangement[v_i]
					else
						length = arrangement[v_i] - arrangement[v_j]
					end
					D = D + length
				end
			end
		end
		
		local pos = ipe.Vector(xstart - 4, positions_ycoord - 8)
		local str_D = "$D=" .. tostring(D) .. "$"
		local text = ipe.Text(model.attributes, str_D, pos)
		model:creation("Added label", text)
	end
	
	return max_diameter//2, positions_ycoord
end
