using Images, Plots, Printf, Statistics
include("imageprocessing.jl")

universaldimmingfactor = 8
firstcalibrationimg = 1
lastcalibrationimg = 10
calibrationwhitethreshold = 0.1
targetbrightness = 0.5
contrastadjustmentfactor = 3

imagenames = readdir("images/brightnessadjust")
frames = length(imagenames)
calibrationimgs = []
calibrationmasks = []
for i = firstcalibrationimg:1:lastcalibrationimg
    currentcalibrationimg = @. load("images/brightnessadjust/"*imagenames[i]) /universaldimmingfactor
    push!(calibrationimgs,deepcopy(currentcalibrationimg))
    push!(calibrationmasks,deepcopy(threshold(currentcalibrationimg,calibrationwhitethreshold)))
    #display(Gray.(calibrationmasks[i]))
end
calibrationweights = whitecalibrationweights(calibrationimgs,calibrationmasks,targetbrightness)
#display(Gray.(newimg))

for i = 10:1:30#frames
    img = @. load("images/brightnessadjust/"*imagenames[i]) /universaldimmingfactor
    #display(Gray.(img))
    imgsize = size(img)
    newimg = @. img*calibrationweights
    #TODO: smooth?
    contrastadjust!(newimg,contrastadjustmentfactor)
    display(Gray.(newimg))
    medianfilter!(newimg,3)
    display(Gray.(newimg))
    
end