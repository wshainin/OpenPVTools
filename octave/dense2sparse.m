function sparseVector = dense2sparse(pvpDenseValues)
   sparseVector(:,1) = find(pvpDenseValues);
   sparseVector(:,2) = pvpDenseValues(sparseVector(:,1));
   sparseVector(:,1) = sparseVector(:,1) - 1;


end%function
