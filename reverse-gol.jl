using JuMP

# returns sum of up to 8 neighbours of x[i, j] at time t
macro s(i, j, t)
    return esc(:(sum([x[$(i)+di,$(j)+dj, $(t)] for di in -1:1 for dj in -1:1 if (di!=0 || dj!=0) && 1<=$(i)+di<=size(x,1) && 1<=$(j)+dj<=size(x,2)])))
end


"""
    modelGOL(width, height, timesteps)

Encode Game of Life in linear inequalities as described in README. To ensure all tiles stay inside the bounding box, the cells on its perimeter must be
dead for all timesteps. This means that the 'effective' bounding box only has the size (width - 2) x (height - 2).

# Arguments
    * `width`: Width of model bounding box
    * `height`: Height of model bounding box
    * `timesteps`: Number of timesteps to run the model
"""
function modelGOL(width::Int, height::Int, timesteps::Int)
    model = Model()

    @variable(model, x[1:width, 1:height, 1:timesteps], Bin)  # x[i, j, t] iff cell x[i, j] is alive at time t

    @variable(model, m[1:width, 1:height, 1:timesteps-1], Bin)
    @variable(model, n[1:width, 1:height, 1:timesteps-1], Bin)
   
    # boundary must be dead for all time timesteps
    for i in 1 : width
        for j in 1 : height
            if (i == 1 || i == width || j == 1 || j == height)
                @constraint(model, sum(x[i, j, :]) == 0)
            end
        end
    end

    # game of life progress encoded as x[i, j, t + 1] iff 5 <= x[i, j, t] + 2 * s(i, j, t) <= 7
    
    # =>
    for i in 1 : width
        for j in 1 : height
            for t in 1 : timesteps - 1
                @constraint(model, x[i, j, t] + 2 * @s(i, j, t) >= 5 * x[i, j, t + 1])
                @constraint(model, x[i, j, t] + 2 * @s(i, j, t) <= 7 + 10 * (1 - x[i, j, t + 1]))
            end
        end
    end

    # <=
    for i in 1 : width
        for j in 1 : height
            for t in 1 : timesteps - 1
                @constraint(model, 1 - x[i, j, t + 1] <= m[i, j, t] + n[i, j, t])  # m (value too low) or n (value too high) must be true

                @constraint(model, x[i, j, t] + 2 * @s(i, j, t) <= 4 + 13 * (1 - m[i, j, t]))
                @constraint(model, x[i, j, t] + 2 * @s(i, j, t) >= 8 * n[i, j, t])
            end
        end
    end

    return model, x
end


"""
    printSol(filepath)

Pretty print the game board from the .sol solution file generated by the solvers

# Arguments
    * `filepath`: Relative or absolute filepath to .sol file
"""
function printSol(filepath::String)
    alive = Set{Tuple{Int, Int, Int}}()
    maxI, maxJ, maxT = 0, 0, 0  # Initialize max dimensions to find width and height
    
    # extract alive cells from sol file
    open(filepath, "r") do file
        for line in eachline(file)
            if occursin("x[", line)
                m = match(r"x\[(\d+),(\d+),(\d+)\] ([\d.]+)", line)

                if m !== nothing
                    i, j, t = parse.(Int, m.captures[1:3])
                    value = parse(Float64, m.captures[4])

                    maxI = max(maxI, i)
                    maxJ = max(maxJ, j)
                    maxT = max(maxT, t)
                    
                    if round(value) == 1
                        push!(alive, (i, j, t))
                    end
                end
            end
        end
    end

    for t in 1 : maxT
        println("Board at time t = $t:")
        for i in 1 : maxI
            for j in 1 : maxJ
                print((i, j, t) in alive ? "X" : ".")
            end
            println()
        end
    end    
end


"""
    reversePlay(width, height, timesteps, cells)

Determine starting state such that the after 'timesteps' many iteration the living tiles are exactly the vector 'cells'.

# Arguments
    * `width`: Width of model bounding box
    * `height`: Height of model bounding box
    * `timesteps`: Number of timesteps to run the model
    * `cells`: List of tuples encoding alive cells in last timestep
"""
function reversePlay(width::Int, height::Int, timesteps::Int, cells)
    model, x = modelGOL(width, height, timesteps)

    for i in 1 : width
        for j in 1 : height
            if (i, j) in cells
                @constraint(model, x[i, j, timesteps] == 1)
            else
                @constraint(model, x[i, j, timesteps] == 0)
            end
        end
    end

    JuMP.write_to_file(model, "reverse-$width-$height-$timesteps.mps")
end

function exampleReversePlay()
    # Donald Knuths 7x15 board spelling out "LIFE"
    cells = [(3, 3), (4, 3), (5, 3), (6, 3), (7, 3), (7, 4), (7, 5), (3, 7), (4, 7), (5, 7), (6, 7), (7, 7), (3, 9), (3, 10), (3, 11), (4, 9), (5, 9), (5, 10), (6, 9), (7, 9), (3, 13), (3, 14), (3, 15), (4, 13), (5, 13), (5, 14), (6, 13), (7, 13), (7, 14), (7, 15)]

    # choose model bounding box 9x17, such that simulation bounding box is 7x15
    reversePlay(9, 17, 4, cells)
    reversePlay(9, 17, 5, cells)
end


"""
    oscillator(width, height, period)

Determine starting state such that the after 'timesteps' many iteration the living tiles are exactly the vector 'cells'.

# Arguments
    * `width`: Width of model bounding box
    * `height`: Height of model bounding box
    * `timesteps`: Number of timesteps to run the model
    * `cells`: List of tuples encoding alive cells in last timestep
"""
function oscillator(width::Int, height::Int, period::Int)
    model, x = modelGOL(width, height, period + 1)

    # first and last board must be the same

    @constraint(model, [i=1:width, j=1:height], x[i, j, 1] == x[i, j, period + 1])

    # states in between must be different from first

    @variable(model, o[1:width, 1:height, 1:period - 1], Bin)

    for t in 1 : period - 1
        # if x != x', then o true
        @constraint(model, [i=1:width, j=1:height], x[i, j, t] - x[i, j, t + 1] <= o[i, j, t])
        @constraint(model, [i=1:width, j=1:height], x[i, j, t + 1] - x[i, j, t] <= o[i, j, t])

        # if x == x', then o false
        @constraint(model, [i=1:width, j=1:height], x[i, j, t] + x[i, j, t + 1] >= o[i, j, t])
        @constraint(model, [i=1:width, j=1:height], 2 - (x[i, j, t] + x[i, j, t + 1]) >= o[i, j, t])

        @constraint(model, sum(o[:, :, t]) >= 1)
    end

    # find oscillator of minimal size
    @objective(model, Min, sum(x[:, :, period + 1]))

    JuMP.write_to_file(model, "oscillator-$width-$height-$period.mps")
end

function exampleOscillator()
    # find smallest period-3 oscillator in 7x7 simulation bounding box, proves optimality of https://conwaylife.com/wiki/Jam
    oscillator(9, 9, 3)
end

# (c) Mia Muessig