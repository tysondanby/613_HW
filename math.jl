function circlematrix(r;scalingfactor = 1.0)
    matrix = zeros(2*r+1, 2*r+1)
    for i = 1:1:(2*r+1)
        for j = 1:1:(2*r+1)
            x = (i - r - 1)#*r/(r+.5)
            y = (j - r - 1)#*r/(r+.5)
            if sqrt(x^2+y^2) <= scalingfactor*r
                matrix[i,j] = 1
            end
        end
    end
    return matrix
end