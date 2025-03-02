include("math.jl")
function threshold(img,val)
    imgsize = size(img)
    newimg = zeros(imgsize)
    for row = 1:1:imgsize[1]
        for column = 1:1:imgsize[2]
            if img[row,column] > val
                newimg[row,column] = 1
            end
        end
    end
    return newimg
end

function zeropad(img)
    newimg = zeros(size(img)[1]+2,size(img)[2]+2)
    newimg[2:end-1,2:end-1] = img
    return newimg
end

function onepad(img)
    newimg = ones(size(img)[1]+2,size(img)[2]+2)
    newimg[2:end-1,2:end-1] = img
    return newimg
end

function extend(img)
    newimg = zeros(size(img)[1]+2,size(img)[2]+2)
    newimg[2:end-1,2:end-1] = img
    newimg[1,2:end-1] = img[1,:]
    newimg[end,2:end-1] = img[end,:]
    newimg[2:end-1,1] = img[:,1]
    newimg[2:end-1,end] = img[:,end]
    newimg[1,1] = img[1,1]
    newimg[1,end] = img[1,end]
    newimg[end,1] = img[end,1]
    newimg[end,end] = img[end,end]
    return newimg
end

function filter(img,mask)
    newimg = zeros(size(img))
    workimg = zeros(size(img))
    workimg = img
    rows, columns = size(img)
    masksize = size(mask)[1]
    if (masksize != size(mask)[2]) || (trunc(masksize/2) == round(masksize/2))
        @error("Only square, odd numbered masks are supported.")
    end
    zeropadding = (masksize - 1)/2
    if zeropadding > 0
        for i = 1:1:zeropadding
            workimg = extend(workimg)
        end
    end
    for row = 1:1:rows
        for column = 1:1:columns
            newimg[row,column] = sum(workimg[row:row+masksize-1,column:column+masksize-1] .* mask)
        end
    end
    return newimg
end

function edgefind(img)
    mask = [0  1 0;
            1 -4 1;
            0  1 0]
    return filter(img,mask)
end

function sharpen(img,strength)
    laplacian = edgefind(img)
    return img - strength*laplacian
end

function erode(img,r)
    refimg = deepcopy(img)
    structured::Array{Bool} = circlematrix(r)
    test::Array{Bool} = ones(2*r+1,2*r+1)
    newimg = zeros(size(img))
    onepadding = r
    if onepadding > 0
        for i = 1:1:onepadding
            refimg=onepad(refimg)
        end
    end
    rows,columns = size(img)
    for row = 1:1:rows
        for column = 1:1:columns
            booleanmatrix = (@. Bool(refimg[row:row+(2*r),column:column+(2*r)])) .|| ( .!(structured) )
            if booleanmatrix == test
                newimg[row,column] = 1
            end
        end
    end
    return newimg
end

function dilate(img,r)
    refimg = deepcopy(img)
    structured::Array{Bool} = circlematrix(r)
    test::Array{Bool} = zeros(2*r+1,2*r+1)
    newimg = zeros(size(img))
    zeropadding = r
    if zeropadding > 0
        for i = 1:1:zeropadding
            refimg=zeropad(refimg)
        end
    end
    rows,columns = size(img)
    for row = 1:1:rows
        for column = 1:1:columns
            booleanmatrix = (@. Bool(refimg[row:row+(2*r),column:column+(2*r)])) .&& ( .!(structured) )
            if booleanmatrix != test
                newimg[row,column] = 1
            end
        end
    end
    return newimg
end

function whitecalibrationweights(calibrationimgs,calibrationmasks,targetbrightness)
    @assert length(calibrationimgs) == length(calibrationmasks)
    R, C = size(calibrationimgs[1])
    weights = ones(R,C)
    mastermask = ones(R, C)
    #find master mask
    for i = 1:1:length(calibrationimgs)
        currentmask = calibrationmasks[i]
        for r = 1:1:R
            for c = 1:1:C
                if currentmask[r,c] == 0
                    mastermask[r,c] = 0
                end
            end
        end
    end
    for r = 1:1:R
        for c = 1:1:C
            if mastermask[r,c] == 1
                sum = 0
                for i = 1:1:length(calibrationimgs)
                    currentimg = calibrationimgs[i]
                    sum = sum + currentimg[r,c]
                end
                average = sum/length(calibrationimgs)
                weights[r,c] = deepcopy(targetbrightness/average)
            end
        end
    end

    return weights
end

function contrastadjust!(img,factor)
    R,C = size(img)
    for  r = 1:1:R
        for c = 1:1:C
            oldval = img[r,c]
            newval = oldval + factor * (oldval - 0.5)
            if newval > 1
                img[r,c] = 1
            elseif newval < 0
                img[r,c] = 0
            else
                img[r,c] = newval
            end
        end
    end
    return img
end

function medianfilter!(img,filtersize)
    R,C = size(img)
    extensions = (filtersize-1)/2
    refimg = img
    for i = 1:1:extensions
        refimg = extend(refimg)
    end
    
    for  r = 1:1:R
        for c = 1:1:C
            masked = []
            for fr = 1:1:(filtersize)
                for fc = 1:1:(filtersize)
                    push!(masked,refimg[r+fr-1,c+fc-1])
                end
            end
            img[r,c] = median(masked)
        end
    end
    return img
end

function medianfilter!(img,filtersize,weight)
    R,C = size(img)
    extensions = (filtersize-1)/2
    refimg = img
    for i = 1:1:extensions
        refimg = extend(refimg)
    end
    
    for  r = 1:1:R
        for c = 1:1:C
            masked = []
            for fr = 1:1:(filtersize)
                for fc = 1:1:(filtersize)
                    push!(masked,refimg[r+fr-1,c+fc-1])
                end
            end
            img[r,c] = weight*median(masked) + (1-weight)*img[r,c] 
        end
    end
    return img
end

function centeringfilter!(img,filtersize)
    R,C = size(img)
    extensions = (filtersize-1)/2
    refimg = img
    for i = 1:1:extensions
        refimg = extend(refimg)
    end
    
    for  r = 1:1:R
        for c = 1:1:C
            masked = []
            for fr = 1:1:(filtersize)
                for fc = 1:1:(filtersize)
                    push!(masked,refimg[r+fr-1,c+fc-1])
                end
            end
            if (img[r,c] == maximum(masked)) || (img[r,c] == minimum(masked))
                img[r,c] = median(masked)
            end
        end
    end
    return img
end

function rmblackobjects(img,bounds)#removes objects outside of bounds
    xboundmin,xboundmax=bounds[1]
    yboundmin,yboundmax=bounds[2]
    R,C = size(img)
    newimg = deepcopy(img)
    for i =1:1:R
        for j = 1:1:C
            if  (i >= yboundmin) && (i <= yboundmax) && (j >= xboundmin) && (j <= xboundmax) 
            else
                newimg[i,j] = 0
            end
        end
    end
    return newimg
end

function blackcentroid(img)
    pixels::Int64 = 0
    weight = (0.0 , 0.0)
    R,C = size(img)
    for x = 1:1:C
        for y = 1:1:R
            if img[y,x] < 0.5
                pixels = pixels +1
                weight = (weight[1] + x, weight[2] + y)
            end
        end
    end
    cx = weight[1]/pixels
    cy = weight[2]/pixels
    return cx,cy
end