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

function run(model)
	local d = ipeui.Dialog(model.ui:win(), "Graph input")
	
	--------------------------------------------------------------------
	-- construct the dialog
	
	-- LINEAR SEQUENCE   ##########################
	
	local row = 1
	d:add("label4", "label", {label="Head vector"}, row, 1)
	--                                            SPAN: from column 1 to column 4
	d:add("head_vector", "input", {}, row, 2,        1, 4)
	
	-- EDGE LIST         ##########################
	
	row = row + 1
	d:add("label1", "label", {label="Edge list"}, row, 1)
	d:add("edge_list", "input", {}, row, 2, 1, 4)
	
	-- ARRANGEMENT  ###########    INVERSE ARRANGEMENT  ###########
	
	row = row + 1
	d:add("label2", "label", {label="Arrangement"}, row, 1)
	d:add("arrangement", "input", {}, row, 2)
	
	d:add("label3", "label", {label="Inverse Arrangement"}, row, 3)
	d:add("inverse_arrangement", "input", {}, row, 4)
	
	-- VERTEX LABELS
	
	row = row + 1
	d:add("label1", "label", {label="Vertex labels"}, row, 1)
	d:add("labels_list", "input", {}, row, 2, 1, 4)
	
	-- X OFFSET ##############   USE AUTOMATIC ALIGNMENT (HERE A CHECK BOX)
	
	row = row + 1
	d:add("label4", "label", {label="X offset"}, row, 1)
	d:add("xoffset", "input", {}, row, 2)
	
	d:add(
		"automatic_spacing",
		"checkbox",
		{label="Use automatic spacing"},
		row, 3,
	-- SPAN: from column 3 to column 4
	   3, 4)
	
	-- BUTTONS
	
	d:addButton("ok", "&Ok", "accept")
	d:addButton("cancel", "&Cancel", "reject")
	--------------------------------------------------------------------
	
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
	local success, converted_data = _G.parse_data(d, model)
	
	-- if errors were found...
	if success == false then
		return
	end
	
	-- from this point we can assume that the input data is formatted
	-- correctly, and that has been correctly retrieved into the
	-- variables above.
	
	_G.draw_data(
		model,
		converted_data,
		{
			xoffset = xoffset,
			xstart = xstart,
			ycoord = ycoord
		}
	)
end
