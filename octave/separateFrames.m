i = 1;
for j = 1:100:500000
   for k = 0:49
      S1_400{i}.time     = S1{j+k}.time;
      S1_400{i++}.values = S1{j+k}.values;
   end
end
writepvpsparsevaluesfile("/home/wshainin/drive/_WORK/Sampling/S1_50_5000.pvp", S1_400, 8, 8, 192);
