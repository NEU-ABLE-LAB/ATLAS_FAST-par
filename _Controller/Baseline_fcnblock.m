function thetaout = Baseline_fcnblock(omega,theta,theta_dot_FF,T63,Enable,Omega_g_rated,theta_K,kp,Ti,theta_max,theta_min)

%% FilterGenSpeet Block (uses state X1)
%Define persistant Variable
persistent X1
if isempty(X1)
    X1 = 1;
    X0 = X1*omega;
end

X1_dot = 1/T63*(omega - X0 * X1); %cheese it since we cannot define X1 in terms of an input
 
omega_filter = X0 * X1;

X1 = X1 + X1_dot;
X0 = 1;             %cancel out initial condition                   

%Calculate X1_dot
if Enable > .5
else
   omega_filter = omega; 
end

%% CPC controler Block (Uses State X2)
persistent X2
if isempty(X2)
    X2 = 1;
    X0_2 = X2*theta;
end

%error signal
Error = (omega_filter - Omega_g_rated)/(1 + theta/theta_K);

X2_dot = 1/Ti*(fminmax(X0_2 * X2 + Error * kp,theta_max,theta_min) - X0_2 * X2) + theta_dot_FF; 

%output
thetaout = fminmax(X0_2 * X2 + Error * kp,theta_max,theta_min);
thetaout = [thetaout ; thetaout ; thetaout];   %all pitches the same

%next step in SS
X2 = X21 + X2_dot;
X0_2 = 1;                  %cancel out initial condition after first pass through function 










end

function y = fminmax(u,theta_max,theta_min)
y = u;
if u > theta_max
    y = theta_max;
end
if u < theta_min
    y = theta_min;
end    


end
