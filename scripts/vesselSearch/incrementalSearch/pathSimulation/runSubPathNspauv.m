function [endIteration,reachedWaypoint, lengthOfPath, lastPoint, subpath, angles] = runSubPathNspauv(wpt, currentWaypointIndex, R_switch, environmentRandomValues,currentIterationNumber, prevIterationNumber, vesselResultsPath)
    numberOfSamples = size(environmentRandomValues,2); 
    if currentWaypointIndex == 2 %&& currentIterationNumber == 1 
        
        %% USER INPUTS
        h = 0.05;                           % Sampling time [s]
        N = numberOfSamples; %30000*2;                          % Number of samples to simulate
        
        % Initialize position and orientation
        xn = 0; yn = 0; zn = 0;             % Initial North-East-Down positions (m)
        phi = 0; theta = 0;                 % Initial Euler angles (radians)
        psi = atan2(wpt.pos.y(2) - wpt.pos.y(1), ...
            wpt.pos.x(2) - wpt.pos.x(1));   % Yaw angle towards next waypoint
        U = 1;                              % Initial speed (m/s)
        
        % Initial control and state setup
        theta_d = 0; q_d = 0;               % Initial pitch references
        psi_d = psi; r_d = 0; a_d = 0;      % Initial yaw references
        
        % Initialize ocean current parameters
        Vc = 0.3;                      % Horizontal speed (m/s)
        betaVc = deg2rad(20);          % Horizontal direction (radians)
        wc = 0.1;                      % Vertical speed (m/s)
        
        % Initialize propeller dynamics
        n = 1000;                      % Initial propeller speed (rpm)
        n_d = 1300;                    % Desired propeller speed (rpm)
        rangeCheck(n_d, 0, 1500);      % Check if within operational limits
        
        % Intitial state vector
        x = [U; zeros(5,1); xn; yn; zn; phi; theta; psi; 0; 0; 0; 0; n];
        
        %% UNCONSTRAINED CONTROL ALLOCATION
        % [tau2 tau3 tau5 tau6] = B_delta * [delta_r, delta_s, delta_bp, delta_bs]
        [~, ~, M, B_delta] = npsauv();  % Mass matrix M and input matrix B_delta
        
        % Pseudoinverse (Fossen 2021, Section 11.2.2)
        % [delta_r, delta_s, delta_bp, delta_bs] = B_pseudo * [tau5, tau6]
        W = diag([5 5 1 1]);   % 5 times more expensive to use delta_r and delta_s
        B_pseudo = inv(W) * B_delta' * inv(B_delta * inv(W) * B_delta');
        
        %% CONTROL SYSTEM CONFIGURATION
        % Setup for depth and heading control
        psi_step = deg2rad(-60);       % Step change in heading angle (rad)
        z_step = 30;                   % Step change in depth, max 1000 m
        rangeCheck(z_step,0,1000);
        
        % Integral states for autopilots
        z_int = 0;                     % Integral state for depth control
        theta_int = 0;                 % Integral state for pitch control
        psi_int = 0;                   % Integral state for yaw control
        
        % Depth controller (suceessive-loop closure)
        z_d = zn;                      % Initial depth target (m)
        wn_d_z = 0.02;                 % Natural frequency for depth control
        Kp_z = 0.1;                    % Proportional gain for depth
        T_z = 100;                     % Time constant for integral action in depth control
        
        % Closed-loop pitch and heading control parameters (rad/s)
        zeta_theta = 1.0;              % Damping ratio for pitch control (-)
        wn_theta = 1.2;                % Natural frequency for pitch control (rad/s)
        zeta_psi = 1.0;                % Damping ratio for yaw control (-)
        wn_psi = 0.8;                  % Natural frequency for yaw control (rad/s)
        
        % Heading autopilot reference model parameters
        zeta_d_psi = 1.0;              % Damping ratio for yaw control (-)
        wn_d_psi = 0.1;                % Natural frequency for yaw control (rad/s)
        r_max = deg2rad(10.0);         % Maximum turning rate (rad/s)
        
        % MIMO PID pole-placement algorithm (Algorithm 15.2 in Fossen 2021)
        Omega_n = diag([wn_theta wn_psi]);
        Zeta = diag([zeta_theta zeta_psi]);
        M = diag([M(5,5), M(6,6)]);
        Kp = M .* Omega_n.^2;              % Proportional gain
        Kd = M .* (2 * Zeta .* Omega_n);   % Derivative gain
        Ki = (1/10) * Kp .* Omega_n;       % Integral gain 
        
        %% ALOS PATH-FOLLOWING PARAMETERS
        Delta_h = 20;               % horizontal look-ahead distance (m)
        Delta_v = 20;               % vertical look-ahead distance (m)
        gamma_h = 0.001;            % adaptive gain, horizontal plane
        gamma_v = 0.001;            % adaptive gain, vertical plane
        M_theta = deg2rad(20);      % maximum value of estimates, alpha_c, beta_c
        
        % Additional parameter for straigh-line path following
        %R_switch = 5;               % radius of switching circle
        K_f = 0.4;                  % LOS observer gain
        
        %% MAIN SIMULATION LOOP
        simdata = zeros(N+1, 30);   % Preallocate table for simulation data
        ALOSdata = zeros(N+1, 4);   % Preallocate table for ALOS guidance data

        startIteration = 1;

        
    else
        vesselStateFilePath = append(vesselResultsPath, string(currentWaypointIndex-1),"-iter", string(prevIterationNumber));
 
        load(vesselStateFilePath);


        simdata = zeros(N+1, 30);  % Preallocate table for simulation data
        ALOSdata = zeros(N+1, 4);              % Preallocate table for ALOS guidance data
        % update with previous data
        simdata(startIteration,:) = simdataTemp;
        ALOSdata(startIteration,:) = ALOSdataTemp;
    end
    
    clear integralSMCheading ALOS3D 
    wayPoints = [wpt.pos.x wpt.pos.y wpt.pos.z];
    endWaypoint = wayPoints(end,:);
    reachedWaypoint = false;
    stopSimulation = false;
    endIteration = startIteration; 
    checkpointList = [];
    CheckpointDistance = 100; % todo tune? 
    numCheckPointsToCheck = 10; % todo tune 
    
    for i = startIteration:N+1
        t = (i-1) * h;             % Current simulation time

        % Measurement updates
        u = x(1);                  % Surge velocity (m/s)
        %v = x(2);                 % Sway velocity (m/s)
        %w = x(3);                 % Heave velocity (m/s)
        q = x(5);                  % Pitch rate (rad/s)
        r = x(6);                  % Yaw rate (rad/s)
        xn = x(7);                 % North position (m)
        yn = x(8);                 % East position (m)
        zn = x(9);                 % Down position (m), depth
        %phi = x(10);              % Roll angle (rad) 
        theta = x(11);             % PitchYaw angle (rad)
        psi = x(12);               % Yaw angle (rad)
        %delta_r = x(13);          % Rudder angle (rad)
        %delta_s = x(14);          % Stern plane (rad)
        %delta_bp = x(15);         % Port bow plane (rad)
        %delta_bs  = x(16);        % Starboard bow plane (rad)
        n = x(17);                 % Propeller shaft speed (rpm)
    
         % ALOS path-following
    
        % ALOS guidance law
        [psi_ref, theta_ref, y_e, z_e, alpha_c_hat, beta_c_hat] = ...
            ALOS3D(xn, yn, zn, Delta_h, Delta_v, gamma_h, gamma_v,...
            M_theta, h, R_switch, wpt);
    
        % ALOS observer
        [theta_d, q_d] = LOSobserver(theta_d, q_d, theta_ref, h, K_f);
        [psi_d, r_d] = LOSobserver(psi_d, r_d, psi_ref, h, K_f);
    
        ALOSdata(i,:) = [y_e z_e alpha_c_hat beta_c_hat];
    
    
        % MIMO PID controller for pitch and roll moments
        tau5 = -Kp(1,1) * ssa( theta - theta_d ) -Kd(1,1) * q ...
            - Ki(1,1) * theta_int;
        tau6 = -Kp(2,2) * ssa( psi - psi_d ) -Kd(2,2) * r ...
            - Ki(2,2) * psi_int;
    
        % Propeller command (RPM)
        if (n < n_d)
            n = n + 1;
        end
    
        % Control inputs
        u_com = [ (1/u^2) * B_pseudo * [tau5 tau6]'
            n                                    ];
        max_u = [deg2rad(20); deg2rad(20); deg2rad(20); deg2rad(20); 1500];
        u_com = sat(u_com, max_u);
    
        % Ocean current random walks with saturation
        %betaVc = sat(betaVc + 0.01 * h * randn, deg2rad(100));
        %Vc = sat(Vc + 0.05 * h * randn, 1.0);
        %wc = sat(wc + 0.01 * h * randn, 0.2);
        betaVc = sat(betaVc + 0.01 * h *  environmentRandomValues(1,i), deg2rad(100));
        Vc = sat(Vc + 0.05 * h *  environmentRandomValues(2,i), 1.0);
        wc = sat(wc + 0.01 * h *  environmentRandomValues(3,i), 0.2);
    
        % AUV dynamics 
        xdot = npsauv(x, u_com, Vc, betaVc, wc);
    
        % Store simulation data in a table
        simdata(i,:) = [t z_d theta_d psi_d r_d u_com' x' Vc betaVc wc];
    
        % Euler's integration method (k+1)
        x = x + h * xdot;
        z_int = z_int + h * ( zn - z_d );
        theta_int = theta_int + h * ssa( theta - theta_d );
        psi_int = psi_int + h * ssa( psi - psi_d );


       point = [xn yn zn];
       distanceToFinalWpt = pdist2(point, endWaypoint, 'euclidean');
       
       if distanceToFinalWpt < (R_switch) 
            stopSimulation = true;
            reachedWaypoint = true;
       end

       if mod(i,CheckpointDistance) == 0
           if length(checkpointList) > numCheckPointsToCheck
               if all(checkpointList((end-numCheckPointsToCheck):end) < distanceToFinalWpt) % new distance is larger than previous 
                   % change so that all of the points 
                   stopSimulation = true;
                   reachedWaypoint = false;
               end
           end
           checkpointList = [checkpointList; distanceToFinalWpt];

       end

       if stopSimulation
            vesselStateFilePath = append(vesselResultsPath, string(currentWaypointIndex),"-iter", string(currentIterationNumber));

            simdataTemp = simdata(i,:);
            ALOSdataTemp = ALOSdata(i,:);
            lastPoint = point;
            
            subpath = simdata(startIteration:i,17:19);
            angles = simdata(startIteration:i,20:22);
            clear wpt currentWaypointIndex endWaypoint environmentRandomValues currentIterationNumber prevIterationNumber lastWptIndex simdata ALOSdata checkpointList vesselResultsPath
            
            endIteration = i+1; 
            lengthOfPath = endIteration - startIteration;
            startIteration = endIteration;
            save(vesselStateFilePath)
            return 
       end

    end

    if (reachedWaypoint == false) && (i == (N+1)) % TODO comment out 
        % waypoint not reached within budget 
        vesselStateFilePath = append(vesselResultsPath, string(currentWaypointIndex),"-iter", string(currentIterationNumber));
        lastPoint = [xn yn zn];

        simdataTemp = simdata(i,:);
        ALOSdataTemp = ALOSdata(i,:);
        lastPoint = point;
        
        subpath = simdata(startIteration:i,17:19);
        angles = simdata(startIteration:i,20:22);

        clear wpt currentWaypointIndex endWaypoint environmentRandomValues currentIterationNumber prevIterationNumber lastWptIndex simdata ALOSdata vesselResultsPath
        %startIteration = i+1;
        
        endIteration = i+1; 
        lengthOfPath = endIteration - startIteration;
        % set next iterations start iteration
        startIteration = endIteration;
        save(vesselStateFilePath)
    end
    
            
end
