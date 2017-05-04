function [voltTimestamps] = ExtractVoltTimestamps(varargin);
voltData=varargin{1};
voltFooter=varargin{2};
Logloop={'LogStartMDHTime','LogStopMDHTime','LogStartMPCUTime','LogStopMPCUTime'};
for LogNum =1:size(Logloop,2);
     indLog=strfind(voltFooter,Logloop{1,LogNum}); %find when logging stopped
     TF=isempty(indLog); %throw error if log stop time not found
     if TF == 1
         errordlg(['Could not find ' Logloop{1,LogNum} '...something is wrong with your file footer']);
         error('Exiting ...');
     end;
     ind=find(not(cellfun('isempty', indLog)));
     voltTimestamps.(Logloop{1,LogNum})=str2num(voltFooter{ind(1,1)+1});
     clear indLog
     clear ind
 end;