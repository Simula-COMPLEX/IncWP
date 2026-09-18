function [simdata, state, newPointIndex] = marinerPath(wpt, R_switch, environmentRandomValues)
        clear LOSchi EKF_5states
        if nargin ==1, R_switch = 400; end
        wayPoints = [wpt.pos.x wpt.pos.y];

        % LOS parameters
        Delta_h = 500;                   % Look-ahead distance
        K_f = 0.2;                       % LOS observer gain
    
        % PID pole placement algorithm (Fossen 2021, Section 15.3.4)
        wn = 0.05;                       % Closed-loop natural frequency
        T = 107.3;                       % Nomoto time constant
        K = 0.185;                       % Nomoto gain constant
        Kp = (T/K) * wn^2;               % Proportional gain
        Td = T/(K*Kp) * (2*1*wn - 1/T);  % Derivative time constant
        Ti = 10 / wn;                    % Integral time constant
            
        % Reference model specifying the heading autopilot closed-loop dynamics
        wn_d = 0.1;                      % Natural frequency (rad/s)
        zeta_d = 1.0;                    % Relative damping factor (-)
        r_max = deg2rad(1.0);            % Maximum turning rate (rad/s)
        
        % Initial states
        x_hat = zeros(5,1);              % xhat = [ x, y, U, chi, oemga_chi ]'
        x = zeros(7,1);                  % x = [ u v r x y psi delta ]'
        U0 = 7.7175;                     % Nominal speed
        e_int = 0;                       % Autopilot integral state 
        delta_c = 0;                     % Initial rudder angle command
        psi_d = 0;                       % Initial desired heading angle
        chi_d = 0;                       % Initial desired course angle
        omega_chi_d = 0;                 % Initial desired course rate
        r_d = 0;                         % Initial desired rate of turn
        a_d = 0;                         % Initial desired acceleration
        
        % maximum limits
        delta_c_max = deg2rad(40);
        omega_chi_d_max = deg2rad(1);
    
        last_waypoint = wayPoints(end,:);
    nextWaypointIndex = 2;
    nextWaypoint = wayPoints(nextWaypointIndex,:);
    guidanceWpt.pos.x = wpt.pos.x(nextWaypointIndex-1:nextWaypointIndex);
    guidanceWpt.pos.y = wpt.pos.y(nextWaypointIndex-1:nextWaypointIndex);
        reached_every_waypoint = false;

        x_prd = [];
        P_prd = [];
        count = 1;

    
        t_f = 3000;              % Final simulation time (sec)
        h  = 0.05;                % Sampling time [s]
        Z = 2;                    % GNSS measurement frequency (2 times slower)
        
        t = 0;
        N = size(environmentRandomValues,2) - 1;
        simdata = zeros(N+1,17);             % Memory allocation
        state = zeros(N+1,14);

        newPointIndex = [];
    
     
    for i=1:N+1
        
            t = (i-1) * h;                   % Simulation time in seconds
        
            r    = x(3) + 0.0001 * environmentRandomValues(1,i); 
            xpos = x(4) + 0.01 * environmentRandomValues(2,i);
            ypos = x(5) + 0.01 * environmentRandomValues(3,i);
            psi  = x(6) + 0.0001 * environmentRandomValues(4,i);
        
            % EKF estimates used for path-following control
            U_hat = x_hat(3);
            chi_hat = x_hat(4);
            omega_chi_hat = x_hat(5);
        
            % Guidance and control system 
            % LOS course autopilot for straight-line path following
            [chi_ref, ~, updateToNextWaypoint] = LOSchi(xpos, ypos, Delta_h, R_switch, guidanceWpt);
        
            if updateToNextWaypoint
                newPointIndex = [newPointIndex; i ];
            end
            % LOS observer for estimation of chi_d and omega_chi_d
            [chi_d, omega_chi_d] = LOSobserver(...
                chi_d, omega_chi_d, chi_ref, h, K_f);
        
            omega_chi_d = sat(omega_chi_d, omega_chi_d_max); % Max value
        
            % PID course autopilot
            e = ssa(chi_hat - chi_d);
            delta_PID = (1/K) * omega_chi_d ...               % Feedforward
               -Kp * ( e + Td * (omega_chi_hat - omega_chi_d) ... % PID
               + (1/Ti) * e_int );                 
    
            delta_c = sat(delta_c, delta_c_max);             % Maximum rudder angle
        
            % Ship dynamics
            [xdot,U] = mariner(x,delta_c, U0);     
            
            % Store data for presentation
            simdata(i,:) = [t, x', U, psi_d, r_d, chi_d, omega_chi_d, delta_c, ...
                U_hat, chi_hat, omega_chi_hat]; 
            
            
            %state(i,:) = [x' xdot'];
            % Numerical integration
            x = x + h * xdot;                             % Euler's method
            e_int = e_int + h * e;
            delta_c = delta_c + h * (delta_PID - delta_c) / 1.0;
        
            % Propagation of the EKF states
            [x_hat,x_prd, P_prd, count] = EKF_5states(x_hat, x_prd, P_prd, count, xpos, ypos, h, Z, 'NED', ...
                100*diag([0.1,0.1]), 1000*diag([1 1]), 0.00001, 0.00001);
    
        distanceToNextWpt = pdist2([xpos ypos], nextWaypoint, 'euclidean');
        reachedWaypoint = distanceToNextWpt < R_switch/2 || updateToNextWaypoint;
        if reachedWaypoint
            clear LOSchi EKF_5states
            if nextWaypointIndex == size(wayPoints,1)
                reached_every_waypoint = true;
            else
                nextWaypointIndex = nextWaypointIndex+1;
                guidanceWpt.pos.x = wpt.pos.x(nextWaypointIndex-1:nextWaypointIndex);
                guidanceWpt.pos.y = wpt.pos.y(nextWaypointIndex-1:nextWaypointIndex);
                if nextWaypointIndex == size(wayPoints,1)
                    nextWaypoint = last_waypoint;
                else
                    nextWaypoint = wayPoints(nextWaypointIndex,:);
                end
            end
        end

        if reached_every_waypoint || i == N+1
            break;
        end
    end
    simdata(i+1:end,:) = [];
    state(i+1:end,:) = [];
end
