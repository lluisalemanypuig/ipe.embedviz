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
