function tests = testFullPathSimulatorsWithEarlyStopping
% Execute only when MATLAB runs are authorized. No experiment files are used.
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    testCase.TestData.oldPath = path;
    addpath(genpath(fullfile(root,'frameworks','MSS')));
    addpath(fullfile(root,'scripts','vesselSearch','helpers'));
    addpath(fullfile(root,'scripts','vesselSearch','globalSearch', ...
        'pathSimulation','withEarlyStopping'));
end

function teardownOnce(testCase)
    path(testCase.TestData.oldPath);
    clear integralSMCheading ALOS3D LOSchi EKF_5states
end

function testShortEnvironmentBudgets(testCase)
    wpt.pos.x = [0; 1000; 2000];
    wpt.pos.y = [0; 500; 1000];
    wpt.pos.z = [0; 20; 40];
    for samples = [1 4]
        [data, guidance, state] = remus100pathWithEarlyStopping(wpt,5,zeros(2,samples));
        verifySize(testCase,data,[samples 23]);
        verifySize(testCase,guidance,[samples 4]);
        verifyEqual(testCase,state,zeros(samples,12));
        verifyEqual(testCase,data(:,1),(0:samples-1)'*0.05);
        again = remus100pathWithEarlyStopping(wpt,5,zeros(2,samples));
        verifyEqual(testCase,again,data);

        [data, guidance] = npsauvPathWithEarlyStopping(wpt,5,zeros(3,samples));
        verifySize(testCase,data,[samples 30]);
        verifySize(testCase,guidance,[samples 4]);
        verifyTrue(testCase,all(isfinite(data(:))));

        wpt2D = wpt;
        wpt2D.pos = rmfield(wpt.pos,'z');
        [data, state, switches] = marinerPathWithEarlyStopping(wpt2D,5,zeros(4,samples));
        verifySize(testCase,data,[samples 17]);
        verifySize(testCase,state,[samples 14]);
        verifyEqual(testCase,state,zeros(samples,14));
        verifyEmpty(testCase,switches);
        verifyTrue(testCase,all(isfinite(data(:))));
    end
end

function testMarinerExtraction(testCase)
    data = reshape(1:51,3,17);
    [angles, positions] = extractAnglesAndPath(data,[],"mariner");
    verifyEqual(testCase,angles,data(:,[2 3 4 7 8]));
    verifyEqual(testCase,positions,data(:,5:6));
end

function testThreeDimensionalExtraction(testCase)
    data = reshape(1:69,3,23);
    [angles, positions] = extractAnglesAndPath(data,[],"remus100");
    verifyEqual(testCase,angles,data(:,21:23));
    verifyEqual(testCase,positions,data(:,18:20));
    data = reshape(1:90,3,30);
    [angles, positions] = extractAnglesAndPath(data,[],"nspauv");
    verifyEqual(testCase,angles,data(:,20:22));
    verifyEqual(testCase,positions,data(:,17:19));
end
