function plotFinalPath()
    resultsPathInfo = what("ExperimentsResults");
    resultsPath = char(resultsPathInfo.path);
    %vesselStateFilePath = append(resultsPath, "/", "remus100/WP-6-iter")%,"/Ex-", string(experimentNumber),"/FinalPath");
    vesselStateFilePath = "/Users/karolinen/Documents/MATLAB/Simulators/ExperimentsResults/remus100/KneePointSel-exNum2/WptIdx-6-iter"; 
    for iter = 1:100
        fileLocation = append(vesselStateFilePath,string(iter));
        load(fileLocation,"simdataTemp");
        simdata = simdataTemp;
        eta = simdata(:,18:23);
        fullpath = [eta(:,1) eta(:,2) eta(:,3)];
        angles = [eta(:,4) eta(:,5) eta(:,6)]; 
        pointsMatrix = [0 0 0];
        %plotShipPath(fullpath, pointsMatrix, 5);

        %ointsMatrix = [wpt.pos.x wpt.pos.y wpt.pos.z];
        xpoints = pointsMatrix(:,1);
        ypoints = pointsMatrix(:,2);
        zpoints = pointsMatrix(:,3);

        xpath = fullpath(:,1);
        ypath = fullpath(:,2);
        zpath = fullpath(:,3);
        figure
        plot3(ypath, xpath, zpath)
        hold on
        plot3(ypoints, xpoints, zpoints, 'ro', 'MarkerSize', 5);
        hold off;
        grid on;
        set(gca, 'ZDir', 'reverse');
        xlabel("y axis")
        ylabel("x axis")
        zlabel("z axis")
        view(-25, 30)


    end
end