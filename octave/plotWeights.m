function plotWeights(directory)
   cwd = pwd;
   cd(directory);
   system('mkdir Weights');

   CP = glob("Checkpoint*");
   for k = 1:numel(CP)
      L(k,1) = str2double(CP{k}(11:end));
   end
   [L, idx] = sort(L);

   for l = 1:numel(CP)
      weightFile = [CP{idx(l)}, "/", "S1ToImageReconS1Error_W.pvp"];
      weightsdata = readpvpfile(weightFile);
      t = weightsdata{1}.time;
      pS = size(weightsdata{1}.values{1});
      weightsnumpatches = pS(4);
      subplot_x = ceil(sqrt(weightsnumpatches));
      subplot_y = ceil(weightsnumpatches/subplot_x);
      %%h_weightsbyindex = figure;

      for j = 1:weightsnumpatches  % Normalize and plot weights by weight index
         weightspatch{j} = weightsdata{1}.values{1}(:,:,:,j);
         weightspatch{j} = weightspatch{j}-min(weightspatch{j}(:));
         weightspatch{j} = weightspatch{j}*255/max(weightspatch{j}(:));
         weightspatch{j} = uint8(permute(weightspatch{j},[2 1 3]));
         %%subplot(subplot_y,subplot_x,j);
         %%imshow(weightspatch{j});
      end
      %%w = ceil(sqrt(weightsnumpatches));
      %%h = floor(sqrt(weightsnumpatches));
      for i = 1: subplot_y
         row{i} = horzcat(weightspatch{(i-1) * subplot_x + 1 : min(i*subplot_x, weightsnumpatches)}); 
      end
      row{subplot_y} = horzcat(row{subplot_y}, zeros(pS(1), pS(2) * subplot_x, pS(3)))(1:pS(1), 1:pS(2)*subplot_x, :);
      weights = vertcat(row{1:subplot_y});
      %%imshow(weights);
      %%outFile = ['Weights/' num2str(L(l)), ".png"];
      outFile = sprintf('Weights/%05d.png',l);
      %%imwrite(weights, outFile);
      imwrite(imresize(weights, 4), outFile);

      %%suffix='_W.pvp';
      %%[startSuffix,endSuffix] = regexp(directory,suffix);
      %%outFile = ['Weights/' directory(1:startSuffix-1) '_WeightsByFeatureIndex_' sprintf('%.08d',t) '.png']
      %%print(h_weightsbyindex,outFile);

   end
   cd(cwd);
end
