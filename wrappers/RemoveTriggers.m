function [voltMat_noTrig, voltTime, samplingRate_hz] = RemoveTriggers(varargin)    
    voltData = varargin{1};
    voltTimestamps = varargin{2};
    trigOn=find(voltData{1} == 5000);  % find trigger on markers (trigger here has no association with scanner trigger experimenter uses. They indicate start of dicom acquisition.
        TF=isempty(trigOn);
        if TF == 1
            errordlg('Could not find trigger on times, data is uninterpretable. ');
            error('Exiting ...');
        end;
        voltMat_noTrig=voltData; % make a new matrix for our clean data
        voltMat_noTrig{1,1}(trigOn)=[]; %
        trigOff = find(voltMat_noTrig{1} == 5003);  % System uses identifier 5003 as trigger OFF
        TF=isempty(trigOff);
        if TF == 1
            errordlg('Could not find trigger off times, data is uninterpretable. ');
            error('Exiting ...');
        end;
        voltMat_noTrig{1,1}(trigOff)=[];
        voltMat_noTrig=voltMat_noTrig{1,1}(:,:);
        samplingRate_ms = round(((voltTimestamps.LogStopMDHTime-voltTimestamps.LogStartMDHTime)/size(voltMat_noTrig,1)));%samplingRate_ms = round(((voltTimestamps.LogStopMDHTime-voltTimestamps.LogStartMDHTime)/size(voltMat_noTrig,1))); %caclulate sampling rate of physio data in ms
        samplingRate_hz = 1000/(samplingRate_ms);
        voltTime=(1:length(voltMat_noTrig))./samplingRate_hz;