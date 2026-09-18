function [performance, figureNumber] = evaluateMarinerWaypoints(intialPath,intialDistanceBetweenWaypoints, intialSubpathDistances, initalPointsMatrix, R_switch, individual, figureNumber, savePlotPath, plotPath)
    Delta_h = 500;
    numPoints = length(individual)/2;
    wpt.pos.x = [0 individual(1:numPoints)]';
    wpt.pos.y = [0 individual((numPoints+1):end)]';
    pointsMatrix = [wpt.pos.x wpt.pos.y];
    [simdata, ~] = marinerPath(wpt, Delta_h, R_switch);
      
    x_mutated = simdata(:,5);
    y_mutated = simdata(:,6);
    generatedPath = [x_mutated y_mutated];

    [totalDistanceBetweenWaypoints, totalSubpathDistances, numMissingWaypoints] = calculatePathScores(intialPath, initalPointsMatrix, generatedPath, pointsMatrix, R_switch);
    
    performance = [totalDistanceBetweenWaypoints, totalSubpathDistances-intialSubpathDistances, numMissingWaypoints];
    
    if plotPath  
        %figurePath = append(savePlotPath,"/plots/","exNum", string(experimentNumber), "-figNum",string(figureNumber))
        figurePath = append(savePlotPath,"-figNum",string(figureNumber))        
        figureNumber = plot2Dpostion(wpt, simdata, R_switch, figureNumber, figurePath)
     end
end


function figureNumber = plot2Dpostion(wpt, simdata, R_switch, figureNumber, filelocation)
    scrSz = get(0, 'ScreenSize'); % Returns [left bottom width height]
    wayPoints = [wpt.pos.x wpt.pos.y];
    x     = simdata(:,5);
    y     = simdata(:,6);
    %% 2-D position plots with waypoints
    figure(figureNumber)
    set(gcf,'Position',[1,1, 1.0*scrSz(4),1.0*scrSz(4)],'Visible','off');
    hold on;
    plot(y,x,'b');  % Plot vehicle position
    plotStraightLinesAndCircles(wayPoints, R_switch);
    xlabel('East (m)', 'FontSize', 14);
    ylabel('North (m)', 'FontSize', 14);
    title('North-East Positions (m)', 'FontSize', 14);
    axis equal;
    grid on;
    set(findall(gcf,'type','line'),'linewidth',2);
    set(findall(gcf,'type','legend'),'FontSize',12);
    set(figureNumber,'Visible', 'on'); 
    saveas(gcf, append(filelocation, "-2Dposition.png"))
    figureNumber = figureNumber + 1
end


function plotStraightLinesAndCircles(wayPoints, R_switch)%, filelocation)
    legendLocation = 'northeast';
    
    % Plot straight lines and circles for straight-line path following
    for idx = 1:length(wayPoints(:,1))-1
        if idx == 1
            plot([wayPoints(idx,2),wayPoints(idx+1,2)],[wayPoints(idx,1),...
                wayPoints(idx+1,1)], 'r--', 'DisplayName', 'Line');
        else
            plot([wayPoints(idx,2),wayPoints(idx+1,2)],[wayPoints(idx,1),...
                wayPoints(idx+1,1)], 'r--','HandleVisibility', 'off');
        end
    end

    theta = linspace(0, 2*pi, 100);
    for idx = 1:length(wayPoints(:,1))
        xCircle = R_switch * cos(theta) + wayPoints(idx,1);
        yCircle = R_switch * sin(theta) + wayPoints(idx,2);
        plot(yCircle, xCircle, 'k');
    end

    legend('Vessel position','Straight-line path','Circle of acceptance',...
        'Location',legendLocation);
    %saveas(gcf, append(filelocation, "-NorthEastPosition.png"))
end


