%converts Dicom time stamp format(MPCU) to MDH time format(physio logs).
%The output is number of ms after midnight. 
%See: https://cfn.upenn.edu/aguirre/wiki/public:pulse-oximetry_during_fmri_scanning

function output = TimeConverter(time_in_secs)
numInteg = floor(time_in_secs);
numFract = time_in_secs - numInteg;
numDigits = numel(num2str(round(numInteg)));
numDec = sprintf('%0.4f',numFract);
tics = (str2num(numDec)*10000);
time_str = num2str(time_in_secs);
if numDigits == 6
    hrs=str2num(time_str(1:2));
    mins=str2num(time_str(3:4));
    secs=str2num(time_str(5:6));
end
if numDigits == 5
    hrs=str2num(time_str(1));
    mins=str2num(time_str(2:3));
    secs=str2num(time_str(4:5));
end
if numDigits == 4
    hrs=0
    mins=str2num(time_str(1:2));
    secs=str2num(time_str(3:4));
end
if numDigits == 3
    hrs=0
    mins=str2num(time_str(1));
    secs=str2num(time_str(2:3));
end
if numDigits == 2
    hrs=0
    mins=0
    secs=str2num(time_str(1:2));
end
if numDigits == 1
    hrs=0
    mins=0
    secs=str2num(time_str(1));
end
if numDigits == 0
    hrs=0
    mins=0
    secs=0
end
output=(hrs*60*60*1000)+(mins*60*1000)+(secs*1000)+(tics/10);
end


