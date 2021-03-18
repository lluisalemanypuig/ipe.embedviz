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
	local arr = data_to_be_drawn["arr"]
	local inv_arr = data_to_be_drawn["inv_arr"]
	local adj_matrix = data_to_be_drawn["adj_matrix"]
	local root_vertex = data_to_be_drawn["root"]
	local uses_zero = data_to_be_drawn["uses_zero"]
	local n = data_to_be_drawn["n"]
	local automatic_spacing = data_to_be_drawn["automatic_spacing"]
	
	local p = model:page()
	local prev_Nobj = #p
	
	local xoffset = coordinates["xoffset"]
	local xstart = coordinates["xstart"]
	local ycoord = coordinates["ycoord"]
	
	-- first, calculate widths of the labels
	
	local labels_width = {}
	if automatic_spacing then
		-- first add all labels to the model, I really couldn't care less where
		for i = 1,n do
			v_i = inv_arr[i]
			local pos = ipe.Vector(50, 50)
			local text = ipe.Text(model.attributes, v_i, pos)
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
			v_i = inv_arr[i - prev_Nobj]
			labels_width[v_i] = p[i]:get("width")
		end
		-- delete the labels added (I know this is not efficient, but
		-- I'm expecting a low number of labels)
		while #p > prev_Nobj do
			p:remove(#p)
		end
	else
		-- assign width using the xoffset
		for i = 1,n do
			v_i = inv_arr[i]
			labels_width[v_i] = xoffset
		end
	end
	
	-- second, add labels and marks (black dots)
	
	local xcoords = {}
	for i = 1,n do
		v_i = inv_arr[i]
		
		-- calculate x_coord for v_i
		if i == 1 then
			xcoords[v_i] = xstart
		else
			v_i_1 = inv_arr[i - 1]
			local x_plus_width = xcoords[v_i_1] + labels_width[v_i_1]
			xcoords[v_i] = next_multiple_four(x_plus_width) + 4
		end
		
		-- create the text label for the vertices with the correct position
		local pos = ipe.Vector(xcoords[v_i] - 4, ycoord - 12)
		local text = ipe.Text(model.attributes, v_i, pos)
		model:creation("Added label", text)
		
		-- create the mark
		mark_pos = ipe.Vector(xcoords[v_i], ycoord)
		mark = ipe.Reference(model.attributes, "mark/disk(sx)", mark_pos)
		model:creation("Added mark", mark)
		
		-- create the text label for the positions
		local contents = ""
		if uses_zero then
			contents = tostring(i - 1)
		else
			contents = tostring(i)
		end
		local pos = ipe.Vector(xcoords[v_i] - 4, ycoord - 20)
		local text = ipe.Text(model.attributes, contents, pos)
		model:creation("Added label", text)
	end
	
	-- third, add a CIRCLE around the root vertex, if any
	
	if root_vertex ~= nil then
		R = inv_arr[root_vertex]
		add_circle(model, ipe.Vector(xcoords[R], ycoord), 4)
	end
	
	-- fourth, add the arcs between the positions
	
	for p_i = 1,n do
		for p_j = p_i+1,n do
			if adj_matrix[p_i][p_j] == true then
				v_i = inv_arr[p_i]
				v_j = inv_arr[p_j]
				
				-- choose right and left points
				local right = nil
				local left = nil
				if arr[v_i] < arr[v_j] then
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
	
	-- fifth, select the objects created so that they can be
	-- moved easily
	
	p:deselectAll()
	for i = prev_Nobj+1,#p do
		p:setSelect(i, 1)
	end
end
