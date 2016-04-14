labels = dlmread("train_labels.dlm");
for i = 1 : size(labels)(1)
   gt{i,1}.time = 0;
   gt{i,1}.values = zeros(32,32,10);

   gt{i,1}.values(:,:,labels(i) + 1) = 1;
end
keyboard;
