[S1, S1hdr] = readpvpfile(["S1_50_5000.pvp"]);
vecLength = S1hdr.nx * S1hdr.ny * S1hdr.nf;
imageIndex = 1;
hamming = zeros(50,50);
for frame = 1:50:250000
   for perturbationY = 0:49 
      for perturbationX = 0:49 
         settleOne = sparse2dense(S1{frame + perturbationY}.values, vecLength);
         settleTwo = sparse2dense(S1{frame + perturbationX}.values, vecLength);
	 [hammingFrame,~,~] = compareActivities(settleOne, settleTwo);
         hamming(perturbationY+1, perturbationX+1) += hammingFrame;
      end
   end
   imageIndex++;
end
hamming /= imageIndex;
