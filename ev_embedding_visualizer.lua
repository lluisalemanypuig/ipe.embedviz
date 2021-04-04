----------------------------------------------------------------------
-- Automatic labelling ipelet
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
https://github.com/lluisalemanypuig/ipe.drawembedding
--]]

------------------------------------------------------------------------
------------------------------------------------------------------------

label = "Embedding visualizer"

about = [[
Tool for drawing (linear) embeddings of graphs.
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
--- DRAW DATA

_G.dofile(_G.os.getenv("HOME") .. "/.ipe/ipelets/ev_draw_input_data.lua")

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
	-- ARRANGEMENT  ################    INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_1", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_1", "input", {}, row, 4)
	
	-- (2)
	-- ARRANGEMENT  ################    INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_2", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_2", "input", {}, row, 4)
	
	-- (3)
	-- ARRANGEMENT  ################    INVERSE ARRANGEMENT  ###################
	
	row = row + 1
	d:add("label", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement_3", "input", {}, row, 2)
	
	d:add("label", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement_3", "input", {}, row, 4)
	
	-- (4)
	-- ARRANGEMENT  ################    INVERSE ARRANGEMENT  ###################
	
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
	
	-- X OFFSET ##############   AUTOMATIC ALIGNMENT (CHECK BOX)
	
	row = row + 1
	d:add("label", "label", {label="X offset"}, row, 1)
	d:add("xoffset", "input", {}, row, 2)
	d:add(
		"automatic_spacing",
		"checkbox",
		{label="Use automatic spacing"},
		row, 3,
		-- SPAN: row span, column span
		1, 2
	)
	
	-- CALCULATE SUM OF EDGE LENGTHS (CHECK BOX)
	
	row = row + 1
	d:add(
		"calculate_D",
		"checkbox",
		{label="Calculate sum of edge lengths"},
		row, 1,
		-- SPAN: row span, column span
		1, 4
	)
	
	-- BUTTONS
	
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	--------------------------------------------------------------------
	
	return d
end

function run(model)
	
	--------------------------------------------------------------------
	-- construct the dialog
	
	local d = make_dialog(model)
	
	-- "execute" the dialog
	if not d:execute() then
		return
	end
	
	-- VARIABLES
	local xoffset = 16 -- default distance between consecutive points
	local xstart = 24  -- starting x coordinate
	local ycoord = 500 -- height of the points
	
	-- in case some offset was given, check that it
	-- is a non-null numeric value
	local input_offset = d:get("xoffset")
	if input_offset ~= "" then
		xoffset = tonumber(input_offset)
		if xoffset == nil then
			model:warning("Input offset is not numerical.")
			return
		end
		if xoffset == 0 then
			model:warning("Input offset cannot be 0.")
			return
		end
	end
	
	-- parse and convert the data from the boxes
	local success, parsed_data = _G.parse_data(d, model)
	
	-- if errors were found...
	if success == false then
		-- halt
		return
	end
	
	-- from this point we can assume that the input data is formatted
	-- correctly, and that has been correctly retrieved into the
	-- variables above.
	
	-- prior to drawing the objects, deselect all objects
	local p = model:page()
	p:deselectAll()
	local prev_Nobj = #p
	
	local num_arrangements = parsed_data["num_arrangements"]
	
	local y_increment = 0
	for i = 1, num_arrangements do
	    local data_to_draw =
		{
			n						= parsed_data["n"],
			adjacency_matrix		= parsed_data["adjacency_matrix"],
			root_vertices			= parsed_data["root_vertices"],
			automatic_spacing		= parsed_data["automatic_spacing"],
			INTvertex_to_STRvertex	= parsed_data["INTvertex_to_STRvertex"],
			calculate_D				= parsed_data["calculate_D"],
			arrangement				= parsed_data["arrangements"][i],
			inverse_arrangement		= parsed_data["inverse_arrangements"][i]
		}

		_G.draw_data(
			model,
			data_to_draw,
			{
				xoffset = xoffset,
				xstart = xstart,
				ycoord = ycoord + y_increment
			}
		)

		y_increment = y_increment - 50
	end
	
	-- select all created objects
	for i = prev_Nobj+1,#p do
		p:setSelect(i, 1)
	end
	
end
