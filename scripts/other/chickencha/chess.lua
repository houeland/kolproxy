local function copy_board(board)
	newboard = {}
	for k, v in pairs(board) do
		newboard[k] = v
	end
	return newboard
end

local function square(file, rank)
	return file + 64 - 8*rank
end

local function file(square)
	return (square - 1) % 8 + 1
end

local function rank(square)
	return 8 - math.floor((square - 1) / 8)
end

local try_move

local endmoves = {
	-- bishop
	b = function(file, rank)
		local ranks = 8 - rank
		if file + ranks <= 8 then
			return file + ranks, 8
		end
		if file - ranks >= 1 then
			return file - ranks, 8
		end
	end,
	-- knight
	n = function(file, rank)
		if rank == 7 then
			if file > 2 then
				return file - 2, 8
			else
				return file + 2, 8
			end
		end
		if rank == 6 then
			if file > 1 then
				return file - 1, 8
			else
				return file + 1, 8
			end
		end
	end,
	-- pawn
	p = function(file, rank)
		if rank == 7 then
			return file, 8
		end
	end,
	-- rook
	r = function(file, rank)
		return file, 8
	end,
}
-- queen same as rook
endmoves.q = endmoves.r
-- king same as pawn
endmoves.k = endmoves.p

local function rook_moves(board, file, rank, pieces)
	for f = file - 1, 1, -1 do
		local square = square(f, rank)
		if board[square] then
			local move = try_move(board, f, rank, pieces)
			if move then return move end
			break
		end
	end
	for f = file + 1, 8 do
		local square = square(f, rank)
		if board[square] then
			local move = try_move(board, f, rank, pieces)
			if move then return move end
			break
		end
	end
	for r = rank - 1, 1, -1 do
		local square = square(file, r)
		if board[square] then
			local move = try_move(board, file, r, pieces)
			if move then return move end
			break
		end
	end
	for r = rank + 1, 8 do
		local square = square(file, r)
		if board[square] then
			local move = try_move(board, file, r, pieces)
			if move then return move end
			break
		end
	end
end

local function bishop_moves(board, file, rank, pieces)
	-- black kingside
	for offs = 1, math.min(file - 1, 8 - rank) do
		local square = square(file - offs, rank + offs)
		if board[square] then
			local move = try_move(board, file - offs, rank + offs, pieces)
			if move then return move end
			break
		end
	end
	-- black queenside
	for offs = 1, math.min(8 - file, 8 - rank) do
		local square = square(file + offs, rank + offs)
		if board[square] then
			local move = try_move(board, file + offs, rank + offs, pieces)
			if move then return move end
			break
		end
	end
	-- white kingside
	for offs = 1, math.min(file - 1, rank - 1) do
		local square = square(file - offs, rank - offs)
		if board[square] then
			local move = try_move(board, file - offs, rank - offs, pieces)
			if move then return move end
			break
		end
	end
	-- white queenside
	for offs = 1, math.min(8 - file, rank - 1) do
		local square = square(file + offs, rank - offs)
		if board[square] then
			local move = try_move(board, file + offs, rank - offs, pieces)
			if move then return move end
			break
		end
	end
end

local moves = {
	-- bishop
	b = bishop_moves,
	-- king
	k = function(board, file, rank, pieces)
		return try_move(board, file - 1, rank, pieces) or
			try_move(board, file + 1, rank, pieces) or
			try_move(board, file, rank - 1, pieces) or
			try_move(board, file, rank + 1, pieces) or
			try_move(board, file - 1, rank - 1, pieces) or
			try_move(board, file + 1, rank - 1, pieces) or
			try_move(board, file - 1, rank + 1, pieces) or
			try_move(board, file + 1, rank + 1, pieces)
	end,
	-- knight
	n = function(board, file, rank, pieces)
		return try_move(board, file - 1, rank - 2, pieces) or
			try_move(board, file - 2, rank - 1, pieces) or
			try_move(board, file + 1, rank - 2, pieces) or
			try_move(board, file + 2, rank - 1, pieces) or
			try_move(board, file + 1, rank + 2, pieces) or
			try_move(board, file + 2, rank + 1, pieces) or
			try_move(board, file - 1, rank + 2, pieces) or
			try_move(board, file - 2, rank + 1, pieces)
	end,
	-- pawn
	p = function(board, file, rank, pieces)
		return try_move(board, file - 1, rank + 1, pieces) or
			try_move(board, file + 1, rank + 1, pieces)
	end,
	-- queen
	q = function(board, file, rank, pieces)
		return rook_moves(board, file, rank, pieces) or bishop_moves(board, file, rank, pieces)
	end,
	-- rook
	r = rook_moves,
}

local function solve(board, whitepiece, file, rank, pieces)
	if pieces == 0 then
		file, rank = endmoves[whitepiece](file, rank)
		if file and rank then
			return {square(file, rank)}
		end
		return
	end
	return moves[whitepiece](board, file, rank, pieces)
end

try_move = function(board, file, rank, pieces)
	if file < 1 or file > 8 or rank < 1 or rank > 8 then return end
	local square = square(file, rank)
	local whitepiece = board[square]
	if whitepiece == nil then return end
	board = copy_board(board)
	board[square] = nil
	local solution = solve(board, whitepiece, file, rank, pieces - 1)
	if solution then
		table.insert(solution, 1, square)
		return solution
	end
end

local chess_href = add_automation_script("automate-chess-puzzle", function()
	local text, url = get_page("/choice.php")
	local board = {}
	local square = 1
	local whitesquare = nil
	local whitepiece = nil
	local pieces = 0
	for x in text:gmatch([[chess/([%l_]-).gif]]) do
		if x ~= "blanktrans" then
			-- name is of form "chess_PFB" where:
			-- P is the piece
			-- F is the foreground color
			-- B is the background color; we don't care about this
			local piece = x:sub(7, 7)
			local color = x:sub(8, 8)
			if color == "b" then
				board[square] = piece
				pieces = pieces + 1
			else
				whitesquare = square
				whitepiece = piece
			end
		end
		square = square + 1
	end
	local solution = solve(board, whitepiece, file(whitesquare), rank(whitesquare), pieces)
	local ptf
	for k, v in ipairs(solution) do
		local xy = ("%d,%d"):format(file(v) - 1, 8 - rank(v))
		ptf = async_get_page("/choice.php", { pwd = session.pwd, whichchoice = "443", option = "1", xy = xy })
	end
	return ptf()
end)

add_printer("/choice.php", function()
	if adventure_title ~= "Chess Puzzle" then return end
	text = text:gsub([[<input class=button type=submit value="Walk Away"></form>]], [[%1<a href="]] .. chess_href { pwd = session.pwd } .. [[" style="color: green">{ Solve }</a>]])
end)
