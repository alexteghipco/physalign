function physAlign(clock,physioLag,subFiles,pulsFiles,respFiles,outputDir,samplingRate,plotSwitch,excelSwitch,checkMissing)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%1.1 General Information%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function takes in .puls or .resp files and extracts relevant voltage 
% values in those files for each dicom within a sequence. The standard output 
% is a textfile called subject_sequence_physiotype.txt where each row 
% corresponds to the cumulative dicom number within that sequence. physiotype
% will either be 'hr' for heart-rate or 're' for respiration. A log of all
% events called LOG.txt will also be generated. This includes displayed 
% information and warnings. Subject names are extracted automatically from 
% your file as everything after the last slash in your input subFile.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%1.2 Variables and Usage%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subFiles - subFile is the nth row in subFiles, a 
% cell where rows correspond to all subject level folders you want to 
% analyze. Every subject level folder should contain sequence folders. These
% should in turn contain raw dicoms, and the script will ignore non .dcm 
% files in those folders. The script will sort your sequence level folders
% by extracting numbers from your folder names and sorting by ascending 
% order. In other words, it will assume you are running this over raw data. 
% As such it will also ignore phoenix reports and localizer scans. It will
% work on renamed data but then will assume order of the scans is as it 
% appears in folder. 

% respFiles | pulsFiles - For each subject folder you must also select a 
% resp or puls file. Each of these must be in the same order as your subject 
% folders and the variable must be a cell where every row corresponds to a 
% physio file. If you do not want to analyze one of the types of data leave 
% the cell variable empty.

% outputDir - You must also select an output directory for your files. The output files
% will be placed directly in here and will overwrite previous data of same
% name. This variable, is a string. 

% samplingRate - This should be left as the string auto for automatic 
% detection using the header of the physio files. (For SIEMENS)

% physioLag - This is the lag value for SIEMENS. Default is 1050 (ms). 
% Leave variable as double 1050.

% clock - This is the clock to which you would like to align. The options
% are the string MDH or MPCU. Leave as MDH for default. MDH is
% preferable because it is the scanner computer.

% plotSwitch - This will generate a figure for every sequence that will 
% plot the last 2 minutes prior to the start of said sequence. Use this
% to check if breath holding lines up. This is a double variable either 1
% or 0.

% excelSwitch - This is a double variable, either 1 or 0. If set to 1 it 
% will group tasks together by sequence and write them as csv files across 
% subs, physio file types, etc.

% checkMissing - This is a double variable, either 1 or 0. If set to 1 it
% will check your sequence folders for missing Dicoms.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%1.3.Wrappers%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-physAlign.m aligns your physio data by drawing on functions in the
% ./wrappers directory.
%-ClipTimeseries.m: extracts the portion of the physio file that
% corresponds to the length of scanning determined from the dicoms of the
% a particular sequence. Takes into account dummy scans and offsets the data
% by the difference between scan start timestamp (from physio file) and first
% dicom in the sequence.
%-DicomLengths.m: extracts acquisition time of first and last dicom in a
% sequence. Also makes sure there are no missing dicoms; tells you which
% dicom is missing. Tells you how long the sequence took to complete in log.
%-dir2.m is like dir command but ignores select type of files...for example
% hidden files, certain sequences (localizers, phoenix), etc.
%-ExperimentLengths.m: extracts first and last dicom of entire session for
% the subject. Prints this to log. If using raw dicoms will read first
% localizer dicom.
%-ImportVoltage.m: this reads physio files using textscan. Checks footer
% integrity.
% -padcat.m: This is to ensure we can load all text files into matlab. This
% pads NaNs and allows for horizontal concatenation of different
% dimensions.
% -read_dicom_headers.m: This is an spm script relying on
% spm_dicom_dict.mat in order to read in dicom header. 
%-RemoveTriggers.m: Removes triggers from voltage matrices.
% -sortStruct.m: This will sort a structure based on a field that is
% number.
%-TimeConverter.m: converts MDH time format to MPCU (msecs after midnight).
%-uipickfiles.m: gui for selecting folders.
%-VoltTime.m: Extracts MPCU/MDH timestamps to align data. This gets fed
% to ClipTimeseries.m

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Contact Alex @ ateghipc@u.rochester.edu for questions/comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath([pwd '/Wrappers']); %add support scripts
disp('%%%%%%%%%%%%%%%%%%%%%SUCCESFULLY ADDED SCRIPTS TO PATH%%%%%%%%%%%%%%%%%%%%%%%%%%');
waitBar = waitbar(0.1,'Starting Log...'); %loading bar indexes subject being analyzed
subCount = size(subFiles,1);
diary([outputDir '/LOG.txt']); %start logging all displayed information

for subNum = 1:subCount;
    sub = subFiles{subNum,1};
    disp(['%%%%%%%%%%%%%%%%%%%%%STARTING ANALYSIS ON SUBJECT ' num2str(sub) '%%%%%%%%%%%%%%%%%%%%%%%%%%']);
    lastSlash=ismember(sub,'/'); %find all characters that are forward slashes
    index = find(lastSlash); 
    index1 = index(1,end); %find last slash
    index2 = index(1,end-1); %find second to last slash
    subName = sub(index1+1:end); %get everything between last and second to last slash 
    baseDir = sub(index2+1:index1-1);
    
    if cellfun('isempty',pulsFiles) == 0 %only assign puls variable if it's not an empty cell
        puls = pulsFiles{subNum,1};
        disp(['bad pulse file; made variable zero']);
    end
    if cellfun('isempty',respFiles) == 0
        resp = respFiles{subNum,1}; %only assign resp variable if it's not an empty cell
        disp(['bad respiration file; made variable zero']);
    end
    
    d = dir2(sub); %remove hidden files, remove localizer and phoenix report
    d(~[d.isdir]) = []; %remove anything not a directory
    
    try
        for x = 1:size(d,1) %find all numbers in each d.name field 
            toFind = regexp(d(x).name,'\d*','Match'); 
            d(x).toSort = str2num(toFind{1,1}); %assign field toSort as first number in string (i.e. 10.MPRAGE2.epbold will get 10)
        end
        
        d = nestedSortStruct(d, 'toSort'); %now sort the entire structure by this double field
        disp(['sorted all of your files by extracted numbers from file names. If timing for whole experiment sounds wrong, you have folders with inconsistent numbers in them.']);
        
    catch me
        fprintf('You are not running this on raw data... %s\n',me.message) %warn through log if there are no numbers...will assume order from dir is correct order of collected sequences
    end
    
    seqPath = sub;
    
    lastSeq = [seqPath '/' d(end).name]; %test file ensures last and first sequences aren't phoenix or localizer...this is just a second safety measure to make sure there are correct dicoms in the most critical scans for data alignment
    testFile = dir(lastSeq);
    testFile([testFile.isdir]) = [];
    if isempty(testFile) == 1
        lastSeq = [seqPath '/' d(end-1).name];
    end
    clear testFile
    
    firstSeq = [seqPath '/' d(1).name]; % do the same for first sequence
    testFile = dir(firstSeq);
    testFile([testFile.isdir]) = [];
    if isempty(testFile) == 1
        firstSeq = [seqPath '/' d(2).name];
    end
    clear testFile
    
    ExperimentLength(subName,lastSeq,firstSeq); %total scanning time extraction
    
    %Import voltage matrices. Find footer and check integrity. Extract footer timestamps. Clip voltage matrices. Remove values printed from buffer at end of data collection,
    %remove triggers, and clip matrices based on MDH start and stop times.
    %(i.e. align physio files according to CPU from scanner computer; same one that prints acquisition times in DICOM header)
    if exist('puls','var') == 1
        [pulsTimestamps,pulsData,pulsTime,pulsSampling] = ImportVoltage(puls); %if puls variable exists, read puls file, check integrity of footer, extract timestamps
    end
    if exist('resp','var') == 1
        [respTimestamps,respData,respTime,respSampling] = ImportVoltage(resp); %if resp variable exists, read puls file, check integrity of footer, extract timestamps
    end
    
    disp(['Imported all of your physio data successfully.']);
    
    %check auto frequency detection...this is done even if you override
    %auto detection to ensure your input is applicable across both puls and
    %resp data.
    if exist('puls','var') == 1 && exist('resp','var') == 1
        if fix(pulsSampling) ~= fix(respSampling); %%check to make sure both physio file for this sub have the same sampling rate
            errordlg('ERROR: the sampling rate of your resp file does not match your puls file...something is wrong with your physio data');
            error('Exiting ...');
        else
            physioSampling = respSampling; %if auto detected resp and puls files match in sampling rate, then continue...
        end
    else
        if exist('puls','var') == 1
            physioSampling = pulsSampling; %if you do not have either a resp or pulse file, then we make sure we get autodetected sampling rate from a variable that exists 
        end
        if exist('resp','var')
            physioSampling = respSampling;
        end
    end
    
    switch samplingRate 
        case ischar(samplingRate) == 1 %if sampling rate is a string it is assumed you want to auto detect
            samplingRate = physioSampling;
            disp(['Sampling rate set automatically to 'num2str(physioSampling)]);
        case isnumeric(samplingRate) == 1
            if samplingRate ~= physioSampling %%if you indicated you wanted to use your own sampling rate, but the auto retrieved sampling rate doesn't match up, this will warn you about it.
                options.Interpreter = 'tex';
                % Include the desired Default answer
                options.Default = 'No';
                % Create a TeX string for the question
                qstring = 'Your selected sampling rate does not match with auto-sampling rate detection. Should I continue with your sampling rate?';
                choice = questdlg(qstring,'Beep Boop Error',...
                    'Yes','No',options)
                
                overrideSampling=inputdlg('You have chosen to manually input the sampling rate but it doesnt match up with your data...continue analysis with your sampling rate? (yes/no)');
                if strcmp(overrideSampling,'yes')
                    display('Continuing analysis with your selected sampling rate even though auto-sampling rate detection is different.');
                else
                    samplingRate = physioSampling;
                    display('Continuing analysis with auto-sampling rate detection because your selected sampling rate is different.');
                end
            end
    end
    
    seqCount = size(d,1); %now lets extract physio data for each sequence
    for seqNum = 1:seqCount
        seqName = d(seqNum,1).name;
        disp(['%%%%%%%%%%%%%%%%%%%%%STARTING ANALYSIS ON SEQUENCE: ' seqName '%%%%%%%%%%%%%%%%%%%%%%%%%%']);
        waitbar((seqNum+subNum/seqCount+subCount),waitBar,['Working on subject ' subName ' and sequence ' seqName]);
        seq = [sub '/' seqName];
        
        testFile = dir(seq); %get all dicoms in sequence folder
        testFile([testFile.isdir]) = []; %remove directories from list of files
        
        if isempty(testFile) == 0
            seqTimestamps = DicomLengths(seq, subName, seqName, checkMissing); %get the length of scan, and relevant dicom header info, plus check missing dicoms
            
            if exist('resp','var') == 1
                try
                    display('Working on resp data');
                    type = 'resp';
                    [respData_aligned, respTime_aligned] = ClipTimeseries(respData, respTime, respSampling, respTimestamps, clock, physioLag, seqTimestamps, seqName, subName, type, plotSwitch); %extract only the physio data for the sequence and downsample data from physio sampling rate to TR. Clock determines which header to use for clipping
                    dlmwrite([outputDir '/' baseDir '_' subName '_' seqName '_re.txt'],respData_aligned,' ');
                catch me
                    fprintf('One of your sequences contains dicoms that do not have readable TR %s\n',me.message);
                end
            end
            if exist('puls','var') == 1
                try
                    display('Working on puls data');
                    type = 'puls';
                    [pulsData_aligned, pulsTime_aligned] = ClipTimeseries(pulsData, pulsTime, pulsSampling, pulsTimestamps, clock, physioLag, seqTimestamps, seqName, subName, type, plotSwitch); %do the same for other data
                    dlmwrite([outputDir '/' baseDir '_' subName '_' seqName '_hr.txt'],pulsData_aligned,' ');
                catch me
                    fprintf('One of your sequences contains dicoms that do not have readable TR %s\n',me.message); %if there is a problem writting output it is because TR is missing form dicom header. This happens. for example in ASL scans.
                end
            end
        end
    end
end

switch excelSwitch 
    case excelSwitch == 1
        display('Writting excel files...');
        
        textDir = dir2(outputDir); %get all of the text files printed earlier
        
        for file = 1:size(textDir,1)
            patterns = findstr(textDir(file).name,'_'); %group sequences based on string between last underscore and the appended _hr.txt or _re.txt string used by script earlier.
            textDir(file).folderName = textDir(file).name(patterns(end-1)+1:patterns(end)-1);
            try
                
                textDir(file).physio = dlmread([outputDir '/' textDir(file).name]); %read in the files into the scructure
                
            catch me
                textDir(file).physio = 0; %if there are no voltage values for sequence. For example, lets say Pat started collecting physio after MPRAGE as she usually does... then set this to zero
                fprintf('I caught some empty text files in here... %s\n',me.message);
            end
        end
        
        C=cellfun(@char,{textDir.folderName},'unif',0); %find all unique scan names
        [~,idx]=unique(C);
        
        for i = 1:size(idx,1) %for each unique scan find all instances of that scan
            scans = find(arrayfun(@(n) strcmp(textDir(n).folderName, textDir(idx(i)).folderName), 1:numel(textDir)));
            
            scanPhysio = padcat(textDir(scans).physio);
            
            for o = 1:size(scans,2)
                string = textDir(scans(o)).name; %make cell for each file name that will be column header
                periods = findstr(string,'.'); %remove dots. header can't contain this.
                string(periods) =[];
                para1 = findstr(string,'('); %remove parentheses. header can't contain this.
                string(para1) =[];
                para2 = findstr(string,')');
                string(para2) =[];
                headers{o} = string(1:end-3); %remove _hr or _re appended by script
            end
            
            try
                T = array2table(scanPhysio);
                T.Properties.VariableNames=headers'; %make table with headers
                
                writetable(T,[outputDir '/' textDir(idx(i)).folderName '.csv'],'Delimiter',',','QuoteStrings',true); %write as csv
            catch me
                fprintf('Because your text files are empty some text files could not be concatenated into an excel file ... %s\n',me.message);
            end
            
            clear headers
            
        end
end

display('Done....')
diary off
close(waitBar);

