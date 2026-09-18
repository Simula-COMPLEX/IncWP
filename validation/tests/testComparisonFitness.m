function tests = testComparisonFitness
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    testCase.TestData.oldPath = path;
    addpath(fullfile(root,'validation'));
    addpath(fullfile(root,'scripts','vesselSearch','globalSearch'));
end

function teardownOnce(testCase)
    path(testCase.TestData.oldPath);
end

function testIdenticalStraightRoutes(testCase)
    waypoints = [0 0;2 0;4 0];
    segments = {[0 0;1 0;2 0];[2 0;3 0;4 0]};
    path = vertcat(segments{:});
    [fitness,steps] = calculateComparisonFitness([2 0 4 0],waypoints,0.1, ...
        path,path,segments,segments,[1;1],[1;1],"");
    verifyEqual(testCase,steps.FullInstabilityFitness,[-1;-1]);
    verifyEqual(testCase,fitness.FullInstabilityFitness,[-1;-1]);
    verifyEqual(testCase,fitness.FullProximityFitness,[0;0]);
    verifyEqual(testCase,fitness.FitnessMatch,[1;1]);
end

function testLongerIncrementalPath(testCase)
    waypoints = [0 0;2 0;4 0];
    full = {[0 0;1 0;2 0];[2 0;3 0;4 0]};
    inc = {[0 0;1 1;2 0];[2 0;3 0;4 0]};
    [fitness,steps] = calculateComparisonFitness([2 0 4 0],waypoints,0.1, ...
        vertcat(full{:}),vertcat(inc{:}),full,inc,[1;1],[1;1],"");
    verifyEqual(testCase,steps.IncInstabilityFitness,[-sqrt(2);-1],'AbsTol',1e-12);
    verifyEqual(testCase,fitness.IncInstabilityFitness(1),-(sqrt(2)+1)/2,'AbsTol',1e-12);
    verifyEqual(testCase,fitness.FitnessMatch,[0;0]);
end

function testFailureAndUnavailableSegments(testCase)
    waypoints = [0 0;2 0;4 0];
    segments = {[0 0;1 0];[]};
    path = segments{1};
    [fitness,steps] = calculateComparisonFitness([2 0 4 0],waypoints,0.1, ...
        path,path,segments,segments,[0;NaN],[0;NaN],"");
    verifyEqual(testCase,steps.FullInstabilityFitness(1),-999999999);
    verifyTrue(testCase,isnan(steps.FullInstabilityFitness(2)));
    verifyFalse(testCase,fitness.Comparable(1));
    verifyTrue(testCase,isnan(fitness.FitnessMatch(1)));
end
