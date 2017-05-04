%%This will read the first and last dicom you collected in a session and
%%extract acquisition time for the first dicom as well as content time for the
%%last dicom (acquisition time is onset of volume collection; content time
%%is the end). This information is printed to 'output' struct.  
function [Dicom]= DicomLengths(seq, subName, seqName, checkMissing)

dicomDir = dir2([seq '/*.dcm']);
dicomDir = extractfield(dicomDir,'name');
Dicom.numDicoms = size(dicomDir,2);
% idx = find(strcmp([dicomDir], '.'));
% idx2 = find(strcmp([dicomDir], '..'));
% remove=horzcat(idx,idx2)';
% dicomDir(remove) = [];
for seqDicomsNum = 1:Dicom.numDicoms;
    dicomNum(seqDicomsNum) = str2double(dicomDir{1,seqDicomsNum}(end-7:end-4));
end
dicomDir=sort(dicomDir);
dicomSequence_diff = diff(dicomNum);
dicomSequence_find = find([dicomSequence_diff inf]>1);
dicomSequence_length = diff([0 dicomSequence_find]);
dicomSequence_endpoint = cumsum(dicomSequence_length);

switch checkMissing
    case checkMissing == 1
        if size(dicomSequence_length,2) > 1;
            missingDicom = dicomNum(1,dicomSequence_endpoint(1,1));
            disp(['Something is wrong with your DICOMS. Im guessing that you are missing dicom number: ' num2str(missingDicom)]);
            return
        end
end
% if strcmp(imageProcessingToolbox,'IPT') == 1
%     lastDicomHD = dicominfo([seq '/' dicomDir{1,Dicom.numDicoms}]);
%     firstDicomHD = dicominfo([seq '/' dicomDir{1,1}]);
%     Dicom.lastDicom=TimeConverter(str2num(lastDicomHD.ContentTime));
%     Dicom.firstDicom=TimeConverter(str2num(firstDicomHD.AcquisitionTime));
% end
% if strcmp(imageProcessingToolbox,'SPM') == 1
lastDicomHD = read_dicom_headers([seq '/' dicomDir{1,Dicom.numDicoms}],false);
firstDicomHD = read_dicom_headers([seq '/' dicomDir{1,1}],false);
lastDicomHD = lastDicomHD{1,1};
firstDicomHD = firstDicomHD{1,1};
Dicom.lastDicom=(lastDicomHD.ContentTime)*1000;
Dicom.firstDicom=(firstDicomHD.AcquisitionTime)*1000;
% end

Dicom.TR = lastDicomHD.RepetitionTime;
Dicom.DicomDur=Dicom.lastDicom-Dicom.firstDicom;
display(['Total scanning time for ' subName '''''s ' seqName ' was ' num2str(((Dicom.lastDicom-Dicom.firstDicom)/1000)/60) ' minutes according to DICOMS']);



