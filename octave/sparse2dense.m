function denseVector = sparse2dense(pvpSparseValues, vecLength)
   denseVector = zeros(vecLength,1);
   denseVector(pvpSparseValues(:, 1) + 1) = pvpSparseValues(:, 2);
end%function
