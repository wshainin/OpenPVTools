if (!exist("S1", "var"))
    printf("Loading S1...\n");
    fflush(stdout);
    [S1, S1hdr] = readpvpfile(["S1_50_5000.pvp"]);
end
if (!exist("S1hdr","var"))
    vecLength = 8*8*192;
else
    vecLength = S1hdr.nx * S1hdr.ny * S1hdr.nf;
end
printf("Computing Sparsity\n");
activity = zeros(vecLength, 5000);
for perturbation = 1:50
    printf("Computing Perturbation %d\n", perturbation);
    fflush(stdout);
    
    imageIndex = 1;
    for frame = perturbation:50:250000
        activity = sparse2dense(S1{frame}.values, vecLength);   
        l0(imageIndex, perturbation) = length(find(activity));
        l1(imageIndex, perturbation) = sum(sum(abs(activity)));

        imageIndex++;
    end
end
        
