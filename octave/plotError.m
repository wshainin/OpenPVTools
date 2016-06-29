function plotError(pvpPath)
    [errorData, errorHDR] = readpvpfile(pvpPath);
    for errorFrame = 1:numel(errorData)
        l2(errorFrame) = sum(sum(sum(errorData{errorFrame}.values)));
    end
    plot(l2)











end
