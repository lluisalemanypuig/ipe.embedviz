
function make_dialog(model)
	local d = ipeui.Dialog(model.ui:win(), "Linear embedding")
	
	-- LINEAR SEQUENCE   #######################################################
	
	local row = 1
	d:add("label", "label", {label="Head vector"}, row, 1)
	--                                        SPAN: row span, colum span
	d:add("head_vector", "input", {}, row, 2, 1, 3)
	
	-- EDGE LIST         #######################################################
	
	row = row + 1
	d:add("label", "label", {label="Edge list"}, row, 1)
	--                                      SPAN: row span, colum span
	d:add("edge_list", "input", {}, row, 2, 1, 3)
	
	-- (1)
	-- ARRANGEMENT  ################  INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_1", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_1", "input", {}, row, 4)
	
	-- (2)
	-- ARRANGEMENT  ################  INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_2", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_2", "input", {}, row, 4)
	
	-- (3)
	-- ARRANGEMENT  ################  INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_3", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_3", "input", {}, row, 4)
	
	-- (4)
	-- ARRANGEMENT  ################  INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_4", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_4", "input", {}, row, 4)
	
	-- VERTEX LABELS     #######################################################
	
	row = row + 1
	d:add("label", "label", {label="Vertex labels"}, row, 1)
	--                                        SPAN: row span, colum span
	d:add("labels_list", "input", {}, row, 2, 1, 3)
	
	-- X OFFSET ##############   CIRUCLAR RADIUS ##############
	
	row = row + 1
	d:add("label", "label", {label="X offset"}, row, 1)
	d:add("xoffset", "input", {}, row, 2)
	
	d:add("label", "label", {label="Radius"}, row, 3)
	d:add("radius", "input", {}, row, 4)
	
	-- BIPARTITE HEIGHT
	
	row = row + 1
	d:add("label", "label", {label="Bipartite height"}, row, 1)
	d:add("bipartite height", "input", {}, row, 2)
	
	-- AUTOMATIC SPACING (CHECK BOX)
	
	row = row + 1
	d:add(
		"automatic_spacing",
		"checkbox",
		{label="Use automatic spacing"},
		row, 1,
		-- SPAN: row span, column span
		1, 4
	)
	
	-- CALCULATE SUM OF EDGE LENGTHS (CHECK BOX)
	
	row = row + 1
	d:add(
		"calculate_D",
		"checkbox",
		{label="Calculate sum of edge lengths"},
		row, 1,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- CALCULATE NUMBER OF EDGE CROSSINGS (CHECK BOX)
	
	d:add(
		"calculate_C",
		"checkbox",
		{label="Calculate number of edge crossings"},
		row, 3,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- BICOLOR GRAPH (CHECK BOX)
	row = row + 1
	d:add(
		"bicolor_vertices",
		"checkbox",
		{label="Bicolor vertices of the graph"},
		row, 1,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- EMBEDDINGS
	row = row + 1
	d:add(
		"linear_embedding",
		"checkbox",
		{label="Linear embedding"},
		row, 1,
		-- SPAN: row span, column span
		1, 2
	)
	d:add(
		"circular_embedding",
		"checkbox",
		{label="Circular embedding"},
		row, 3,
		-- SPAN: row span, column span
		1, 2
	)
	row = row + 1
	d:add(
		"bipartite_embedding",
		"checkbox",
		{label="Bipartite embedding"},
		row, 1,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- BUTTONS
	
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	--------------------------------------------------------------------
	
	row = row + 1
	d:add(
		"label",
		"label",
		{label="https://github.com/lluisalemanypuig/ipe.embedviz"},
		row, 1,
		-- SPAN: row span, column span
		1, 4
	)
	
	return d
end
