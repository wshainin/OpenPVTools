function pvpWeights(pvpFile)
   system('mkdir Weights');

   weightsdata = readpvpfile(pvpFile);
   numFrames = numel(weightsdata);
   for l = 1:100:numel(weightsdata)
   %%for l = numFrames
      pS = size(weightsdata{1}.values{1});
      weightsnumpatches = pS(4);
      subplot_x = ceil(sqrt(weightsnumpatches));
      subplot_y = ceil(weightsnumpatches/subplot_x);
      %%h_weightsbyindex = figure;

      for j = 1:weightsnumpatches  % Normalize and plot weights by weight index
         %%t = weightsdata{j}.time;
         weightspatch{j} = weightsdata{l}.values{1}(:,:,:,j);
         weightspatch{j} = imadjust(weightspatch{j}, [min(weightspatch{j}(:)), max(weightspatch{j}(:))]);
         weightspatch{j} = permute(weightspatch{j},[2 1 3]);
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
      imwrite(imresize(weights, 4), outFile);

      %%suffix='_W.pvp';
      %%[startSuffix,endSuffix] = regexp(directory,suffix);
      %%outFile = ['Weights/' directory(1:startSuffix-1) '_WeightsByFeatureIndex_' sprintf('%.08d',t) '.png']
      %%print(h_weightsbyindex,outFile);

   end
end
