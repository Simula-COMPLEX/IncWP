classdef RandomSearchAlogrithm < ALGORITHM
%------------------------------- Reference --------------------------------
%------------------------------- Copyright --------------------------------
%--------------------------------------------------------------------------

    methods
        function main(Algorithm,Problem)
            % %% Generate random population
            % Population = Problem.Initialization(Problem.N, Algorithm.parameter);
            % %Problem = savePopulation(Problem, Population, Algorithm.parameter);
            % [~,FrontNo,CrowdDis] = EnvironmentalSelection(Population,Problem.N);
            % Problem = savePopulation(Problem, Population, Algorithm.parameter);
            % 
            % %% Optimization
            % while Algorithm.NotTerminated(Population)
            %     MatingPool = TournamentSelection(2,Problem.N,FrontNo,-CrowdDis);
            %     %Offspring  = OperatorGA(Problem,Population(MatingPool));
            %     Offspring = GArealPoints(Problem,Population(MatingPool));
            %     Problem = savePopulation(Problem, Offspring, Algorithm.parameter);
            %     [Population,FrontNo,CrowdDis] = EnvironmentalSelection([Population,Offspring],Problem.N); % population changed here
            % end
            Algorithm.parameter.populationType = "random";
            Population = Problem.Initialization(Problem.N,Algorithm.parameter);
            Problem = savePopulation(Problem, Population, Algorithm.parameter);
            Algorithm.NotTerminated(Population)
            %numGeneration = Problem.generation;
         
            % Problem = savePopulation(Problem, Population, Algorithm.parameter);
            % numberOfEvaluations = length(Population);
            % Problem.FE = numberOfEvaluations;
            % 

            %% Optimization
            while Algorithm.NotTerminated(Population)
                % Population = Problem.Initialization(Problem.N, Algorithm.parameter);
                % numGeneration = numGeneration+1;
                % Problem.generation = numGeneration;
                % Problem = savePopulation(Problem, Population, Algorithm.parameter);
                % 
                % numberOfEvaluations = numberOfEvaluations + length(Population);
                % Problem.FE = numberOfEvaluations;
            end
        end
    end
end