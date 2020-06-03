% struct2bus(s, BusName)
%
% Converts the structure s to a Simulink Bus Object with name BusName
function BusObject = struct2bus(s)

% Obtain the fieldnames of the structure
sfields = fieldnames(s);

% Loop through the structure
for i = 1:length(sfields)
    
    % Create BusElement for each field
    elems(i) = Simulink.BusElement;
    elems(i).Name = sfields{i};
    elems(i).Dimensions = size(s.(sfields{i}));
    elems(i).DataType = class(s.(sfields{i}));
    elems(i).SampleTime = -1;
    elems(i).Complexity = 'real';
    elems(i).SamplingMode = 'Sample based';
    
end

% Create main fields of Bus Object and generate Bus Object in the base
% workspace.
BusObject = Simulink.Bus;
BusObject.HeaderFile = '';
BusObject.Description = sprintf('');
BusObject.Elements = elems;

