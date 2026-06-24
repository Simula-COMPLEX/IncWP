


for mm=1:size(results_overall,1)
    %f_1 = calculateFitness(x(mm,:));
    G(mm,1) = results_overall(mm,1).Cost(1);
    G(mm,2) = results_overall(mm,2).Cost(2);
end

r=max(G);
% Approximation of Pareto set
P=paretofront(G);
% Hypervolume
r = [1 1];
v=hypervolume(G(P,:),r,100000);
