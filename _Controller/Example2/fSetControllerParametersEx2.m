function [Parameter] = fSetControllerParametersEx2(Parameter,...
    Controler, tmpSysMdl)
% Sets the controller parameter.
% This function takes a structure and supplements it with additional fields for the controller parameters.
% 
% NOTE: THE FIELDS ALREADY PRESENT IN THE INPUT STRUCTURE SHOULD NOT BE CHANGED. IT IS AGAINST THE COMPETITION's RULES.
% 
% 
% INPUTS:
%    Parameter: a structure containing information about the turbine and the operating conditions of the simulation
%
% OUTPUTS:
%    Parameter: the input structure supplemented with additional fields.
%
%    The (read only) fields present in the input structure are: 
%        % --- Turbine
%        Parameter.Turbine.Omega_rated = 12.1*2*pi/60 % Turbine rated rotational speed, 12.1rpm [rad/s]
%        Parameter.Turbine.P_el_rated  = 5e6 ; % Rated electrical power [W]
%        Parameter.Turbine.i           = 1/97; % The gear ratio
%        % --- Generator
%        Parameter.Generator.eta_el       = 0.944;                % [-]
%        Parameter.Generator.M_g_dot_max  = 15e3;                 % [-]
%        % --- PitchActuator, e.g.
%        Parameter.PitchActuator.omega         = 2*pi;             % [rad/s]
%        Parameter.PitchActuator.theta_max     = deg2rad(90);      % [rad]
%        Parameter.PitchActuator.theta_min     = deg2rad(0);       % [rad]
%        Parameter.PitchActuator.Delay         = 0.2;              % [s]
%        % -- Variable speed torque controller
%        Parameter.VSC   % Structure containing the inputs for the variable speed controller. READ ONLY.
%        % -- Initial Conditions, e.g.
%        Parameter.IC.theta   % Pitch angle [rad]              
%        % -- Simulation Params
%        Parameter.Time.TMax  % Simulation length [s]
%        Parameter.Time.dt    % Simulation time step [s]


%% Controller parameters for the Collective Pitch Controller (CPC)
% NOTE: these parameters are only used by NREL5MW_Baseline.mdl.
 % Delete them if another model is used
KP          = Controler(1);               % [s] detuned gains
KI          = Controler(2);               % [-]
                  
Parameter.CPC.kp                  = KP;                                % [s]
Parameter.CPC.Ti                  = KP/KI;                             % [s] 
Parameter.CPC.theta_K             = deg2rad(6.302336);                 % [rad]
Parameter.CPC.Omega_g_rated       = Parameter.Turbine.Omega_rated/Parameter.Turbine.i;  % [rad/s]
Parameter.CPC.theta_max           = Parameter.PitchActuator.theta_max; % [rad]
Parameter.CPC.theta_min           = Parameter.PitchActuator.theta_min; % [rad]

Parameter.CParameter = 0;


