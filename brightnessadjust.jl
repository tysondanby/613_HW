using Images, Plots, Printf, Statistics, Measures
include("imageprocessing.jl")

universaldimmingfactor = 8
firstcalibrationimg = 1
lastcalibrationimg = 10
calibrationwhitethreshold = 0.1
targetbrightness = 0.5
contrastadjustmentfactor = 3
sampleframes = [10,13,15,17]

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
frames = []
for i = 10:1:30#frames
    img = @. load("images/brightnessadjust/"*imagenames[i]) /universaldimmingfactor
    #display(Gray.(img))
    rows,columns = size(img)
    newimg = @. img*calibrationweights
    brightadjustimg = deepcopy(newimg)
    #TODO: smooth?
    contrastadjust!(newimg,contrastadjustmentfactor)
    contadjustimg =deepcopy(newimg)
    #display(Gray.(newimg))
    medianfilter!(newimg,3,0.9)
    filtimg =deepcopy(newimg)
    #display(Gray.(newimg))
    newimg = sharpen(newimg,0.5)
    display(Gray.(newimg))
    if i in sampleframes
        figure = zeros(3*rows + 4,2*columns+2)
        figure[1:rows,1:columns] = img#original
        figure[1:rows,(end-columns+1):end] = brightadjustimg
        figure[rows+3:2*rows+2,1:columns] =contadjustimg
        figure[rows+3:2*rows+2,(end-columns+1):end] = filtimg
        zero = Int(round(columns/2) +1)
        figure[(end-rows+1):end,zero+1:zero+columns]=newimg#sharpen
        save("deliverables/3_frame_$i"*"_comparison.png",map(clamp01nan,Gray.(figure)))
        save("deliverables/3_frame_$i"*"_final.png",map(clamp01nan,Gray.(newimg))) 
    end
    push!(frames,deepcopy(newimg))
end


animation = @animate for i = 1:1:length(frames)
    plot(Gray.(frames[i]),xlims = (0,256),ylims = (0,176),xticks = [],yticks=[],bottommargin=-1.5mm,topmargin=-3mm,leftmargin = -4.5mm,rightmargin=-4.5mm)
end
gif(animation,"deliverables/3_anim.gif",fps = 10)