function file_exists(file)
	local f = io.open(file, "rb")
	if f then f:close() end
	return f ~= nil
end

function read_lines(file)
	if not file_exists(file) then return {} end
	lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function save_inputs(filename, data)
	save = io.open(filename, 'w+')
	save:write(data)
	save:close()
end

function table_to_string(t)
	local result = ""
	for k,v in pairs(t) do
		for i = 1,string.len(v),input_size do
			result = result .. string.sub(v,i,i + input_size - 1) .. '\n'
		end
	end
	return result
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

local file = 'Input Log.txt'
local lines = read_lines(file)
local input_samples = {}

--[[Joypad table format:
"P1 A": "False"
"P1 B": "False"
"P1 Down": "False"
"P1 Left": "False"
"P1 Right": "False"
"P1 Select": "False"
"P1 Start": "False"
"P1 Up": "False"
"Power": "False"
"Reset": "False"

Read through the input sample file to determine which input sequences
are most common]]
input_size = 8 --How many chars per input?
slice_size = 10 --How many frames in each input sample?
--Remove inputs at the end that don't form a full slice
while #lines % slice_size ~= 0 do
	lines[#lines] = nil
end

local current_slice = ""
for k,v in pairs(lines) do
	--print('line[' .. k .. ']', string.sub(v, 5, 12))
	local inputs = string.sub(v, 5, 12)
	current_slice = current_slice .. inputs
	if k % slice_size == 0 then
		--We have reached the end of the input slice, so add it to the sample table
		if input_samples[current_slice] == nil then
			input_samples[current_slice] = 1
		else
			--MUST COMMENT THIS OUT FOR NORMALIZED/"BALANCED" INPUT CHOICES!
			input_samples[current_slice] = input_samples[current_slice] + 1
		end
		current_slice = "" --Reset current_slice to store the next one
	end
end

--[[for k,v in pairs(input_samples) do
	print(k)
	print(v .. ' instances')
end]]
--print(convert_to_inputs("...R..B."))
local frame = 1
local start_state = "1-1 start.State"
savestate.load(start_state)
--Parameters
num_futures = 10
future_length = slice_size * 30
retries_before_rewind = 1 --IDEA: Instead, try 2nd, 3rd etc. best future when stuck
total_input_slices = 0 --Will be used when picking inputs randomly
total_unique_inputs = 0
futures_picked = {}
inputs_so_far = ""
savestates = {}
savestates [1] = start_state

math.randomseed(os.clock() * 100000000000)

for k,v in pairs(input_samples) do
	total_input_slices = total_input_slices + v --Add v for weighted choices, 1 for "balanced"
	total_unique_inputs = total_unique_inputs + 1
end

function pick_rng_futures()
	local futures = {}
	for i = 1,num_futures do
		local future = ""
		while string.len(future) < future_length * input_size do
			local j = math.random(1, total_input_slices)
			local m = 0
			for k,v in pairs(input_samples) do
				m = m + v
				if m >= j then
					future = future .. k
					break
				end
			end
		end
		futures[#futures + 1] = future
	end
	return futures
end

function eval_futures(futures)
	local best_future = ""
	local fail_score = -9999999
	local best_score = fail_score
	local prevXlow = memory.readbyte(1820)
	local prevXhigh = memory.readbyte(1818)
	local prevSubroutine = memory.readbyte(14)
	local prevRelX = memory.readbyte(134)
	local prevPipe = memory.readbyte(1874)
	
	for k,v in pairs(futures) do
		savestate.load(savestates[#savestates])--Load the most recent state
		local m = 1
		while m < future_length * input_size  and memory.readbyte(14) ~= 11 and memory.readbyte(181) < 2 and memory.readbyte(1882) >= 2 do
			joypad.set(convert_to_inputs(string.sub(v, m, m + input_size - 1)))
			m = m + input_size
			emu.frameadvance()
		end
		--Score this future
		local score = fail_score
		--Check if Mario died. If not, give him a score
		if memory.readbyte(14) ~= 11 and memory.readbyte(181) < 2 and memory.readbyte(1882) >= 2 then
			score = 256 * (memory.readbyte(1818) - prevXhigh) + memory.readbyte(1820) - prevXlow
			score = math.max(score, 0)--Make sure the score is not less than zero, as scroll values
										--reset between levels
			--If Mario hasn't scrolled the screen, check if he's moved to the right on-screen
			--Cap at 194 for pipe bonus rooms, make sure scrolling is locked or pipe was exited
			if score == 0 and (memory.readbyte(1827) == 1 or prevPipe == 2) then
				score = math.max(math.min(memory.readbyte(134), 194) - math.min(prevRelX, 194), 0)
			end
			--Make sure going through pipes is rewarded (important for levels like 1-2)
			--Also finishing levels!
			if memory.readbyte(1874) == 2 or memory.readbyte(1874) == 1 then score = score + 100 end
			if memory.readbyte(14) ~= 8 or prevSubroutine ~= 8 then score = score + 100 end
		end
		--Make sure Mario makes progress, or else you will DIE
		if score > best_score and score > 0 then
			best_future = v
			best_score = score
		end
	end
	return best_future
end

--test = pick_rng_futures()
--print(test)
--print(eval_futures(test))

while memory.readbyte(1887) < 1 do
	savestate.load(savestates[#savestates])
	local progress = 0
	for i = 1,retries_before_rewind do
		local best = eval_futures(pick_rng_futures())
		if best ~= "" then
			savestate.load(savestates[#savestates])
			local m = 1
			while m < future_length * input_size do
				local inp = string.sub(best, m, m + input_size - 1)
				joypad.set(convert_to_inputs(inp))
				inputs_so_far = inputs_so_far .. inp .. '\n'
				m = m + input_size
				emu.frameadvance()
			end
			local new_state_name = 'state ' .. (#savestates + 1) .. '.State'
			savestate.save(new_state_name)
			savestates[#savestates + 1] = new_state_name
			progress = 1
			break
		end
	end
	if progress == 0 then
		--If every future leads to a death, rewind and try again
		savestates[#savestates] = nil
		inputs_so_far = string.sub(inputs_so_far, 1, string.len(inputs_so_far) - future_length * (input_size + 1))
	else
		save_inputs('save ' .. #savestates .. '.save', inputs_so_far)
	end
end