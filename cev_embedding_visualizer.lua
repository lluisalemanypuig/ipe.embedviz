----------------------------------------------------------------------
-- CIRCULAR EMBEDDING VISUALIZER IPELET
----------------------------------------------------------------------
--[[
This file is an extension of the drawing editor Ipe (ipe7.sourceforge.net)

Copyright (c) 2020 Lluís Alemany-Puig

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
--]]


--[[
You'll find the instruction manual at:
https://github.com/lluisalemanypuig/ipe.embedviz
--]]

------------------------------------------------------------------------
------------------------------------------------------------------------

label = "Circular embedding visualizer"

about = [[
Tool for drawing circular embeddings of graphs.
]]

if _G["next_multiple_four"] == nil then

------------------------------------------------------------------------
------------------------------------------------------------------------
--- AUXILIARY FUNCTIONS

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_auxiliary_functions.lua")

------------------------------------------------------------------------
------------------------------------------------------------------------
--- PARSE INPUT DATA

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_parse_input_data.lua")

------------------------------------------------------------------------
------------------------------------------------------------------------
--- DATA STRUCTURES

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_queue.lua")

------------------------------------------------------------------------
------------------------------------------------------------------------
--- DRAW DATA

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/cev_draw_input_data.lua")
_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/lev_draw_input_data.lua")

end

function make_dialog(model)
	local d = ipeui.Dialog(model.ui:win(), "Graph input")
	
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
	
	-- X OFFSET ##############   RADIUS
	
	row = row + 1
	d:add("label", "label", {label="Offset"}, row, 1)
	d:add("xoffset", "input", {}, row, 2)
	
	d:add("label", "label", {label="Radius"}, row, 3)
	d:add("radius", "input", {}, row, 4)
	
	-- AUTOMATIC SPACING
	
	row = row + 1
	d:add(
		"automatic_spacing",
		"checkbox",
		{label="Use automatic spacing"},
		row, 1,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- CALCULATE SUM OF EDGE LENGTHS (CHECK BOX)
	
	d:add(
		"calculate_D",
		"checkbox",
		{label="Calculate sum of edge lengths"},
		row, 3,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- CALCULATE NUMBER OF EDGE CROSSINGS (CHECK BOX)
	
	row = row + 1
	d:add(
		"calculate_C",
		"checkbox",
		{label="Calculate number edge crossings"},
		row, 1,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- BICOLOR GRAPH (CHECK BOX)
	
	d:add(
		"bicolor_vertices",
		"checkbox",
		{label="Bicolor vertices of the graph"},
		row, 3,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- BUTTONS
	
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	--------------------------------------------------------------------
	
	return d
end

function run(model)
	
	local radius = 52 -- radius of the circle
	local ycoord = 40 -- y-coordinate of the circle's centre
	local xcoord = 24 -- x-coordinate of the circle's centre
	
	--------------------------------------------------------------------
	-- construct and execute the dialog
	local d = make_dialog(model)
	if not d:execute() then
		return
	end
	
	-- parse and convert the data from the boxes
	local success, parsed_data = _G.parse_data(d, model, {get_radius = true})
	
	-- if errors were found...
	if not success then
		-- halt
		return
	end
	
	-- check existence of metrics
	local has_metric_D = parsed_data["calculate_D"]
	local has_metric_C = parsed_data["calculate_C"]
	
	-- calculate labels dimensions
	local
		vertex_labels_width, vertex_labels_height, vertex_labels_depth,
		vertex_labels_max_width, vertex_labels_max_height, vertex_labels_max_depth,
		position_labels_width, position_labels_height, position_labels_depth,
		position_labels_max_width, position_labels_max_height, position_labels_max_depth
		=
		_G.calculate_labels_dimensions
		(
			model,
			parsed_data["automatic_spacing"],
			parsed_data["n"],
			parsed_data["INTvertex_to_STRvertex"],
			8
		)
	
	-- color vertices
	local color_per_vertex = _G.bicolor_vertices_graph(
		parsed_data["n"],
		parsed_data["adjacency_matrix"],
		parsed_data["bicolor_vertices"]
	)
	
	-- prior to drawing the objects, deselect all objects
	local p = model:page()
	p:deselectAll()
	local prev_Nobj = #p
	
	-- draw all arrangements given
	local num_arrangements = parsed_data["num_arrangements"]
	for i = num_arrangements,1, -1 do
		local height_labels_inbetween = 
			_G.circular_draw_data(
				model,
				{
					n							= parsed_data["n"],
					adjacency_matrix			= parsed_data["adjacency_matrix"],
					root_vertices				= parsed_data["root_vertices"],
					automatic_spacing			= parsed_data["automatic_spacing"],
					INTvertex_to_STRvertex		= parsed_data["INTvertex_to_STRvertex"],
					calculate_D					= parsed_data["calculate_D"],
					calculate_C					= parsed_data["calculate_C"],
					color_per_vertex			= color_per_vertex,
					arrangement					= parsed_data["arrangements"][i],
					inverse_arrangement			= parsed_data["inverse_arrangements"][i],
					vertex_labels_width			= vertex_labels_width,
					vertex_labels_height		= vertex_labels_height,
					vertex_labels_depth			= vertex_labels_depth,
					vertex_labels_max_width		= vertex_labels_max_width,
					vertex_labels_max_height	= vertex_labels_max_height,
					vertex_labels_max_depth		= vertex_labels_max_depth,
					position_labels_width		= position_labels_width,
					position_labels_height		= position_labels_height,
					position_labels_depth		= position_labels_depth,
					position_labels_max_width	= position_labels_max_width,
					position_labels_max_height	= position_labels_max_height,
					position_labels_max_depth	= position_labels_max_depth
				},
				{
					radius	= radius,
					xcoord	= xcoord,
					ycoord	= ycoord
				}
			)
		
		------------------------------------------------------------------------
		-- calculate new y coordinate for the vertices' marks
		
		-- increment by POSITIONS and VERTEX LABELS
		ycoord = ycoord + 2*radius
		ycoord = ycoord + height_labels_inbetween
		
		-- increment by METRICS height
		if has_metric_D then
			-- height of the label with $D=...$ plus some more
			ycoord = ycoord + 8
		end
		if has_metric_C then
			-- height of the label with $C=...$ plus some more
			ycoord = ycoord + 8
		end
	end
	
	-- select all created objects
	for i = prev_Nobj+1,#p do
		p:setSelect(i, 1)
	end
	
end
