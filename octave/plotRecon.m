function plotRecon(imagePVP, reconPVP)
   out = "Recon";
   system(['mkdir ', out]);
   image = readpvpfile(imagePVP);
   recon = readpvpfile(reconPVP);
   frames = min(numel(recon), numel(image));
   %%for i = 1:frames
   for i = 800*8+399:800*8+400
      img = (permute(imadjust(image{i}.values, [min(image{i}.values(:)), max(image{i}.values(:))]), [2,1,3]));
      rec = (permute(imadjust(recon{i}.values, [min(recon{i}.values(:)), max(recon{i}.values(:))]), [2,1,3]));
      comb = imresize(horzcat(img, rec), 2);
      outFile = sprintf([out, '/%05d.png'],i);
      imwrite(comb, outFile);
      %%figure;
      %%imagesc(comb);
   end
end

