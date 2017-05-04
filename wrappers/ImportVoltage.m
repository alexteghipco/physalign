function [voltTimestamps,voltMat_noTrig,voltTime,samplingRate_hz] = ImportVoltage(varargin)
fclose('all'); 
file=varargin{1};
fid=fopen(file);
ignore=textscan(fid,'%s',5); %Ignore first 5 values, they are placeholders. (some say first 4)
voltData=textscan(fid,'%u16');
voltFooter=textscan(fid,'%s');
if ~size(voltFooter{1},1)
    errordlg('No footer found in log file. Something probably went wrong during data collection.');
    error('Exiting ...');
end;
voltFooter=voltFooter{1}; %make footer easier to work with
voltTimestamps = ExtractVoltTimestamps(voltData,voltFooter);
[voltMat_noTrig, voltTime, samplingRate_hz] = RemoveTriggers(voltData,voltTimestamps);
