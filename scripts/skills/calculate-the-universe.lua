local moonsign_numbers = {
	Mongoose = 1,
	Wallaby = 2,
	Vole = 3,
	Platypus = 4,
	Opossum = 5,
	Marmot = 6,
	Wombat = 7,
	Blender = 8,
	Packrat = 9,
}

function calculate_the_universe(input)
	local moonsign_number = moonsign_numbers[moonsign()] or 10
	return (input + moonsign_number + ascensions_count()) * (spleen() + level()) + advs()
end
