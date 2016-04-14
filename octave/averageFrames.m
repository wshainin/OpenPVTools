

k = 1;
for i = 1:50:500
   avg = zeros(8*8*192, 1);
   for j = 0:49
      vec = sparse2dense(S1{i+j}.values, 8*8*192);
      avg += vec;
   
   end     
   
   out{k}.time = 0;
   out{k++}.values = dense2sparse(avg ./ 50);
end
