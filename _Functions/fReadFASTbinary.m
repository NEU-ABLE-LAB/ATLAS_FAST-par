function [Channels, ChanName, ChanUnit, FileID, DescStr] = fReadFASTbinary(FileName,machinefmt)
%[Channels, ChannelNames, ChannelUnits] = fReadFASTbinary(FileName)
% Author: Bonnie Jonkman, National Renewable Energy Laboratory
% (c) 2012, 2013 National Renewable Energy Laboratory
%
% 22-Oct-2012: Edited for FAST v7.02.00b-bjj
% 25-Nov-2013: Edited for faster performance, as noted from 
%              https://wind.nrel.gov/forum/wind/viewtopic.php?f=4&t=953
%
% Input:
%  FileName      - string: contains file name to open
%
% Output:
%  Channels      - 2-D array: dimension 1 is time, dimension 2 is channel 
%  ChanName      - cell array containing names of output channels
%  ChanUnit      - cell array containing unit names of output channels
%  FileID        - constant that determines if the time is stored in the
%                  output, indicating possible non-constant time step
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
LenName = 10;  % number of characters per channel name
LenUnit = LenName;  % number of characters per unit name

if nargin<2
    machinefmt = 'native';
%     machinefmt = 'l';
end


FileFmtID = struct( 'WithTime',   1, ...               % File identifiers used in FAST
                    'WithoutTime',2, ...
                    'ChanLen',    3 );

fid  = fopen( FileName );
if fid > 0
    %----------------------------        
    % get the header information
    %----------------------------
    
    FileID       = fread( fid, 1, 'int16',machinefmt);             % FAST output file format, INT(2)

    NumOutChans  = fread( fid, 1, 'int32',machinefmt);             % The number of output channels, INT(4)
    NT           = fread( fid, 1, 'int32',machinefmt);             % The number of time steps, INT(4)

    if FileID == FileFmtID.WithTime
        TimeScl  = fread( fid, 1, 'float64',machinefmt);           % The time slopes for scaling, REAL(8)
        TimeOff  = fread( fid, 1, 'float64',machinefmt);           % The time offsets for scaling, REAL(8)
    else
        TimeOut1 = fread( fid, 1, 'float64',machinefmt);           % The first time in the time series, REAL(8)
        TimeIncr = fread( fid, 1, 'float64',machinefmt);           % The time increment, REAL(8)
    end
    
    ColScl       = fread( fid, NumOutChans, 'float32',machinefmt); % The channel slopes for scaling, REAL(4)
    ColOff       = fread( fid, NumOutChans, 'float32',machinefmt); % The channel offsets for scaling, REAL(4)

    LenDesc      = fread( fid, 1,           'int32',machinefmt );  % The number of characters in the description string, INT(4)
    DescStrASCII = fread( fid, LenDesc,     'uint8',machinefmt );  % DescStr converted to ASCII
    DescStr      = char( DescStrASCII' );                     
    
    if FileID == FileFmtID.ChanLen
        LenName = 15;
        LenUnit = LenName;
    end

    ChanName = cell(NumOutChans+1,1);                   % initialize the ChanName cell array
    for iChan = 1:NumOutChans+1 
        ChanNameASCII = fread( fid, LenName, 'uint8',machinefmt ); % ChanName converted to numeric ASCII
        ChanName{iChan}= strtrim( char(ChanNameASCII') );
    end
    
    ChanUnit = cell(NumOutChans+1,1);                   % initialize the ChanUnit cell array
    for iChan = 1:NumOutChans+1
        ChanUnitASCII = fread( fid, LenUnit, 'uint8',machinefmt ); % ChanUnit converted to numeric ASCII
        ChanUnit{iChan}= strtrim( char(ChanUnitASCII') );
    end            

    %disp( ['Reading from the file ' FileName ' with heading: ' ] );
    %disp( ['   "' DescStr '".' ] ) ;
    
    %-------------------------        
    % get the channel time series
    %-------------------------

    nPts        = NT*NumOutChans;           % number of data points in the file   
    Channels    = zeros(NT,NumOutChans+1);  % output channels (including time in column 1)
    
    if FileID == FileFmtID.WithTime
        [PackedTime, cnt] = fread( fid, NT, 'int32',machinefmt ); % read the time data
        if ( cnt < NT ) 
            fclose(fid);
            error(['Could not read entire ' FileName ' file: read ' num2str( cnt ) ' of ' num2str( NT ) ' time values.']);
        end
    end
        
        
    [PackedData, cnt] = fread( fid, nPts, 'int16' ); % read the channel data
    if ( cnt < nPts ) 
        fclose(fid);
        error(['Could not read entire ' FileName ' file: read ' num2str( cnt ) ' of ' num2str( nPts ) ' values.']);
    end
    
    fclose(fid);
    
    %-------------------------
    % Scale the packed binary to real data
    %-------------------------
    
%     ip = 1;
    for it = 1:NT
        Channels(it,2:end) = (PackedData(1+NumOutChans*(it-1):NumOutChans*it) - ColOff)./ColScl;
%         for ic = 1:NumOutChans
%             Channels(it,ic+1) = ( PackedData(ip) - ColOff(ic) ) / ColScl(ic) ;
%             ip = ip + 1;
%         end % ic       
    end %it

    if FileID == FileFmtID.WithTime
        t = ( PackedTime - TimeOff ) ./ TimeScl;
        % HACK to use constant dt
        dt2 = (t(end)-t(1))/(length(t)-1);
        t2 = t(1):dt2:t(end);
        %fprintf('dt = %.4f - dt = %.4f - len %d - len %d\n',t(2)-t(1),dt2,length(t),length(t2));
        if length(t2)~=length(t)
            warning('Problem in t')
            keyboard
        end
        Channels(:,1) = t2;
    else
        Channels(:,1) = TimeOut1 + TimeIncr*(0:(NT-1))';
    end
    
else
    error(['Could not open the FAST binary file: ' FileName]) ;
end

return;

