using Images, Plots
include("imageprocessing.jl")

calibrationfactor = 9.25926e-5 #m/px
framerate = 2500 #fps
whitethreshold = 0.35 #1 is white
waterhitindex = 18 #index of first image after hitting the water. Found by looking at the images
sampleframes = [1,10,18]

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
centroidys::Vector{Float64} = zeros(frames)

for i = 1:1:frames
    img = load("images/abovewater/"*imagenames[i])
    imgthresh = threshold(img,whitethreshold)
    rows, columns = size(img)
    #display(img) #debug
    #display(Gray.(imgthresh))
    foundblack::Vector{Bool} = zeros(rows)
    for row = 1:1:rows
        for column = 1:1:columns
            if img[row,column] < whitethreshold
                foundblack[row] = true
            end
        end
    end
    croppeddimg = imgthresh[1:885,150:212]
    #display(Gray.(croppeddimg))
    ~,centroidys[i] = blackcentroid(croppeddimg)
    topblacks[i] = findfirst(x -> x==true,foundblack)
    bottomblacks[i] = findfirst(x -> x==true,reverse(foundblack))
    diameters[i] = findfirst(x -> x==false,foundblack[topblacks[i]:end]) - 1
    bottomsphere[i] = topblacks[i] + diameters[i] - 1
    if i in sampleframes
        figureimg = zeros(rows,3*columns+2)
        figureimg[:,1:columns] = img #original
        figureimg[:,(2+columns):(1+2*columns)] = imgthresh #threshold
        figureimg[1:885,(152+2*columns):(214+2*columns)] = croppeddimg #crop
        save("deliverables/1_frame_$i"*"_comparison.png",Gray.(figureimg))
    end
end
diameter = mean(diameters[1:10])
positions = @. calibrationfactor*(centroidys)#+0.5*diameters)
positions[18:end] = @. calibrationfactor*(topblacks[18:end]+0.5*diameter - 1)
timestamps = collect(0:frametime:frametime*(frames-1)) #these are timesteps for the velocity. They occur exactly between frames.
velocities = zeros(frames)
for i = 2:1:frames-1
    velocities[i] = (positions[i+1] - positions[i-1])/(2*frametime)
end

#ball hits water just before waterhitindex
timestamps = 1000*@. timestamps - timestamps[waterhitindex] + 0.5*frametime
theory = @. getv(timestamps/1000)
p1 = plot(timestamps[2:waterhitindex],[velocities[2:waterhitindex], theory[2:waterhitindex]], xlims = (timestamps[1],timestamps[end]),ylims = (1.8,2.05), label =["Measured" "Theoretical"])
xlabel!("Time Relative to Impact (ms)")
ylabel!("Velocity (m/s)")
watervelocity = velocities[waterhitindex-1]#(positions[waterhitindex] - positions[waterhitindex-1])/(frametime)

savefig(p1,"deliverables/1_plot.png")
#save(Gray.(img))