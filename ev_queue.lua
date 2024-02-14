----------------------------------------------------------------------
-- LINEAR EMBEDDING VISUALIZER IPELET
----------------------------------------------------------------------
--[[
This file is an extension of the drawing editor Ipe (ipe7.sourceforge.net)

Copyright (c) 2020-2024 Lluís Alemany-Puig

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

--[[
This code has been adapted from the following post in stackoverflow.com

https://stackoverflow.com/questions/18843610/fast-implementation-of-queues-in-lua
--]]

Queue = {}
function Queue.new ()
	return {first = 0, last = -1}
end

function Queue.push_left(queue, value)
	local first = queue.first - 1
	queue.first = first
	queue[first] = value
end

function Queue.push_right(queue, value)
	local last = queue.last + 1
	queue.last = last
	queue[last] = value
end

function Queue.pop_left(queue)
	local first = queue.first
	if first > queue.last then error("queue is empty") end
	local value = queue[first]
	queue[first] = nil        -- to allow garbage collection
	queue.first = first + 1
	return value
end

function Queue.pop_right(queue)
	local last = queue.last
	if queue.first > last then error("queue is empty") end
	local value = queue[last]
	queue[last] = nil -- to allow garbage collection
	queue.last = last - 1
	return value
end

function Queue.size(queue)
	return queue.last - queue.first + 1
end
