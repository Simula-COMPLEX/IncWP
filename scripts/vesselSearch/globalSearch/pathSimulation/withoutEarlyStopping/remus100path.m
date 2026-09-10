function [simdata , ALOSdata, state] = remus100path(wpt, R_switch, environmentRandomValues)
    
    clear integralSMCheading ALOS3D;    % Clear persistent states in controllers
    %% USER INPUTS
    h = 0.05;                           % Sampling time [s]
    N = 28000*2;                         % Number of samples to simulate


    % Initialize position and orientation
    xn = 0; yn = 0; zn = 0;             % Initial North-East-Down positions (m)
    phi = 0; theta = 0;                 % Initial Euler angles (radians)
    psi = atan2(wpt.pos.y(2) - wpt.pos.y(1), ...
        wpt.pos.x(2) - wpt.pos.x(1));   % Yaw angle towards next waypoint
    U = 1;                              % Initial speed (m/s)
    
    % Initial control and state setup
    theta_d = 0; q_d = 0;               % Initial pitch references
    psi_d = psi; r_d = 0; a_d = 0;      % Initial yaw references
    
    % State vector initialization
    % Using Euler angles
    x = [U; zeros(5,1); xn; yn; zn; phi; theta; psi];
    
    
    % Initialize ocean current parameters
    Vc = 0.5;                      % Horizontal speed (m/s)
    betaVc = deg2rad(30);          % Horizontal direction (radians)
    wc = 0.1;                      % Vertical speed (m/s)
    
    % Initialize propeller dynamics
    n = 1000;                      % Initial propeller speed (rpm)
    n_d = 1300;                    % Desired propeller speed (rpm)
    rangeCheck(n_d, 0, 1525);      % Check if within operational limits
    
    %% CONTROL SYSTEM CONFIGURATION
    % Setup for depth and heading control
    psi_step = deg2rad(-60);       % Step change in heading angle (rad)
    z_step = 30;                   % Step change in depth, max 100 m
    rangeCheck(z_step,0,100);
    
    % Integral states for autopilots
    z_int = 0;                     % Integral state for depth control
    theta_int = 0;                 % Integral state for pitch control
    psi_int = 0;                   % Integral state for yaw control
    
    % Depth controller (suceessive-loop closure)
    z_d = zn;                      % Initial depth target (m)
    wn_d_z = 0.02;                 % Natural frequency for depth control
    Kp_z = 0.1;                    % Proportional gain for depth
    T_z = 100;                     % Time constant for integral action in depth control
    Kp_theta = 5.0;                % Proportional gain for pitch control
    Kd_theta = 2.0;                % Derivative gain for pitch control
    Ki_theta = 0.3;                % Integral gain for pitch control
    K_w = 5.0;                     % Feedback gain for heave velocity
    
    % Heading control parameters (using Nomoto model)
    K_yaw = 5 / 20;                % Gain, max rate of turn over max. rudder angle
    T_yaw = 1;                     % Time constant for yaw dynamics
    zeta_d_psi = 1.0;              % Desired damping ratio for yaw control
    wn_d_psi = 0.1;                % Natural frequency for yaw control
    r_max = deg2rad(5.0);          % Maximum allowable rate of turn (rad/s)
    
    % Heading autopilot (Equation 16.479 in Fossen 2021)
    % sigma = r-r_d + 2*lambda*ssa(psi-psi_d) + lambda^2 * integral(ssa(psi-psi_d))
    % delta = (T_yaw*r_r_dot + r_r - K_d*sigma - K_sigma*(sigma/phi_b)) / K_yaw
    lambda = 0.1;
    phi_b = 0.1;                   % Boundary layer thickness
    
    K_d = 0.5;                 % Derivative gain for PID controller
    K_sigma = 0;               % Gain for SMC component in PID (inactive in PID mode)
    
    
    %% ALOS PATH-FOLLOWING PARAMETERS
    Delta_h = 20;               % horizontal look-ahead distance (m)
    Delta_v = 20;               % vertical look-ahead distance (m)
    gamma_h = 0.001;            % adaptive gain, horizontal plane
    gamma_v = 0.001;            % adaptive gain, vertical plane
    M_theta = deg2rad(20);      % maximum value of estimates, alpha_c, beta_c
    
    % Additional parameter for straigh-line path following
    K_f = 0.5;                  % LOS observer gain
    
    %% MAIN SIMULATION LOOP
    simdata = zeros(N+1, length(x) + 11);  % Preallocate table for simulation data
    ALOSdata = zeros(N+1, 4);              % Preallocate table for ALOS guidance data
    state = zeros(N+1,length(x)); 
    
    wayPoints = [wpt.pos.x wpt.pos.y wpt.pos.z];
    last_waypoint = wayPoints(end,:);
    nextWaypointIndex = 2;
    nextWaypoint = wayPoints(nextWaypointIndex,:);
    
    reached_every_waypoint = false;
    stopSimulation = false;

    checkpointList = [];
    % Early stopping: every 100 simulation steps, record the distance to the
    % current target waypoint. If the last 10 sampled distances are strictly
    % increasing, the trajectory is treated as diverging and the simulation
    % stops early.
    CheckpointDistance = 100;
    numCheckPointsToCheck = 10;
    
    
    for i = 1:N+1
        t = (i-1) * h;             % Current simulation time
    
        % Measurement updates
        u = x(1);                  % Surge velocity (m/s)
        v = x(2);                  % Sway velocity (m/s)
        w = x(3);                  % Heave velocity (m/s)
        q = x(5);                  % Pitch rate (rad/s)
        r = x(6);                  % Yaw rate (rad/s)
        xn = x(7);                 % North position (m)
        yn = x(8);                 % East position (m)
        zn = x(9);                 % Down position (m), depth
    
       
        phi = x(10); theta = x(11); psi = x(12); % Euler angles
       
    
        % Control system updates based on selected mode
       
    
       %ALOS path-following - Heading autopilot using the tail rudder (integral SMC)
       delta_r = integralSMCheading(psi, r, psi_d, r_d, a_d, ...
           K_d, K_sigma, 1, phi_b, K_yaw, T_yaw, h);
    
       % Depth autopilot using the stern planes (PID)
       delta_s = -Kp_theta * ssa( theta - theta_d )...
           - Kd_theta * q - Ki_theta * theta_int - K_w * w;
    
       % ALOS guidance law
       [psi_ref, theta_ref, y_e, z_e, alpha_c_hat, beta_c_hat] = ...
           ALOS3D(xn, yn, zn, Delta_h, Delta_v, gamma_h, gamma_v,...
           M_theta, h, R_switch, wpt);
    
       % ALOS observer
       [theta_d, q_d] = LOSobserver(theta_d, q_d, theta_ref, h, K_f);
       [psi_d, r_d] = LOSobserver(psi_d, r_d, psi_ref, h, K_f);
       if abs(r_d) > r_max, r_d = sign(r_d) * r_max; end
    
       % Ocean current dynamics
       if t > 800
           Vc_d = 0.65;
           w_V = 0.1;
           Vc = exp(-h*w_V) * Vc + (1 - exp(-h*w_V)) * Vc_d;
       else
           Vc = 0.5;
       end
    
       if t > 500
           betaVc_d = deg2rad(160);
           w_beta = 0.1;
           betaVc = exp(-h*w_beta) * betaVc + (1 - exp(-h*w_beta)) * betaVc_d;
       else
           betaVc = deg2rad(150);
       end
    
       betaVc = betaVc + (pi/180) * environmentRandomValues(1,i) / 20;
       Vc = Vc + 0.002 * environmentRandomValues(2,i);

    
       ALOSdata(i,:) = [y_e z_e alpha_c_hat beta_c_hat];
    
       
    
       % Propeller control (rpm)
       if (n < n_d)
           n = n + 1;
       end
    
       % Amplitude saturation of the control signals
       n_max = 1525;                                % maximum propeller RPM
       max_ui = [deg2rad(15) deg2rad(15) n_max]';   % deg, deg, RPM
    
       if (abs(delta_r) > max_ui(1)), delta_r = sign(delta_r) * max_ui(1); end
       if (abs(delta_s) > max_ui(2)), delta_s = sign(delta_s) * max_ui(2); end
       if (abs(n)       > max_ui(3)), n = sign(n) * max_ui(3); end
    
       ui = [delta_r -delta_s n]';                % Commanded control inputs
    
       % Store simulation data in a table
       simdata(i,:) = [t z_d theta_d psi_d r_d Vc betaVc wc ui' x'];
       
       % Propagate the vehicle dynamics (k+1), (Fossen 2021, Eq. B27-B28)
       % x = x + h * xdot is replaced by forward and backward Euler integration
       xdot = remus100(x, ui, Vc, betaVc, wc);
    
       Jmtrx = eulerang(x(10),x(11),x(12));
       x(1:6) = x(1:6) + h * xdot(1:6);        % forward Euler
       x(7:12) = x(7:12) + h * Jmtrx * x(1:6); % backward Euler
    
    
       % Euler's integration method (k+1)
       z_int = z_int + h * ( zn - z_d );
       theta_int = theta_int + h * ssa( theta - theta_d );
       psi_int = psi_int + h * ssa( psi - psi_d );

       point = [xn yn zn];
       if pdist2(point, last_waypoint, 'euclidean') < (R_switch/2) 
            reached_every_waypoint = true; 
       end

       if reached_every_waypoint == false
            distanceToNextWpt = sqrt( (nextWaypoint(1)-point(1))^2 + (nextWaypoint(2)-point(2))^2 + (nextWaypoint(3)-point(3))^2 );

            if distanceToNextWpt < R_switch  && nextWaypointIndex < size(wayPoints,1)
                    % Move the early-stopping target to the next waypoint once the
                    % current intermediate waypoint has been reached.
                    nextWaypointIndex = nextWaypointIndex + 1;
                    nextWaypoint = wayPoints(nextWaypointIndex,:);
                    checkpointList = [];
            end
            

            if mod(i,CheckpointDistance) == 0
                if length(checkpointList) > numCheckPointsToCheck
                    if all(checkpointList((end-numCheckPointsToCheck):end) < distanceToNextWpt)
                        stopSimulation = true;
                        reachedWaypoint = false;
                    end
                end
                checkpointList = [checkpointList; distanceToNextWpt];

            end
        end

       if reached_every_waypoint == true && i>= round(N/3) || stopSimulation == true
            simdata(i+1:end,:) = [];
            ALOSdata(i+1:end,:) = [];
            return
        end 
    
    end
end 
