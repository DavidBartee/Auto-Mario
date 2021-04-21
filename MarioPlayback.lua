function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function read_lines_to_string(file)
	if not file_exists(file) then return nil end
	lines = ""
	for line in io.lines(file) do
		lines = lines .. line .. '\n'
		total_save_frames = total_save_frames + 1
	end
	return lines
end
--[[Take an input string from the Input Log and convert it to a table of
input values that can be fed to the emulator]]
function convert_to_inputs(input)
	local result = {}
	if string.sub(input, 8, 8) == "." then result["P1 A"] = "False" else result["P1 A"] = "True" end
	if string.sub(input, 7, 7) == "." then result["P1 B"] = "False" else result["P1 B"] = "True" end
	if string.sub(input, 2, 2) == "." then result["P1 Down"] = "False" else result["P1 Down"] = "True" end
	if string.sub(input, 3, 3) == "." then result["P1 Left"] = "False" else result["P1 Left"] = "True" end
	if string.sub(input, 4, 4) == "." then result["P1 Right"] = "False" else result["P1 Right"] = "True" end
	if string.sub(input, 1, 1) == "." then result["P1 Up"] = "False" else result["P1 Up"] = "True" end
	result["P1 Start"] = "False"
	result["P1 Select"] = "False"
	result["Power"] = "False"
	result["Reset"] = "False"
	return result
end

input_size = 8 --How many chars per input?
slice_size = 10 --How many frames in each input sample?

local frame = 1
local start_state = "1-1 start.State"
savestate.load(start_state)
save_file = 'save 23.save'
total_save_frames = 0
inputs = read_lines_to_string(save_file)
--[[first = (1 - 1) * (input_size + 1)
second = (1) * (input_size + 1) - 1
print(first, second)
print(string.sub(inputs, first, second))]]
while frame <= total_save_frames do
	--print(string.sub(inputs, (frame - 1) * (input_size + 1) + 1, frame * (input_size + 1) - 1))
	--print(convert_to_inputs(string.sub(inputs, (frame - 1) * (input_size + 1) + 1, frame * (input_size + 1) - 1)))
	joypad.set(convert_to_inputs(string.sub(inputs, (frame - 1) * (input_size + 1) + 1, frame * (input_size + 1) - 1)))
	emu.frameadvance()
	frame = frame + 1
end