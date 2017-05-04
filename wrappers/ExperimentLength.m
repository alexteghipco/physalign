%This function gets Dicom header of very first dicom collected and very
%last dicom (i.e. first localizer and last sequence excluding phoenix
%folder).
function [dicomDur] = ExperimentLength(subName,lastSeq,firstSeq)

firstSessionDicom=dir([firstSeq '/*.dcm']);
lastSessionDicom=dir([lastSeq '/*.dcm']);

% if strcmp(imageProcessingToolbox,'IPT') == 1
%     firstSessionDicomHD=dicominfo([firstSeq '/' firstSessionDicom(1,1).name]);
%     firstSession_firstDicom=TimeConverter(str2num(firstSessionDicomHD.AcquisitionTime));
%     lastSessionDicomHD=dicominfo([lastSeq '/' lastSessionDicom(end).name]);
%     lastSession_lastDicom=TimeConverter(str2num(lastSessionDicomHD.ContentTime));
% end

% if strcmp(imageProcessingToolbox,'SPM') == 1
    firstSessionDicomHD = read_dicom_headers([firstSeq '/' firstSessionDicom(1,1).name],false);
    firstSessionDicomHD = firstSessionDicomHD{1,1};
    firstSession_firstDicom = firstSessionDicomHD.AcquisitionTime*1000;
    lastSessionDicomHD = read_dicom_headers([lastSeq '/' lastSessionDicom(end).name],false);
    lastSessionDicomHD = lastSessionDicomHD{1,1};
    lastSession_lastDicom=lastSessionDicomHD.ContentTime*1000;
% end

dicomDur=lastSession_lastDicom-firstSession_firstDicom;
display(['Total scanning time for subject ' num2str(subName) ' was ' num2str(((lastSession_lastDicom-firstSession_firstDicom)/1000)/60) ' minutes according to DICOMS']);



