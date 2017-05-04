function varargout = startPhysAlign(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%1.General Information%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function generates a GUI that draws on 'phys_gui.m' and
%'startPhysAlign.fig' and passes inputs into physAlign.m, which will 
%extract physiological data for a given subjects sequences.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%1.1 Usage%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% %%
%To use: type 'startPhysAlign' into the command window. Select folders
%for subjects and physio data. Choose a clock to align to. MDH is
%preferable because it is the scanner computer. Don't worry about any of
%the options, the script detects everything automatically (except 
%subs/physio files) but the gui allows you to override it. 

%See physAlign.m documentation for more information about the underlying
%scripts.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Contact Alex @ ateghipc@u.rochester.edu for questions/comments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Begin initialization code
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @startPhysAlign_OpeningFcn, ...
                   'gui_OutputFcn',  @startPhysAlign_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before startPhysAlign is made visible.
function startPhysAlign_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to startPhysAlign (see VARARGIN)

% Choose default command line output for startPhysAlign
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes startPhysAlign wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%%%%%%%%%%%%%%%%%%%%SET UP ALL OF THE MOUSOVER EVENTS%%%%%%%%%%%%%%%%%%%%%%
aa = sprintf('Select subject directories that contain all of that subjects sequence directories. You may select multiple subjects.');
set(handles.dicomFiles,'TooltipString',aa);
ab = sprintf('Select puls files in the order in which you selected your subject directories. Subject 1 should match puls file 1. If you do not want to analyze these select only resp files.');
set(handles.pulsFiles,'TooltipString',ab);
ac = sprintf('Select resp files in the order in which you selected your subject directories. Subject 1 should match resp file 1. If you do not want to analyze these select only puls files.');
set(handles.respFiles,'TooltipString',ac);
ad = sprintf('If you know physio data sampling rate, you can input it here. The script will automatically detect this for you otherwise.');
set(handles.samplingRate,'TooltipString',ad);
ae = sprintf('Scanners have different lag values. If you are not using SIEMENS, find and input the lag value corresponding to your scanner.');
set(handles.physioLag,'TooltipString',ae);
af = sprintf('You can choose which clock to align to, scanner computer or scanner. MDH should be more accurate. Number is in ms.');
set(handles.mdhButton,'TooltipString',af);
aff = sprintf('You can choose which clock to align to, scanner computer or scanner. MDH should be more accurate.');
set(handles.mpcuButton,'TooltipString',aff);
ag = sprintf('This option will generate a plot, for every sequence, of 2 minutes of resp and/or puls data prior to the start of scan. Use this to check if alignment corresponds to practice breath holding.');
set(handles.plotSwitch,'TooltipString',ag);
ah = sprintf('This option will concatenate the physio text files for each type of task into one spreadsheet. For example, all resting state scans will be grouped into one csv file.');
set(handles.excelSwitch,'TooltipString',ah);
ai = sprintf('This option will quickly look for missing dicoms in your data. If it finds dicom 8 is followed by dicom 10 it will tell you that you are missing dicoms 8 and 9. This does not affect accuracy of physio extraction unless first or last scan is affected.');
set(handles.checkMissing,'TooltipString',ai);
aj = sprintf('Select an output directory into which the script will place all physio data. Each row will correspond to a dicom in order from first to last dicom. Each subject and each sequence gets its own text file.');
set(handles.ouputDir,'TooltipString',aj);

% --- Outputs from this function are returned to the command line.
function varargout = startPhysAlign_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function goButton_Callback(hObject, eventdata, handles) %Analyze Button

ise = evalin( 'base', 'exist(''outputDir'',''var'') == 1' );
if ise == 1
    outputDir = evalin('base', 'outputDir');
else
    warnNow = warndlg('You have not selected an output directory','Missing Data');
end


ise = evalin( 'base', 'exist(''checkMissing'',''var'') == 1' );
if ise == 1
    checkMissing = evalin('base', 'checkMissing');
else 
    checkMissing = 1;
end

ise = evalin( 'base', 'exist(''excelSwitch'',''var'') == 1' );
if ise == 1
    excelSwitch = evalin('base', 'excelSwitch');
else
    excelSwitch = 0;
end

ise = evalin( 'base', 'exist(''plotSwitch'',''var'') == 1' );
if ise == 1
    plotSwitch = evalin('base', 'plotSwitch');
else
    plotSwitch = 0;
end

ise = evalin( 'base', 'exist(''clock'',''var'') == 1' );
if ise == 1
    clock = evalin('base', 'clock');
else
    clock = 'MDH';
end

ise = evalin( 'base', 'exist(''physioLag'',''var'') == 1' );
if ise == 1
    physioLag = evalin('base', 'physioLag');
    if physioLag ~= 1050
    warnNow = warndlg('You have chosen to override the default physio lag time for SIEMENS scanners.','Override Data');
    end
else
    physioLag = 1050;
end

ise = evalin( 'base', 'exist(''samplingRate'',''var'') == 1' );
if ise == 1
    samplingRate = evalin('base', 'samplingRate');
    if isnumeric(samplingRate)
        warnNow = warndlg('You have chosen to override the automatic frequency calculation.','Override Data');
    end
else
    samplingRate = 'auto';
end


ise = evalin( 'base', 'exist(''respFiles'',''var'') == 1' );
if ise == 1
    respFiles = evalin('base', 'respFiles');
else
    respFiles = {''};
end

ise = evalin( 'base', 'exist(''subFiles'',''var'') == 1' );
if ise == 1
    subFiles = evalin('base', 'subFiles');
else
    errordlg('you did not select subject folders');
    error('Exiting ...');
end

ise = evalin( 'base', 'exist(''pulsFiles'',''var'') == 1' );
if ise == 1
    pulsFiles = evalin('base', 'pulsFiles');
else
    pulsFiles = {''};
end

if isempty(respFiles) == 1 && isempty(pulsFiles) == 1
    errordlg('you did not select respiration or pulse files');
    error('Exiting ...');
end

if (isempty(respFiles) == 1 && size(pulsFiles,1) ~= size(subFiles,1) == 1) || (isempty(pulsFiles) == 1 && size(respFiles,1) ~= size(subFiles,1) == 1)
    errordlg('the number of physio files that you have selected does not match the number of subject folders you have selected');
    error('Exiting ...');
end

physAlign(clock,physioLag,subFiles,pulsFiles,respFiles,outputDir,samplingRate,plotSwitch,excelSwitch,checkMissing) 


function dicomFiles_Callback(hObject, eventdata, handles)
assignin('base','subFiles',uipickfiles('Prompt','Select all of your subject level folders.')');

function pulsFiles_Callback(hObject2, eventdata, handles)
assignin('base','pulsFiles',uipickfiles('Prompt','Select all of your pulse files in same order as sub folders.')');

function samplingRate_Callback(hObject, eventdata, handles)
get(hObject,'String');
if strcmp(handles.samplingRate.String,'Enter sampling frequency in ms') ~= 1
assignin('base','samplingRate',handles.samplingRate.String);
end

function samplingRate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function pushbutton5_Callback(hObject, eventdata, handles)
assignin('base','pulsFiles',uipickfiles('Prompt','Select all of your pulse files in same order as sub folders.')');

function checkMissing_Callback(hObject, eventdata, handles)
assignin('base','checkMissing',handles.checkMissing.Value);

function plotSwitch_Callback(hObject, eventdata, handles)
assignin('base','plotSwitch',handles.plotSwitch.Value);

function excelSwitch_Callback(hObject, eventdata, handles)
assignin('base','excelSwitch',handles.excelSwitch.Value);

function ouputDir_Callback(hObject, eventdata, handles)
assignin('base','outputDir',uigetdir(pwd,'Select your output directory.'));

function physioLag_Callback(hObject, eventdata, handles)
get(hObject,'String');
if strcmp(handles.physioLag.String,'1050 ms') ~= 1
assignin('base','physioLag',handles.physioLag.String);
end

function physioLag_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function respFiles_Callback(hObject, eventdata, handles)
assignin('base','respFiles',uipickfiles('prompt','Select all of your repiratory files.')');

function mdhButton_Callback(hObject, eventdata, handles)
assignin('base','clock','MDH');

function mpcuButton_Callback(hObject, eventdata, handles)
assignin('base','clock','MPCU');

function mdhButton_CreateFcn(hObject, eventdata, handles)

function mpcuButton_CreateFcn(hObject, eventdata, handles)

function uibuttongroup3_CreateFcn(hObject, eventdata, handles)
