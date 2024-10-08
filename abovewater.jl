using Images, Plots
include("imageprocessing.jl")

calibrationfactor = 9.25926e-5 #m/px
framerate = 2500 #fps
whitethreshold = 0.35 #1 is white
waterhitindex = 18 #index of first image after hitting the water. Found by looking at the images

imagenames = readdir("images/abovewater")
frames = length(imagenames)
frametime = 1/framerate
g = 9.8
h = 0.2
vf = sqrt(2*g*h)
function getv(t)#relative to when sphere hits water
    return vf + g*t
end

topblacks::Vector{Int} = zeros(frames)#row of first black pixel
bottomsphere::Vector{Int} = zeros(frames) #row of bottom of sphere
bottomblacks::Vector{Int} = zeros(frames)#row of last black pixel
diameters::Vector{Int} = zeros(frames)#a check that this is working

for i = 1:1:frames
    img = load("images/abovewater/"*imagenames[i])
    #imgthresh = threshold(img,whitethreshold)
    rows, columns = size(img)
    #display(img) #debug
    foundblack::Vector{Bool} = zeros(rows)
    for row = 1:1:rows
        for column = 1:1:columns
            if img[row,column] < whitethreshold
                foundblack[row] = true
            end
        end
    end
    topblacks[i] = findfirst(x -> x==true,foundblack)
    bottomblacks[i] = findfirst(x -> x==true,reverse(foundblack))
    diameters[i] = findfirst(x -> x==false,foundblack[topblacks[i]:end]) - 1
    bottomsphere[i] = topblacks[i] + diameters[i] - 1
end

positions = @. calibrationfactor*topblacks
timestamps = collect(0:frametime:frametime*(frames-1)) #these are timesteps for the velocity. They occur exactly between frames.
velocities = zeros(frames)
for i = 2:1:frames-1
    velocities[i] = (positions[i+1] - positions[i-1])/(2*frametime)
end

#ball hits water just before waterhitindex
timestamps = 1000*@. timestamps - timestamps[waterhitindex] + 0.5*frametime
theory = @. getv(timestamps/1000)
p1 = plot(timestamps[2:waterhitindex],[velocities[2:waterhitindex], theory[2:waterhitindex]], xlims = (timestamps[1],timestamps[end]),ylims = (1.8,2.025), label =["Measured" "Theoretical"])
xlabel!("Time Relative to Impact (ms)")
ylabel!("Velocity (m/s)")
watervelocity = (velocities[waterhitindex-1] + velocities[waterhitindex-1])/2
