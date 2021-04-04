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
	--     this is actually a table that represents a SHAPE
	local arc_as_curve = {type="curve", closed = false, arc_as_table}
	-- make Path object
	local path = ipe.Path(model.attributes, {arc_as_curve})
	
	-- ADD ARC
	model:creation("Added arc", path)
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
	local n = data_to_be_drawn["n"]
	local arrangement = data_to_be_drawn["arrangement"]
	local inverse_arrangement = data_to_be_drawn["inverse_arrangement"]
	local adjacency_matrix = data_to_be_drawn["adjacency_matrix"]
	local root_vertices = data_to_be_drawn["root_vertices"]
	local INTvertex_to_STRvertex = data_to_be_drawn["INTvertex_to_STRvertex"]
	local automatic_spacing = data_to_be_drawn["automatic_spacing"]
	local calculate_D = data_to_be_drawn["calculate_D"]
	
	local p = model:page()
	local prev_Nobj = #p
	
	local xoffset = coordinates["xoffset"]
	local xstart = coordinates["xstart"]
	local ycoord = coordinates["ycoord"]
	
	-- 1. calculate widths of the labels at every position of the arrangement
	
	local labels_width = {}
	if automatic_spacing then
		-- first add all labels to the model, I really couldn't care less where
		for i = 1,n do
			local idx_v = inverse_arrangement[i]
			
			local str_v = INTvertex_to_STRvertex[idx_v]
			local pos = ipe.Vector(50, 50)
			local text = ipe.Text(model.attributes, str_v, pos)
			model:creation("Added label", text)
		end
		-- now run LaTeX
		success, what, result_code, logfile = model.doc:runLatex()
		if not success then
			model:warning("Latex did not compile! " .. what)
		else
			-- this is needed if we don't want IPE to crash!
			model.ui:setResources(model.doc)
		end
		-- now retrieve the object's width and assign it to
		-- the corresponding labels
		for i = prev_Nobj+1,#p do
			local idx_v = inverse_arrangement[i-prev_Nobj]
			labels_width[idx_v] = p[i]:get("width")
		end
		-- delete the labels added (I know this is not efficient, but
		-- I'm expecting a low number of labels)
		while #p > prev_Nobj do
			p:remove(#p)
		end
	else
		-- assign width using the xoffset
		for i = 1,n do
			local idx_v = inverse_arrangement[i]
			labels_width[idx_v] = xoffset
		end
	end
	
	-- 2. Calculate positions of every vertex, add labels and marks (black dots)
	local xcoords = {}
	for i = 1,n do
		-- vertex index at position 'i'
		local idx_v = inverse_arrangement[i]
		
		-- calculate x_coord for v_i
		if i == 1 then
			xcoords[idx_v] = xstart
		else
			-- vertex index at position 'i-1'
			idx_v1 = inverse_arrangement[i - 1]
			local x_plus_width = xcoords[idx_v1] + labels_width[idx_v1]
			
			xcoords[idx_v] = next_multiple_four(x_plus_width) + 4
		end
		
		-- create the text label for the vertices with the correct position
		local pos = ipe.Vector(xcoords[idx_v] - 4, ycoord - 12)
		local str_v = INTvertex_to_STRvertex[idx_v]
		local text = ipe.Text(model.attributes, str_v, pos)
		model:creation("Added label", text)
		
		-- create the mark
		local mark_pos = ipe.Vector(xcoords[idx_v], ycoord)
		local mark = ipe.Reference(model.attributes, "mark/disk(sx)", mark_pos)
		model:creation("Added mark", mark)
		
		-- create the text label for the positions
		local contents = ""
		if uses_zero then
			contents = tostring(i - 1)
		else
			contents = tostring(i)
		end
		local pos = ipe.Vector(xcoords[idx_v] - 4, ycoord - 20)
		local text = ipe.Text(model.attributes, contents, pos)
		model:creation("Added label", text)
	end
	
	-- 3. add a CIRCLE around every root vertex, if any
	for i = 1,n do
		local v_i = inverse_arrangement[i]
		if root_vertices[v_i] then
			add_circle(model, ipe.Vector(xcoords[v_i], ycoord), 4)
		end
	end
	
	-- 4. Add the arcs between the positions
	--    4.1. Calculate D
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
				
				-- choose right and left points
				local right = nil
				local left = nil
				if arrangement[v_i] < arrangement[v_j] then
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
	
	if calculate_D then
		local pos = ipe.Vector(xstart - 4, ycoord - 32)
		local str_D = "$D=" .. tostring(D) .. "$"
		local text = ipe.Text(model.attributes, str_D, pos)
		model:creation("Added label", text)
	end
end
