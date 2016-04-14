%%function [sqrError, percentChange] = computeAverageActivities(pvpFile, )


%%%%%%%%%% Plotting Hamming Distances For Different Magnitudes of Noise
range = {"00625"; "0125"; "025"; "05"; "1"; "10"};

for i = 1:5
   [S1, S1hdr] = readpvpfile(["cifarExplorePerturbations_", range{i}, "/S1.pvp"]);
   length = S1hdr.nx * S1hdr.ny * S1hdr.nf;
   j = 1;
   for k = 1:800:8000
      firstSettle  = sparse2dense(S1{k + 398}.values, length);
      perturbation = sparse2dense(S1{k + 399}.values, length);
      finalSettle  = sparse2dense(S1{k + 799}.values, length);

      hammingPerturb(j,1) = compareActivities(firstSettle, perturbation);
      hammingFinal(j++,1) = compareActivities(firstSettle, finalSettle);
   end
   hammings(i,:) = [mean(hammingPerturb), mean(hammingFinal)];
   hammingSTD(i,:) = [std(hammingPerturb), std(hammingFinal)];
end
hammings

h = figure;
hold on
X = [.00625; .0125; .025; .05; .1];
plot(X, hammings(:,1), 'b*', 'LineWidth', 5, 'MarkerSize', 10, X, hammings(:,2), 'cx', 'LineWidth', 5, 'MarkerSize', 10);

L = legend("At Perturbation", "Final Settling", 'Location', 'northwest');
%%L =findobj(gcf,'tag','legend')
legend('boxoff');

FS = findall(h,'-property','FontSize');
set(FS,'FontSize', 25);

title("Differences In Activity Vectors After Perturbation\n", "FontSize", 40);
xlabel("\nMean of Noise Distribution ", "FontSize", 40);
ylabel("Hamming Distance\n", "FontSize", 40);

LC = get(L, 'children');
set(LC(1:2), 'linewidth', 10)
set(LC(1:2), 'markersize', 20)
%%%%%%%%%% Plotting Hamming Distances For Different Magnitudes of Noise




%%%%%%%%%% Plotting Hamming Distances Between The LCA Encoding And After Perturbation(s)
[S1, S1hdr] = readpvpfile(["S1_50_5000.pvp"]);
vecLength = S1hdr.nx * S1hdr.ny * S1hdr.nf;
imageIndex = 1;
for frame = 1:50:250000
   settleZero = sparse2dense(S1{frame}.values, vecLength);
   for perturbation = 1:49 
      settleCompare = sparse2dense(S1{frame + perturbation}.values, vecLength);
      [hamming(imageIndex, perturbation), ~, ~] = compareActivities(settleZero, settleCompare);
   end
   imageIndex++;
end




hammings    = mean(hamming)

hammingsSTD = std(hamming)



h = figure;
hold on

errorbar(hammings, hammingsSTD, 'b*')
F = findall('-property', 'LineWidth');
set(F(1:2), 'LineWidth', 2);

%%plot(hamming1, 'r*', hamming2, 'g*', hamming3, 'b*') 
%%L = legend("One Perturbation", "Two Perturbations", "Three Perturbations", 'Location', 'northwest')
%%L = legend("One Perturbation", "Two Perturbations", "Three Perturbations", 'Location', 'eastoutside')

%%L =findobj(gcf,'tag','legend')

%%legend('boxoff');
%%xlabel("\nIndividual CIFAR Training Images", "FontSize", 20);

FS = findall(h,'-property','FontSize');
set(FS,'FontSize', 15);

title("Hamming Distances Between First Encoding\n and Increasing Perturbations\n", "FontSize", 20);
xlabel("Number of Perturbations", "FontSize", 20);
ylabel("Hamming Distance\n", "FontSize", 20);

LC = get(L, 'children');
set(LC(1:3), 'linewidth', 10)
%%set(LC(1:3), 'markersize', 20)
%%%%%%%%%% Plotting Hamming Distances Between The LCA Encoding And After Perturbation(s)


keyboard

%%%%%%%%%% Plotting average energy (10 frames) for each perturbation level
errorData1 = dlmread("cifarExplorePerturbations_00625/S1EnergyProbe.txt", ",",0,3);
errorData2 = dlmread("cifarExplorePerturbations_0125/S1EnergyProbe.txt", ",",0,3);
errorData3 = dlmread("cifarExplorePerturbations_025/S1EnergyProbe.txt", ",",0,3);
errorData4 = dlmread("cifarExplorePerturbations_05/S1EnergyProbe.txt", ",",0,3);
errorData5 = dlmread("cifarExplorePerturbations_1/S1EnergyProbe.txt", ",",0,3);
errorData6 = dlmread("cifarExplorePerturbations_10/S1EnergyProbe.txt", ",",0,3);

h = figure;
hold on
plot(errorData1(1:800), 'r', 'LineWidth', 2)
plot(errorData2(1:800), 'g', 'LineWidth', 2)
plot(errorData3(1:800), 'b', 'LineWidth', 2)
plot(errorData4(1:800), 'c', 'LineWidth', 2)
%%plot(errorData5(1:800), 'm', 'LineWidth', 2)
%%plot(errorData6(1:800), 'k', 'LineWidth', 2)



title("Energy of LCA Encoding With Perturbations\n", "FontSize", 30);
xlabel("Time Step", "FontSize", 30);
ylabel("Energy", "FontSize", 30);
L = legend("+/-.00625 Uniformly distributed", "+/-.0125", "+/-.025 <-Threshold", "+/-.05", 'Location', 'northeast');
legend('boxoff');

FS = findall(h,'-property','FontSize');
set(FS,'FontSize', 20);

LC = get(L, 'children');
set(LC(1:4), 'linewidth', 5)
%%set(LC(1:4), 'markersize', 20)

for i = 1:800:8000
   figure
   plot(errorData3(i:i+799), 'b', 'LineWidth', 2)
end


%%end
