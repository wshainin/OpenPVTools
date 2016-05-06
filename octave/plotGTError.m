while true
gte = readpvpfile("GroundTruthReconS1Error.pvp");
for i = 1:numel(gte)
   X(i,1) = sqrt(sum(gte{i}.values .^ 2));
end
plot(X);
sleep(5);
end

for i = 1 : 5
      rec = (permute(imadjust(recon{i}.values, [min(recon{i}.values(:)), max(recon{i}.values(:))]), [2,1,3]));
      figure;
      imagesc(rec);
end

correct = 0;
for i = numel(gt) - 1000 : numel(gt)
  [~,recon] = max(gtr{i}.values);
  ground = gt{i}.values +1;
  T(i - numel(gt) + 1001, 1) = ground;
  T(i - numel(gt) + 1001, 2) = recon;
  correct += isequal(ground, recon);
end
printf("%d/%d correct\n", correct, size(T(:,1)));

