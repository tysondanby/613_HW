using Images, Plots, Printf
include("imageprocessing.jl")

calibrationfactor = 9.483749e-5 #m/px
framerate = 2500 #fps
whitethreshold = 0.7 #1 is white
filtercuttoff = 30#px. set to remove noise coming from water surface. set as low as possible.
sharpenstrength = 0.04
watersurface = 69#px. by looking at one ofthe images with the cavity in them


#images are selected from just before being in water to the frame just after the pinch.
imagenames = readdir("images/belowwater")
frames = length(imagenames)
frametime = 1/framerate

volumes = []
times = []
t = -.5*frametime
for i = 1:1:frames#62
    img = load("images/belowwater/"*imagenames[i])
    #display(img)
    newimg = img[watersurface:580,90:294]
    display(Gray.(newimg)) 
    newimg = sharpen(newimg,sharpenstrength)
    #display(Gray.(newimg))
    newimg = threshold(newimg,whitethreshold)
    #display(Gray.(newimg))
    tempimg1 = dilate(newimg,4)
    tempimg1 = erode(tempimg1,4)
    tempimg2 = erode(newimg,1)
    tempimg2 = dilate(tempimg2,1)
    newimg[1:filtercuttoff,:] = tempimg1[1:filtercuttoff,:]
    #display(Gray.(newimg))
    newimg[filtercuttoff+1:end,:] = tempimg2[filtercuttoff+1:end,:]
    display(Gray.(newimg))

    #calculate disks
    rows, columns = size(newimg)
    volume = 0.0
    for i = 1:1:rows
        row = newimg[i,:]
        foundblack = false
        for j = 1:1:columns
            if row[j] <= 0.5
                foundblack = true
            end
        end
        d = 0.0
        if foundblack == true
            begincavity = findfirst(x -> x <= 0.5,row) #first black pixel
            endcavity = rows - (findfirst(x -> x <= 0.5,reverse(row))-2) #first white pixel after the cavity.
            d = calibrationfactor*(endcavity - begincavity)
        end
        volume = volume + calibrationfactor*pi*(d/2)^2
    end
    push!(volumes,deepcopy(volume*10000))
    push!(times,deepcopy(t))
    global t = t + frametime
end
#at the impact the volume is known to be zero, but the camera dosné capture it. add that data point.
plotvol = zeros(length(times)+1)
plott = zeros(length(times)+1)
plotvol[1] = volumes[1]
plott[1] = times[1]
plotvol[3:end] = volumes[2:end]
plott[3:end] = times[2:end]
p2 = plot(plott .* 1000,plotvol, label = "Cavity Volume", xlims = (0,30), ylims = (0,0.4), xticks = 0:5:30, yticks = 0:.05:.4)
pinchtime = 1000*(times[end]+times[end-1])/2
vline!([pinchtime], label = "Cavity Closure (t = "*@sprintf("%5.2f",pinchtime)*" ms)")