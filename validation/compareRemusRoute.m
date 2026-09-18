function results = compareRemusRoute(waypoints, generation, individual)
    arguments
        waypoints = []
        generation (1,1) double = 1
        individual (1,1) double = 1
    end
    results = compareVesselRoute("remus100",waypoints,generation,individual);
end
