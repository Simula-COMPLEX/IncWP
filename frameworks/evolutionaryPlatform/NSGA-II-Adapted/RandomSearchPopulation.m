classdef RandomSearchPopulation < ALGORITHM

    methods
        function main(Algorithm,Problem)
            %% Generate random population
            Algorithm.parameter.populationType = "random";
            Population = Problem.Initialization(Problem.N,Algorithm.parameter);
            numGeneration = Problem.generation;
         
            Problem = savePopulation(Problem, Population, Algorithm.parameter);
            numberOfEvaluations = length(Population);
            Problem.FE = numberOfEvaluations;
           

            %% Optimization
            while Algorithm.NotTerminated(Population)
                Population = Problem.Initialization(Problem.N, Algorithm.parameter);
                numGeneration = numGeneration+1;
                Problem.generation = numGeneration;
                Problem = savePopulation(Problem, Population, Algorithm.parameter);

                numberOfEvaluations = numberOfEvaluations + length(Population);
                Problem.FE = numberOfEvaluations;
            end
        end
    end
end

