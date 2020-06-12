function [Thetaout, X0, Xdot] = Baseline_fcnblock(OutData, X, CParameter)
%prealocate
Thetaout = [1; 1; 1];
Xdot = [0; 0];

omega = OutData(CParameter.GenSpeed)*2*pi/60;             %generator speed
theta = OutData(CParameter.BldPitch1)*2*pi/360;           %Use blade 1 pitch, CPC so all blades the same 

X0 = [omega; theta];

%% generator filter block
Enable = CParameter.Enable;
T63 = CParameter.T63;

%y = g(X,u)
omega_filter = X(1);

%change in state = f(X,u)
Xdot(1) = 1/T63*(omega - X(1));

%Determine of genfilter is on
if Enable > .5
else
   omega_filter = omega; 
end

%% CPC controler Block
theta_dot_FF = CParameter.theta_dot_FF;
Omega_g_rated = CParameter.Omega_g_rated;
theta_K = CParameter.theta_K;
kp = CParameter.kp;
Ti = CParameter.Ti;
theta_max = CParameter.theta_max;
theta_min = CParameter.theta_min;

%error signal
Error = (omega_filter - Omega_g_rated)/(1 + theta/theta_K);

%y = g(X,u)
theta = X(2) + Error * kp;
if theta > theta_max
    thetaout = theta_max;
elseif theta < theta_min
    thetaout = theta_min;
else
    thetaout = theta;  
end

%change in state = f(X,u)
Xdot(2) = 1/Ti*(thetaout - X(2)) + theta_dot_FF; 

%Blade pitch output 
Thetaout = [thetaout; thetaout; thetaout];
end