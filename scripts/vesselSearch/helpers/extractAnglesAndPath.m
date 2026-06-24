function [angles, fullpath] = extractAnglesAndPath(simdata,ALOSdata, ship)
    % Extract the position path and angle/state variables from vessel output.
    if ship == "mariner"
        x = simdata(:,5);
        y = simdata(:,6);
        fullpath = [x y];

        u     = simdata(:,1); 
        v     = simdata(:,2);          
        r     = simdata(:,3);  
        psi   = simdata(:,4);
        delta = simdata(:,7);  
       
        angles = [u v r psi delta];
    elseif ship == "remus100"
        eta = simdata(:,18:23);
        x_mutated = eta(:,1);
        y_mutated = eta(:,2);
        z_mutated = eta(:,3);

        fullpath = [x_mutated y_mutated z_mutated];
        angles = [eta(:,4) eta(:,5) eta(:,6)]; 
    elseif ship == "nspauv"
        eta = simdata(:,17:22);
        x_mutated = eta(:,1);
        y_mutated = eta(:,2);
        z_mutated = eta(:,3);

        fullpath = [x_mutated y_mutated z_mutated];
        angles = [eta(:,4) eta(:,5) eta(:,6)];
    end
end
