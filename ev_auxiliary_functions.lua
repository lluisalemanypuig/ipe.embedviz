function next_multiple_four(f)
	ff = math.floor(f)
	return ff + 4 - ff%4
end

function table_length(t)
	local count = 0
	for _ in pairs(t) do
		count = count + 1
	end
	return count
end

-- functions to parse the input string
function find_valid(str, i)
	while
	i <= #str and
	(
		string.sub(str, i,i) == " " or
		string.sub(str, i,i) == "," or
		string.sub(str, i,i) == "|"
	)
	do
		i = i + 1
	end
	return i
end

function find_invalid(str, i)
	while
	i <= #str and
	string.sub(str, i,i) ~= " " and
	string.sub(str, i,i) ~= "," and
	string.sub(str, i,i) ~= "|"
	do
		i = i + 1
	end
	return i
end

function parse_input(input)
	local Vertices = {}
	local i = find_valid(input, 1)
	while i <= #input do
		local j = find_invalid(input, i + 1)
		local word = string.sub(input, i, j - 1)
		table.insert(Vertices, word)
		i = find_valid(input, j)
	end
	return Vertices
end
