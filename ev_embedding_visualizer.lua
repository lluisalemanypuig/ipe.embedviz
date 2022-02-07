----------------------------------------------------------------------
-- LINEAR EMBEDDING VISUALIZER IPELET
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

label = "Embedding visualizer"

about = [[
Tool for drawing linear and circular embeddings of graphs.
]]

if _G["next_multiple_four"] == nil then

------------------------------------------------------------------------
--- AUXILIARY FUNCTIONS

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_auxiliary_functions.lua")
_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_make_dialog.lua")

------------------------------------------------------------------------
--- PARSE INPUT DATA

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_parse_input_data.lua")

------------------------------------------------------------------------
--- DATA STRUCTURES

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_queue.lua")

------------------------------------------------------------------------
--- DRAW DATA

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/bev_draw_input_data.lua")
_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/cev_draw_input_data.lua")
_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/lev_draw_input_data.lua")

end

function run(model)
	
	-- VARIABLES
	local xoffset = 16 -- default distance between consecutive points
	local xstart = 4  -- starting x coordinate of an embedding
	local ystart = 40  -- starting y coordinate of an embedding
	
	local circular_radius = 22  -- radius of the circle
	local bipartite_height = 26  -- height of a bipartite drawing
	
	--------------------------------------------------------------------
	-- construct and execute the dialog
	local d = _G.make_dialog(model)
	if not d:execute() then
		return
	end
	
	-- parse and convert the data from the boxes
	local success, parsed_data = _G.parse_data(d, model)
	
	-- if errors were found...
	if not success then
		-- halt
		return
	end
	
	-- from this point we can assume that the input data is formatted correctly
	
	-- update x-offset
	if parsed_data["xoffset"] ~= nil then
		xoffset = parsed_data["xoffset"]
	end
	-- update circular radius
	if parsed_data["circular_radius"] ~= nil then
		circular_radius = parsed_data["circular_radius"]
	end
	-- update bipartite height
	if parsed_data["bipartite_height"] ~= nil then
		bipartite_height = parsed_data["bipartite_height"]
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
			xoffset
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
	
	local num_arrangements = parsed_data["num_arrangements"]
	
	-- draw all arrangements given
	if parsed_data["draw_linear"] then
		local ycoord = ystart
		local max_width = 0
		
		for i = num_arrangements,1, -1 do
		
			local height, ycoord_vertices, width =
				_G.linear_draw_data(
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
						inverse_arrangement			= parsed_data["inverse_arrangements"][i]
					},
					{
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
						xcoord	= xstart,
						ycoord	= ycoord
					}
				)
			
			if max_width < width then
				max_width = width
			end
			
			--------------------------------------------------------------------
			-- calculate new y coordinate for the vertices' marks
			
			-- increment by POSITIONS and VERTEX LABELS
			ycoord = ycoord + (ycoord - ycoord_vertices)
			
			-- increment by the largest arc's radius plus some more space
			ycoord = ycoord + height + 8
			
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
		
		xstart = xstart + max_width
	end
	
	if parsed_data["draw_circular"] then
		local xcoord = xstart + 3*circular_radius + 8
		local ycoord = ystart
		local max_width = 0
		
		for i = num_arrangements,1, -1 do
			local height, width = 
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
						inverse_arrangement			= parsed_data["inverse_arrangements"][i]
					},
					{
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
						radius	= circular_radius,
						xcoord	= xcoord,
						ycoord	= ycoord
					}
				)
			
			if max_width < width then
				max_width = width
			end
			
			--------------------------------------------------------------------
			-- calculate new y coordinate for the vertices' marks
			
			-- increment by POSITIONS and VERTEX LABELS
			ycoord = ycoord + 24 + height
			
			-- increment by METRICS height
			if has_metric_C then
				-- height of the label with $C=...$ plus some more
				ycoord = ycoord + 8
			end
		end
		
		xstart = xstart + max_width + 12
	end
	if parsed_data["draw_bipartite"] then
		local xcoord = xstart + 40
		local ycoord = ystart
		local max_width = 0
		
		if not parsed_data["bicolor_vertices"] then
			color_per_vertex = _G.bicolor_vertices_graph(
				parsed_data["n"],
				parsed_data["adjacency_matrix"],
				true
			)
		end
		
		for i = num_arrangements,1, -1 do
			local width = 
				_G.bipartite_draw_data(
					model,
					{
						n							= parsed_data["n"],
						adjacency_matrix			= parsed_data["adjacency_matrix"],
						root_vertices				= parsed_data["root_vertices"],
						automatic_spacing			= parsed_data["automatic_spacing"],
						INTvertex_to_STRvertex		= parsed_data["INTvertex_to_STRvertex"],
						calculate_C					= parsed_data["calculate_C"],
						color_per_vertex			= color_per_vertex,
						arrangement					= parsed_data["arrangements"][i],
						inverse_arrangement			= parsed_data["inverse_arrangements"][i]
					},
					{
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
						height	= bipartite_height,
						xcoord	= xcoord,
						ycoord	= ycoord
					}
				)
			
			--------------------------------------------------------------------
			-- calculate new y coordinate for the vertices' marks
			
			-- increment by POSITIONS and VERTEX LABELS
			ycoord = ycoord + 2*(bipartite_height + vertex_labels_max_height + vertex_labels_max_depth) + 12
			
			-- increment by METRICS height
			if has_metric_C then
				-- height of the label with $C=...$ plus some more
				ycoord = ycoord + 8
			end
		end
		
		xstart = xstart + max_width
	end
	
	-- select all created objects
	for i = prev_Nobj+1,#p do
		p:setSelect(i, 1)
	end
	
end
