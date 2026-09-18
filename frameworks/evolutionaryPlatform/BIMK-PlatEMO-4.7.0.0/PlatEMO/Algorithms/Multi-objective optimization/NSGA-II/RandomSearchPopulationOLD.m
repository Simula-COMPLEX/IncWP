classdef RandomSearchPopulationOLD < ALGORITHM

    methods
        function main(Algorithm,Problem)
            %% Generate random population
            Population = Problem.Initialization(Problem.N+1);
            %Population = Problem.Initialization(1);
            %Offspring = randomizePopulation(Problem.N,Problem.D, Problem.minDistanceBetweenPoints, Problem.lower, Problem.upper, Problem.pointDimension);
            
            %[~,FrontNo,CrowdDis] = EnvironmentalSelection(Population,Problem.N);
            savePopulation(Problem, Population)

            %% Optimization
            while Algorithm.NotTerminated(Population)
                %MatingPool = TournamentSelection(2,Problem.N,FrontNo,-CrowdDis);
                %Offspring  = OperatorGA(Problem,Population(MatingPool));
                %Offspring = randomizePopulation(Problem.N,Problem.D, Problem.minDistanceBetweenPoints, Problem.lower, Problem.upper, Problem.pointDimension);
                %[Population,FrontNo,CrowdDis] = EnvironmentalSelection([Population,Offspring],Problem.N);
                Problem.FE     = Problem.FE + length(Population);
                %savePopulation(Problem, Offspring)
            end
        end
    end
end

