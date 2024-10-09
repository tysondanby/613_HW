using Images, Plots, Printf
include("imageprocessing.jl")

calibrationfactor = 9.483749e-5 #m/px
framerate = 2500 #fps
whitethreshold = 0.7 #1 is white
filtercuttoff = 30#px. set to remove noise coming from water surface. set as low as possible.
sharpenstrength = 0.04
watersurface = 69#px. by looking at one ofthe images with the cavity in them
sampleframes = [10,62,69]

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
    imgcrop = deepcopy(newimg)
    #display(Gray.(newimg)) 
    newimg = sharpen(newimg,sharpenstrength)
    imgsharp = deepcopy(newimg)
    #display(Gray.(newimg))
    newimg = threshold(newimg,whitethreshold)
    imgthresh = deepcopy(newimg)
    #display(Gray.(newimg))
    tempimg1 = dilate(newimg,4)
    tempimg1 = erode(tempimg1,4)
    tempimg2 = erode(newimg,1)
    tempimg2 = dilate(tempimg2,1)
    newimg[1:filtercuttoff,:] = tempimg1[1:filtercuttoff,:]
    #display(Gray.(newimg))
    newimg[filtercuttoff+1:end,:] = tempimg2[filtercuttoff+1:end,:]
    #display(Gray.(newimg))

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
    push!(volumes,deepcopy(volume*1000000))
    push!(times,deepcopy(t))
    global t = t + frametime
    if i in sampleframes
        r1,c1 =size(img) 
        one = 1
        croppedfigureimg = zeros(r1,1*columns+1+c1)
        croppedfigureimg[:,1:c1] = img #original
        one = one + c1 + 1
        zero = one - 1
        croppedfigureimg[watersurface:580,one:(zero+columns)] = imgcrop#cropped
        figureimg = zeros(rows,4*columns+3)
        figureimg[:,1:columns] = imgcrop
        one = 1 + columns + 1
        zero = one - 1
        figureimg[:,one:(zero+columns)] = imgsharp #sharpen
        one = one + columns + 1
        zero = one - 1
        figureimg[:,one:(zero+columns)] = imgthresh #threshold
        one = one + columns + 1
        zero = one - 1
        figureimg[:,one:(zero+columns)] = newimg#DE top ED bottom
        save("deliverables/2_frame_$i"*"_crop.png",Gray.(croppedfigureimg))
        save("deliverables/2_frame_$i"*"_comparison.png",Gray.(figureimg)) 
    end
end
#at the impact the volume is known to be zero, but the camera dosné capture it. add that data point.
plotvol = zeros(length(times)+1)
plott = zeros(length(times)+1)
plotvol[1] = volumes[1]
plott[1] = times[1]
plotvol[3:end] = volumes[2:end]
plott[3:end] = times[2:end]
p2 = plot(plott .* 1000,plotvol, label = "Cavity Volume", xlims = (0,30), ylims = (0,40), xticks = 0:5:30, yticks = 0:5:40)
pinchtime = 1000*(times[end]+times[end-1])/2
vline!([pinchtime], label = "Cavity Closure (t = "*@sprintf("%5.2f",pinchtime)*" ms)")
xlabel!("Time After Impact (ms)")
ylabel!("Volume (cm^3)")
savefig(p2,"deliverables/2_plot.png")