function [voltMat_aligned, voltTime_aligned] = ClipTimeseries(voltMat_noTrig, voltTime, voltSampling, voltTimestamp, clock, physioLag, seqTimestamps, seqName, subName, type, plotSwitch)

startPhysio = 0;
TR = seqTimestamps.TR;
lastDicom = seqTimestamps.lastDicom;
firstDicom = seqTimestamps.firstDicom;
numDicoms = seqTimestamps.numDicoms;

%check frequency again.
if strcmp(clock,'MPCU') == 1
    mriDur=(voltTimestamp.LogStopMPCUTime)/1000-(voltTimestamp.LogStartMPCUTime)/1000;
else
    mriDur=(voltTimestamp.LogStopMDHTime)/1000-(voltTimestamp.LogStartMDHTime)/1000;
end
samplingEstimate = size(voltMat_noTrig,1)/mriDur;
if samplingEstimate - voltSampling > 1.5
display(['Something has gone wrong...sampling Hz has changed drastically from ' voltSampling ' to' samplingEstimate ]);
end

%%This will clip entire physio scan by physioLag and SkipTR. 
SkipTR = [1+floor(3000/TR)]; %calculates number of dummy scans.
start = floor(startPhysio*(voltSampling/1000)+(TR*SkipTR)*(voltSampling/1000));

stop = floor(physioLag*(voltSampling/1000)+mod(length(voltMat_noTrig(1:end)),voltSampling) + voltSampling/2); %%not sure which to use
voltMat_noTrig = double(voltMat_noTrig((start)+1:end-(stop))'); 
voltTime = voltTime(start+1:end-stop);
voltTime = voltTime(:)-voltTime(1);

%This will calculate the offset. 
if strcmp(clock,'MPCU') == 1
    offset = firstDicom-voltTimestamp.LogStartMPCUTime;
    endClip = floor((lastDicom - voltTimestamp.LogStartMPCUTime)/(1000/voltSampling)); %endClip = floor((lastDicom - voltTimestamp.LogStartMPCUTime)/(1000/voltSampling));
else
    offset = firstDicom-voltTimestamp.LogStartMDHTime;
    endClip = floor((lastDicom - voltTimestamp.LogStartMDHTime)/(1000/(voltSampling)));
end
startClip = ceil((offset/1000)*voltSampling); 

%endClip = ceil(((offset/1000)+(numDicoms*TR/1000))*voltSampling); %Old
%line; using Dongbo's suggestion from Upenn: result is closer to scanning
%duration derived from dicom timestamps. (by ~500 ms).

%check to see if extracted physio values line up to length of scanning. 
lengthPhysioWindow = (endClip - startClip+1)*(1000/voltSampling);
if (seqTimestamps.DicomDur - lengthPhysioWindow) > (1000/voltSampling) %%|| (lengthPhysioWindow - seqTimestamps.DicomDur) > (1000/voltSampling) CURRENTLY DOES NOT WORK
    errordlg(['Error in ' subName ' for ' seqName ' : extracted physio time window doesnt match length of scanning derived from the dicoms of this session.']);
    error('Exiting ...');
end

if plotSwitch == 1
    try
    figure
    windowPlot = startClip-60*100; %this is 2 minutes (120/2)*100
    windowMat = voltMat_noTrig(1,windowPlot:startClip-1);
    windowData = mean(reshape(windowMat,50,[]))';
    plot(windowData);
    title([type ' data 2 minutes before start of ' seqName ' for subject ' subName]);
    xlabel('Seconds');
    ylabel('Voltage');
    
    catch me
         
        fprintf('Something is wrong with your files...there is not enough physio data to extract the last two minutes before dicom acquisition for this scan %s\n',me.message)
    
    end
    
end

if endClip - startClip < numDicoms*100 && startClip>0 %account for scanner variability; ie sampling rate may not match physio bins 200 ms
    lastStart = endClip;
    lastEnd = endClip + (numDicoms*100 - (endClip - startClip));
    try
    last_voltMat_aligned = mean(voltMat_noTrig(lastStart:lastEnd));
    last_voltTime_aligned = mean(voltTime(lastStart:lastEnd));
    catch me
        fprintf('Something is wrong with your files...there is not enough physio data to extract last dicom physiodata %s\n',me.message)
    end
    
end

%start clip is negative (i.e. T1?)
if startClip < 0
    h = warndlg(['Analysis of ' subName ' ' seqName ' shows a dicom acquisition time BEFORE physio data collection was started. This may be normal if Pat did not yet turn on physio collection.']);
    startClip = 1;
end

%endClip can be larger than voltMat on last run because we remove last 1040
%ms of physio recording for accuracy. It may also be less than 40 ms longer
%than end of scan due to bins not matching up perfectly (i.e. first physio
%bin of 20 ms for physio doesn't ever match with the first 20 ms of
%scanning),and slight variation in sampling rate over time that we can't account for (i.e. change of 0-0.1 ms for true bin size vs modeled of 19-20 ms).
if (endClip > size(voltMat_noTrig,2)); 
    voltMat_noTrig_clipped=voltMat_noTrig(startClip:end);
    voltTime_aligned=voltTime(startClip:end);
else
    voltMat_noTrig_clipped=voltMat_noTrig(startClip:endClip);
    voltTime_aligned=voltTime(startClip:endClip);
end

voltDataSize=size(voltMat_noTrig_clipped,2);
n=round(voltDataSize/numDicoms);
voltMat_aligned=arrayfun(@(i) mean(voltMat_noTrig_clipped(i:i+n-1)),1:n:length(voltMat_noTrig_clipped)-n+1)';

if exist('last_voltMat_aligned','var')
    voltMat_aligned(numDicoms,1) = last_voltMat_aligned;
    voltTime_aligned(numDicoms,1) = last_voltTime_aligned;
end

display(['Total data extracted for ' seqName ' was ' num2str((((lengthPhysioWindow)/1000)/60)) ' minutes long.']);

