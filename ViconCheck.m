function ViconCheck()
%% FIGURE GUI 
close all;
h = figure('Units', 'normalized', 'Color', [.925 .914 .847], 'Position', [0 0 1 0.91]);
set(h,'NextPlot', 'add', 'NumberTitle', 'off', 'Toolbar', 'figure')
Folder = uicontrol('String', 'Select folder', 'Units', 'normalized','FontSize',12,'FontWeight','Bold',...
    'Position', [.01 .95 .1 .04] , 'callback', @chooseFolderButtonselected_cb,...
    'TooltipString', 'choose folder 1');  
pathFolder = uicontrol('String', 'CSV Path', 'Units', 'normalized', 'Style', 'Text',...
    'Position', [.01 .91 .1 .03], 'BackgroundColor',  [1 1 1]);
currentFile = uicontrol('String', 'CSV File', 'Units', 'normalized', 'Style', 'Text',...
    'Position', [.01 .87 .1 .03], 'BackgroundColor',  [1 1 1]);
PertubationNumber = uicontrol('String', 'Pertubation Number', 'Units', 'normalized', 'Style', 'Text',...
    'Position', [.01 .82 .11 .03], 'BackgroundColor',  [1 1 1],'FontWeight','Bold','FontSize',12);
ListBoxPertubation = uicontrol('style','listbox','units','normalized','FontSize',12,'FontWeight','Bold',...
        'Position',[.01 .15 .05 .64],'string',{},...
        'callback', @listBoxPertu_call);
uiwait(h)
newPath=get(pathFolder,'string')
newPath=newPath{2,1}
files=dir(newPath);
for ind=3:size(files,1)
    if ~isempty(strfind(files(ind).name,'Vdata')) && isempty(strfind(files(ind).name,'Vdata2'))
        Vdata=importdata([newPath '\' files(ind).name]);
    end
    if ~isempty(strfind(files(ind).name,'Vdata2')) && ~isempty(strfind(files(ind).name,'Vdata'))
        Vdata2=importdata([newPath '\' files(ind).name]);
    end
end 
set(ListBoxPertubation,'string',{Vdata.StringPer}')
Vdata3 = Vdata2; % for hidden data
isPlotted = zeros(size(Vdata));
plotHandleBamper = zeros(size(Vdata));
plotHandleLeftCG = zeros(size(Vdata));
plotHandleRightCG = zeros(size(Vdata));
plotHandleLeftHCG = zeros(size(Vdata));
plotHandleRightHCG = zeros(size(Vdata));
plotHandleLeftTCG = zeros(size(Vdata));
plotHandleRightTCG = zeros(size(Vdata));
plotHandleCG = zeros(size(Vdata));
plotHandleLeftStep = zeros(size(Vdata));
plotHandleRightStep = zeros(size(Vdata));
plotHandleLeftStepA = zeros(size(Vdata));
plotHandleRightStepA = zeros(size(Vdata));
plotHandleLeftArm = zeros(size(Vdata));
plotHandleRightArm = zeros(size(Vdata));
isPlotted2 = zeros(size(Vdata));
plotHandleBamper2 = zeros(size(Vdata));
plotHandleCG2 = zeros(size(Vdata));
plotHandleLeftStep2 = zeros(size(Vdata));
plotHandleRightStep2 = zeros(size(Vdata));
plotHandleLeftArm2 = zeros(size(Vdata));
plotHandleRightArm2 = zeros(size(Vdata));
drawButton = uicontrol('String', 'Load', 'Units', 'normalized','FontSize',12,...
                        'Position', [.020 .06 .062 .058] , 'callback', @drawButtonselected_cb,...
                        'TooltipString', ' Plot selection ');
saveButton = uicontrol('String', 'Save', 'Units', 'normalized','FontSize',12,...
    'Position', [.100 .06 .062 .058] , 'callback', @saveButtonselected_cb,...
    'TooltipString', ' average ');
exportButton = uicontrol('String', 'Export', 'Units', 'normalized','FontSize',12,...
    'Position', [.180 .06 .062 .058] , 'callback', @exportButtonselected_cb,...
    'TooltipString', ' export '); 
 patientInfoLabel = uicontrol('String', 'Patient information', 'Units', 'normalized','FontSize',12, 'Style', 'Text',...
                             'FontWeight', 'bold','Position', [.845 .93 .13 .05], 'BackgroundColor',  [.925 .914 .847]);     
% 
% %%patient name                        
 patientNameLabel =  uicontrol('String', '', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
                             'Position', [.84 .91 .150 .03], 'BackgroundColor',  [1 1 1]);
%no step check box
 checkBoxStep = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[.17 .15 .05 .03],'string','no step',...
                 'callback', @checkBoxSteps_call);
listBoxStep = uicontrol('style','listbox','units','normalized','FontSize',11,...
                  'Position',[.395 .13 .05 .05],'string',{'Right';'Left';'No Step'},...
                 'callback', @listBoxSteps_call);
patientFirstLeg =  uicontrol('String', 'Side Of First Step:', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
                        'Position', [.340 .13 .05 .05]);
 %hide steps check box
 checkBoxHideSteps = uicontrol('style','checkbox','units','normalized','FontSize',11,...
      'Position',[.46 .06 .09 .03],'string','hide first step', 'Foregroundcolor', 'b',...
     'callback', @checkBoxHideSteps_call);
 
EndFirstStep = uicontrol('String', 'end of all step', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
                             'FontWeight', 'bold','Position', [.46 .1 .09 .03],'Foregroundcolor','c');  
%no arm movements check box
 checkBoxRightArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[0.47,0.15,0.12,0.03],'string','no Right arms movement',...
                 'callback', @checkBoxRightArms_call); 
checkBoxLeftArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[0.66,0.15,0.12,0.03],'string','no Left arms movement',...
                 'callback', @checkBoxLeftArms_call); 
%no bamper movement check box             
 checkBoxBamper = uicontrol('style','checkbox','units','normalized','enable', 'off','FontSize',11,...
                  'Position',[.170 .57 .11 .03],'string','no bamper movement',...
                 'callback', @checkBoxBamper_call); 
%hide bamper check box
 checkBoxHideBamper = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[.26 .1 .09 .03],'string','hide bamper', 'Foregroundcolor', 'k',...
                 'callback', @checkBoxHideBamper_call);                          
 %no CG checkbox            
 checkBoxCG = uicontrol('style','checkbox','units','normalized', 'enable', 'off','FontSize',11,...
                  'Position',[0.49,0.57,0.1,0.03],'string','no CG out of bound',...
                 'callback', @checkBoxCG_call); 
 %hide CG check box            
 checkBoxHideCG = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[0.26,0.06,0.09,0.03],'string','hide CG', 'Foregroundcolor', [0.8003 0.1524 0.8443],...
                 'callback', @checkBoxHideCG_call);              
% hide Right arm movement check box
 checkBoxHideRightArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[.36 .1 .09 .03],'string','hide Right arm', 'Foregroundcolor', 'r',...
                 'callback', @checkBoxHideRightArms_call); 
% hide Left arm movements check box
checkBoxHideLeftArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'Position',[.36 .06 .09 .03],'string','hide Left arm', 'Foregroundcolor', [0.3922 0.7782 0.5277],...
    'callback', @checkBoxHideLeftArms_call);
checkBoxFall = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[.56 .06 .05 .03],'string','Fall',...
                 'callback', @checkBoxFall_call);
checkBoxMS = uicontrol('style','checkbox','units','normalized','FontSize',11,...
                  'Position',[.56 .1 .05 .03],'string','MS',...
                 'callback', @checkBoxMS_call);
%slider
slider = uicontrol('Style','slider','units','normalized','Position',[.82 .1 .14 .03],'Callback',@slider_call);
typeOfArmMove=uicontrol('Style','edit','units','normalized','FontSize',11,'Position',[0.70 0.06 0.10 0.03],'string','','Callback',@typeArm_call);
typeOfLegMove=uicontrol('Style','edit','units','normalized','FontSize',11,'Position',[0.70 0.10 0.10 0.03],'string','','Callback',@typeLeg_call);
TypeLegs_Move = uicontrol('String', 'Type Of Legs Move:', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
                             'FontWeight', 'bold','Position', [0.60 0.10 0.10 0.03], 'BackgroundColor',  [.925 .914 .847]);
TypeArms_Move = uicontrol('String', 'Type Of Arms Move:', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
 'FontWeight', 'bold','Position', [0.60 0.06 0.10 0.03], 'BackgroundColor',  [.925 .914 .847]);
set(gcf,'WindowButtonUpFcn',@releaseCallback); %set release callback for SF line 
ispressed = 0; %flag for SF line being pressed
%CG haxes
haxesCG = axes('Units', 'normalized','Position', [.49 .635 .3 .300], 'Box', 'on');%, 'XTick', [], 'YTick', []);
xlabel('Time', 'fontname' , 'Cambria' , 'fontweight' , 'b')
ylabel('Position', 'fontname' , 'Cambria' , 'fontweight' , 'b')
title(haxesCG, 'CG and feet movement')
haxesCGLine1 = imline(haxesCG,[0 0], [0 0]); %bamper line 1
haxesCGLine1.setColor('k')
addNewPositionCallback(haxesCGLine1,@(pos)callback_line1(pos));
haxesCGLine2 = imline(haxesCG,[0 0], [0 0]); %bamper line 2
haxesCGLine2.setColor('k')
addNewPositionCallback(haxesCGLine2,@(pos)callback_line2(pos));
%SF line
haxesSFLine1 = line([0 0], [0 0],'Color', [0.6557 0.1067 0.3111],'LineWidth',1.5,'Parent', haxesCG, 'ButtonDownFcn',@SFLine1Callback);
haxesCGLine3 = imline(haxesCG,[0 0], [0 0]); %step line 1
haxesCGLine3.setColor('b');
addNewPositionCallback(haxesCGLine3,@(pos)callback_line3(pos));
haxesCGLine4 = imline(haxesCG,[0 0], [0 0]); %step line 2
haxesCGLine4.setColor('c');
addNewPositionCallback(haxesCGLine4,@(pos)callback_line4(pos));
haxesCGLine5 = imline(haxesCG,[0 0], [0 0]); %rightarms line 1
haxesCGLine5.setColor('r');
addNewPositionCallback(haxesCGLine5,@(pos)callback_line5(pos));
haxesCGLine6 = imline(haxesCG,[0 0], [0 0]); %rightarms line 2
haxesCGLine6.setColor('r');
addNewPositionCallback(haxesCGLine6,@(pos)callback_line6(pos));
haxesCGLine7 = imline(haxesCG,[0 0], [0 0]); %CG line 1
haxesCGLine7.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesCGLine7,@(pos)callback_line7(pos));
haxesCGLine8 = imline(haxesCG,[0 0], [0 0]); %CG line 2
haxesCGLine8.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesCGLine8,@(pos)callback_line8(pos));
haxesCGLine9 = imline(haxesCG,[0 0], [0 0]);%leftArms line1
haxesCGLine9.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesCGLine9,@(pos)callback_line9(pos));
haxesCGLine10 = imline(haxesCG,[0 0], [0 0]);%leftArmsline2
haxesCGLine10.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesCGLine10,@(pos)callback_line10(pos));
haxesCGLine11 = imline(haxesCG,[0 0], [0 0]);% end first step
haxesCGLine11.setColor('b');
addNewPositionCallback(haxesCGLine11,@(pos)callback_line11(pos));

%bamper haxes
haxesBamper = axes('Units', 'normalized','Position', [.15 .635 .3 .300], 'Box', 'on');%, 'XTick', [], 'YTick', []);, 'XTick', [], 'YTick', []);
xlabel('Time', 'fontname' , 'Cambria' , 'fontweight' , 'b')
ylabel('Position', 'fontname' , 'Cambria' , 'fontweight' , 'b')
title(haxesBamper, 'Bamper X movement')
haxesBamperLine1 = imline(haxesBamper,[0 0], [0 0]);
addNewPositionCallback(haxesBamperLine1,@(pos)callback_line1(pos));
haxesBamperLine1.setColor('k')
haxesBamperLine2 = imline(haxesBamper,[0 0], [0 0]);
addNewPositionCallback(haxesBamperLine2,@(pos)callback_line2(pos));
haxesBamperLine2.setColor('k')
haxesSFLine3 = line([0 0], [0 0],'Color', [0.6557 0.1067 0.3111],'LineWidth',1.5, 'ButtonDownFcn',@SFLine1Callback);
haxesBamperLine3 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine3.setColor('b');
addNewPositionCallback(haxesBamperLine3,@(pos)callback_line3(pos));
haxesBamperLine4 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine4.setColor('c');
addNewPositionCallback(haxesBamperLine4,@(pos)callback_line4(pos));
haxesBamperLine5 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine5.setColor('r');
addNewPositionCallback(haxesBamperLine5,@(pos)callback_line5(pos));
haxesBamperLine6 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine6.setColor('r');
addNewPositionCallback(haxesBamperLine6,@(pos)callback_line6(pos));
haxesBamperLine7 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine7.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesBamperLine7,@(pos)callback_line7(pos));
haxesBamperLine8 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine8.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesBamperLine8,@(pos)callback_line8(pos));
haxesBamperLine9 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine9.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesBamperLine9,@(pos)callback_line9(pos));
haxesBamperLine10 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine10.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesBamperLine10,@(pos)callback_line10(pos));

haxesBamperLine11 = imline(haxesBamper,[0 0], [0 0]);
haxesBamperLine11.setColor('b');
addNewPositionCallback(haxesBamperLine11,@(pos)callback_line11(pos));

%arms haxes
haxesArms = axes('Units', 'normalized','Position', [.49 .225 .3 .300], 'Box', 'on');%, 'XTick', [], 'YTick', []);, 'XTick', [], 'YTick', []);
xlabel('Time', 'fontname' , 'Cambria' , 'fontweight' , 'b')
ylabel('Position', 'fontname' , 'Cambria' , 'fontweight' , 'b')
title(haxesArms, 'Change in arms distance from CG')
haxesArmsLine1 = imline(haxesArms,[0 0], [0 0]);
addNewPositionCallback(haxesArmsLine1,@(pos)callback_line1(pos));
haxesArmsLine1.setColor('k')
haxesArmsLine2 = imline(haxesArms,[0 0], [0 0]);
addNewPositionCallback(haxesArmsLine2,@(pos)callback_line2(pos));
haxesArmsLine2.setColor('k')
haxesSFLine4 = line([0 0], [0 0],'Color', [0.6557 0.1067 0.3111],'LineWidth',1.5, 'ButtonDownFcn',@SFLine1Callback);
haxesArmsLine3 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine3.setColor('b');
addNewPositionCallback(haxesArmsLine3,@(pos)callback_line3(pos));
haxesArmsLine4 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine4.setColor('c');
addNewPositionCallback(haxesArmsLine4,@(pos)callback_line4(pos));
haxesArmsLine5 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine5.setColor('r');
addNewPositionCallback(haxesArmsLine5,@(pos)callback_line5(pos));
haxesArmsLine6 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine6.setColor('r');
addNewPositionCallback(haxesArmsLine6,@(pos)callback_line6(pos));
haxesArmsLine7 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine7.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesArmsLine7,@(pos)callback_line7(pos));
haxesArmsLine8 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine8.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesArmsLine8,@(pos)callback_line8(pos));
haxesArmsLine9 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine9.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesArmsLine9,@(pos)callback_line9(pos));
haxesArmsLine10 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine10.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesArmsLine10,@(pos)callback_line10(pos));
haxesArmsLine11 = imline(haxesArms,[0 0], [0 0]);
haxesArmsLine11.setColor('b');
addNewPositionCallback(haxesArmsLine11,@(pos)callback_line11(pos));
% step haxes
haxesStep = axes('Units', 'normalized','Position', [.15 .225 .3 .300], 'Box', 'on');%, 'XTick', [], 'YTick', []);, 'XTick', [], 'YTick', []);
xlabel('Time', 'fontname' , 'Cambria' , 'fontweight' , 'b')
ylabel('Position', 'fontname' , 'Cambria' , 'fontweight' , 'b')
title(haxesStep, 'Step')
haxesStepLine1 = imline(haxesStep,[0 0], [0 0]);
addNewPositionCallback(haxesStepLine1,@(pos)callback_line1(pos));
haxesStepLine1.setColor('k')
haxesStepLine2 = imline(haxesStep,[0 0], [0 0]);
addNewPositionCallback(haxesStepLine2,@(pos)callback_line2(pos));
haxesStepLine2.setColor('k')
haxesSFLine2 = line([0 0], [0 0],'Color', [0.6557 0.1067 0.3111],'LineWidth',1.5, 'ButtonDownFcn',@SFLine1Callback);
haxesStepLine3 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine3.setColor('b');
addNewPositionCallback(haxesStepLine3,@(pos)callback_line3(pos));
haxesStepLine4 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine4.setColor('c');
addNewPositionCallback(haxesStepLine4,@(pos)callback_line4(pos));
haxesStepLine5 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine5.setColor('r');
addNewPositionCallback(haxesStepLine5,@(pos)callback_line5(pos));
haxesStepLine6 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine6.setColor('r');
addNewPositionCallback(haxesStepLine6,@(pos)callback_line6(pos));
haxesStepLine7 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine7.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesStepLine7,@(pos)callback_line7(pos));
haxesStepLine8 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine8.setColor([0.8003 0.1524 0.8443]);
addNewPositionCallback(haxesStepLine8,@(pos)callback_line8(pos));
haxesStepLine9 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine9.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesStepLine9,@(pos)callback_line9(pos));
haxesStepLine10 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine10.setColor([0.3922 0.7782 0.5277]);
addNewPositionCallback(haxesStepLine10,@(pos)callback_line10(pos));
haxesStepLine11 = imline(haxesStep,[0 0], [0 0]);
haxesStepLine11.setColor('b');
addNewPositionCallback(haxesStepLine11,@(pos)callback_line11(pos));
% [.83 .270 .14 .650]
haxesSF = axes('Units', 'normalized','Position', [.83 .18 .14 .70], 'Box', 'on');

title(haxesSF, 'stick figure')   


%% functions of the GUI 
function chooseFolderButtonselected_cb(hObject, eventdata, handles)
flag=0;
[FileName,PathName,~]  = uigetfile({'*.csv'});
set(currentFile, 'string',{'corrent file:' FileName})
set(pathFolder,'string',{'corrent path:' PathName})
if ~isempty(strfind(FileName,'Walk')) || ~isempty(strfind(FileName,'walk'))
    set(currentFile,'value',12)
else
    set(currentFile,'value',24)
end
if  get(currentFile,'value')==12 % walking
    set(ListBoxPertubation,'string',{'1';'2';'3';'4';'5';'6';'7';'8';'9';'10';'11';'12'},'Position',[.01 .50 .05 .32])
else
    if get(currentFile,'value')==24% standing
        set(ListBoxPertubation,'string',{'1';'2';'3';'4';'5';'6';'7';'8';'9';'10';'11';'12';'13';'14';'15';'16';'17';'18';'19';'20';'21';'22';'23';'24'},'Position',[.01 .15 .05 .64])
    end
end
PatientName=FileName(1:end-4)
newPath=[PathName PatientName];
if ~isdir([PathName '\' PatientName])
    mkdir(newPath)
    flag=1;
else
    files=dir(newPath);
    for i=3:size(files,1)
        if ~isempty(strfind(files(i).name,'Vdata')) && isempty(strfind(files(i).name,'Vdata2'))
            Vdata=importdata([newPath '\' files(i).name]);
        end
        if ~isempty(strfind(files(i).name,'Vdata2')) && ~isempty(strfind(files(i).name,'Vdata'))
            Vdata2=importdata([newPath '\' files(i).name]);
        end
    end   
end
set(pathFolder,'string',{'corrent path:' newPath});
 fileName=[PathName FileName];
 stepName=PatientName;
 if ~isempty(strfind(PatientName,'Stand'))
     ST_DT=strfind(PatientName,'Stand')
 elseif ~isempty(strfind(PatientName,'stand'))
     ST_DT=strfind(PatientName,'stand')
 elseif ~isempty(strfind(PatientName,'Walk'))
     ST_DT=strfind(PatientName,'Walk')
 elseif  ~isempty(strfind(PatientName,'walk'))
     ST_DT=strfind(PatientName,'walk')
 end
name=PatientName(1:ST_DT-1);
% creating or updating the Vdata and Vdata2 (.MAT) files.
if flag % if this file doesn't have Vdata - Update the Vdata file
    UpdateMat(fileName, name, stepName)
end
uiresume(h)
end
function listBoxPertu_call(hObject, eventdata, handles)   
contents = cellstr(get(ListBoxPertubation,'String')); 
NewText = contents{get(ListBoxPertubation,'Value')}; 
NewColor = sprintf('<HTML><BODY bgcolor="%s">%s', 'green', NewText);
namestr = cellstr(get(ListBoxPertubation, 'String')); 
validx = get(ListBoxPertubation, 'Value'); 
newstr = regexprep(NewColor, '"red"','"blue"'); 
namestr{validx} = newstr; 
set(ListBoxPertubation, 'String', namestr)
end 
% update the Vdata.mat files
function UpdateMat(fileName, name, stepName) 
    try
    modelOutput =  importdata(fileName, ',', 5) %read CG
    tf = isfield(modelOutput, 'data')
    while tf==0
        tf = isfield(modelOutput, 'data')
    end
    % Angles of Elbow and Shoulder
    LElbowAng=modelOutput.data(:,42);
    LShoulderAng=modelOutput.data(:,144:146);
    RElbowAng=modelOutput.data(:,234);
    RShoulderAng=modelOutput.data(:,336:338);
            
    viconData =  importdata(fileName, ',', 11 + length(modelOutput.data)) %read marker positions

    bamperX = viconData.data(:,end-2); %get bamper data
    bamperMovement = bamperX - bamperX(1); %bamper movement
    leftAnkleX = viconData.data(:,93)  - bamperMovement;  %left ankle lateral position, substruct bamper movement
    rightAnkleX = viconData.data(:,111) - bamperMovement; %right ankle lateral position, substruct bamper movement
    leftAnkleY = viconData.data(:,94); %left ankle anterior
    rightAnkleY = viconData.data(:,112);%right ankle anterior
    %%%%
    leftAnkleZ = viconData.data(:,95);
    rightAnkleZ = viconData.data(:,113);
    %%%%
    leftHeelY=viconData.data(:,97);
    rightHeelY=viconData.data(:,115);
    leftToeY= viconData.data(:,100);
    rightToeY=viconData.data(:,118);
    rightArmX  = viconData.data(:,69) -  viconData.data(1,69) - bamperMovement; %right arm lateral position, substruct bamper movement
    rightArmY  = viconData.data(:,70) -  viconData.data(1,70); % right arm lateral movement
    rightArmZ  = viconData.data(:,71) -  viconData.data(1,71); %right arm aupward movement
    leftArmX  = viconData.data(:,48) -  viconData.data(1,48) - bamperMovement; %right arm lateral position, substruct bamper movement
    leftArmY  = viconData.data(:,49) -  viconData.data(1,49); % right arm lateral movement
    leftArmZ  = viconData.data(:,50) -  viconData.data(1,50);%right arm upward
    
    modelOutput.data(:,3)  = modelOutput.data(:,3) - bamperMovement; %cgx
    searchIndex = 0;
    if get(currentFile,'value')==24
    % standing files have 24 segments (perturbations)
        for ind  = 1:24
     %for lateral movements we get pertubations from bamper and for anterior movements get it from the ankle
            if mod(ind, 2) == 0 % left or right pertubation
                pertubationsTime= findPertubations(bamperX, searchIndex,2);   %lateral              
            else % front or back pertubation
                pertubationsTime= findPertubations(leftAnkleY, searchIndex,1);   %anterior     
            end   
            %each segment is from 2 seconds before perturbation start til 3 seconds
            %after perturbation end
                timeSlot = [pertubationsTime(1) - 240, pertubationsTime(2) + 360]; 
                lAnkleX = leftAnkleX(timeSlot(1):timeSlot(2));
                rAnkleX = rightAnkleX(timeSlot(1):timeSlot(2));
                
                lHeelY = leftHeelY(timeSlot(1):timeSlot(2));
                lToeY= leftToeY(timeSlot(1):timeSlot(2));
                rHeelY = rightHeelY(timeSlot(1):timeSlot(2));
                rToeY= rightToeY(timeSlot(1):timeSlot(2));
                CGX = modelOutput.data(timeSlot(1):timeSlot(2),3);
                CGX_plot=CGX;
                CGY = modelOutput.data(timeSlot(1):timeSlot(2),4); 
                CGY_plot=CGY;
                CGZ = modelOutput.data(timeSlot(1):timeSlot(2),5);
                CGZ_plot=CGZ;
                %stepping is in x and y plane
                %leftStepping = sqrt((lAnkleX - lAnkleX(1)).^2 + (leftAnkleY(timeSlot(1):timeSlot(2)) - leftAnkleY(timeSlot(1))).^2+(leftAnkleZ(timeSlot(1):timeSlot(2)) - leftAnkleZ(timeSlot(1))).^2);
                %rightStepping = sqrt((rAnkleX - rAnkleX(1)).^2 + (rightAnkleY(timeSlot(1):timeSlot(2)) - rightAnkleY(timeSlot(1))).^2+(rightAnkleZ(timeSlot(1):timeSlot(2)) - rightAnkleZ(timeSlot(1))).^2);              
                leftStepping = sqrt(lAnkleX.^2 + (leftAnkleY(timeSlot(1):timeSlot(2))).^2)%+(leftAnkleZ(timeSlot(1):timeSlot(2))).^2);
                rightStepping = sqrt(rAnkleX.^2 + (rightAnkleY(timeSlot(1):timeSlot(2))).^2)%+(rightAnkleZ(timeSlot(1):timeSlot(2))).^2);              

                %arms movement is in x y z plane and the cg is reduced
                leftArmTotal = sqrt((leftArmX(timeSlot(1):timeSlot(2)) - CGX).^2 + (leftArmY(timeSlot(1):timeSlot(2)) - CGY).^2 + (leftArmZ(timeSlot(1):timeSlot(2)) - CGZ).^2);
                rightArmTotal = sqrt((rightArmX(timeSlot(1):timeSlot(2)) - CGX).^2 + (rightArmY(timeSlot(1):timeSlot(2)) - CGY).^2 + (rightArmZ(timeSlot(1):timeSlot(2)) - CGZ).^2);                                    
                %bias to zero
                leftStepping = leftStepping - leftStepping(1);
                rightStepping = rightStepping - rightStepping(1);
                leftArmTotal = leftArmTotal - leftArmTotal(1);
                rightArmTotal = rightArmTotal - rightArmTotal(1);
                %find first step foot, last step foot, and the stepping time
                %from perturbations
                [steppingTime, firstStep,EndFirstStep, lastStep] = findStepping(leftStepping(241:end), rightStepping(241:end),'Standing');
                steppingTime = 240 + steppingTime; %add the 2 seconds beforre the perturbation
                %find arms movement from perturbation
                [RightarmsTime,LeftarmsTime] =findArms(leftArmTotal(241:end), rightArmTotal(241:end));
                RightarmsTime=RightarmsTime+240; LeftarmsTime=LeftarmsTime+240;
                lAnkleX = lAnkleX - CGX(1);
                rAnkleX = rAnkleX - CGX(1);
                lHeelY = lHeelY - CGY(1);
                rToeY= rToeY - CGY(1);
                rHeelY = rHeelY - CGY(1);
                lToeY= lToeY - CGY(1);
                CGX = CGX - CGX(1);
                CGY = CGY - CGY(1);
                CGZ = CGZ - CGZ(1);
                %find when CG is out of legs
                if mod(ind, 2) == 0 % left or right pertubation
                    pertubation_type=1;
                    cgOut = findCG(lAnkleX, rAnkleX,[],[], CGX,pertubation_type);
                else % front or back pertubation
                    pertubation_type=2,
                    cgOut = findCG(lHeelY, lToeY,rHeelY, rToeY, CGY,pertubation_type); 
                end
                searchIndex = pertubationsTime(2) + 700;
                %save all data to vdata and and data that can be changed to vdata2            
                Vdata(ind).bamper = bamperMovement(timeSlot(1):timeSlot(2));
                Vdata(ind).leftAnkleX = lAnkleX;
                Vdata(ind).rightAnkleX = rAnkleX;
                Vdata(ind).leftStepping = leftStepping;
                Vdata(ind).rightStepping = rightStepping;
                Vdata(ind).CGX = CGX;
                Vdata(ind).CGX_plot=CGX_plot; 
                Vdata(ind).CGY = CGY;
                Vdata(ind).CGY_plot=CGY_plot;
                Vdata(ind).CGZ = CGZ;
                Vdata(ind).CGZ_plot=CGZ_plot;
                Vdata(ind).leftToeY=lToeY;
                Vdata(ind).leftHeelY =lHeelY;
                Vdata(ind).rightToeY=rToeY;
                Vdata(ind).rightHeelY =rHeelY;
                Vdata(ind).leftArmTotal = leftArmTotal;
                Vdata(ind).rightArmTotal = rightArmTotal;
                Vdata(ind).name = name;
                Vdata(ind).step = stepName;
                Vdata(ind).pertubationsTime = pertubationsTime;
                Vdata(ind).steppingTime = steppingTime;
                Vdata(ind).firstStep = firstStep;
                Vdata(ind).EndFirstStep = EndFirstStep+240;         
                Vdata(ind).lastStep = lastStep;
                Vdata(ind).RightarmsTime = RightarmsTime;
                Vdata(ind).LeftarmsTime = LeftarmsTime;
                Vdata(ind).edited = false;
                Vdata(ind).cgOut = cgOut;
                Vdata(ind).TypeArmMove=[];
                Vdata(ind).TypeLegMove=[];
                Vdata(ind).Fall=0;
                Vdata(ind).MS=0;%multiple steps
                Vdata(ind).SFdATA = viconData.data((timeSlot(1):timeSlot(2)),3:end);
                namestr = cellstr(get(ListBoxPertubation, 'String')); 
                Vdata(ind).StringPer=namestr{ind};
                Vdata(ind).LElbowAng=LElbowAng(timeSlot(1):timeSlot(2));
                Vdata(ind).LShoulderAng=LShoulderAng((timeSlot(1):timeSlot(2)),1:3);       
                Vdata(ind).RElbowAng=RElbowAng(timeSlot(1):timeSlot(2));
                Vdata(ind).RShoulderAng=RShoulderAng((timeSlot(1):timeSlot(2)),1:3); 

                Vdata2(ind).pertubationsTime = pertubationsTime;
                Vdata2(ind).steppingTime = steppingTime;
                Vdata2(ind).firstStep = firstStep;
                Vdata2(ind).EndFirstStep = EndFirstStep+240;         
                Vdata2(ind).lastStep = lastStep;
                Vdata2(ind).RightarmsTime = RightarmsTime;
                Vdata2(ind).LeftarmsTime = LeftarmsTime;
                Vdata2(ind).cgOut = cgOut;  
                Vdata2(ind).TypeArmMove=[];
                Vdata2(ind).TypeLegMove=[];
                Vdata2(ind).Fall=0;
                Vdata2(ind).MS=0;%multiple steps 
                
        end
        a=get(pathFolder,'string')
        save([a{2,1} '\Vdata_' stepName], 'Vdata');
        save([a{2,1} '\Vdata2_' stepName], 'Vdata2');
    else 
            % walking
            for ind  = 1:12
                pertubationsTime= findPertubations(bamperX, searchIndex,2);                 

                timeSlot = [pertubationsTime(1) - 240, pertubationsTime(2) + 360];
                lAnkleX = leftAnkleX(timeSlot(1):timeSlot(2));
                rAnkleX = rightAnkleX(timeSlot(1):timeSlot(2));

                leftStepping = lAnkleX - lAnkleX(1);
                rightStepping = rAnkleX - rAnkleX(1);
                %%%%%
                %leftStepping = sqrt(lAnkleX.^2 + (leftAnkleY(timeSlot(1):timeSlot(2))).^2)%+(leftAnkleZ(timeSlot(1):timeSlot(2))).^2);
                %rightStepping = sqrt(rAnkleX.^2 + (rightAnkleY(timeSlot(1):timeSlot(2))).^2)%+(rightAnkleZ(timeSlot(1):timeSlot(2))).^2);              
                %%%%%%
                %leftStepping = leftStepping - leftStepping(1);
                %rightStepping = rightStepping - rightStepping(1);
                CGX = modelOutput.data(timeSlot(1):timeSlot(2),3);
                CGX_plot=CGX; 
                CGY = modelOutput.data(timeSlot(1):timeSlot(2),4); 
                CGZ = modelOutput.data(timeSlot(1):timeSlot(2),5); 
                leftArmTotal = leftArmX(timeSlot(1):timeSlot(2)) - CGX;
                rightArmTotal = rightArmX(timeSlot(1):timeSlot(2)) - CGX; 
                leftArmTotal = leftArmTotal - leftArmTotal(1);
                rightArmTotal = rightArmTotal - rightArmTotal(1);
                [steppingTime, firstStep,EndFirstStep, lastStep] = findStepping(leftStepping(241:end), rightStepping(241:end),'Walking');%check only in x direction
                steppingTime = 240 + steppingTime;
                [RightarmsTime,LeftarmsTime] =findArms(leftArmX(240 + timeSlot(1):timeSlot(2)), rightArmX(240 + timeSlot(1):timeSlot(2)));%check only movement in x direction
                RightarmsTime=RightarmsTime+240; LeftarmsTime=LeftarmsTime+240;
                lAnkleX = lAnkleX - CGX(1);
                rAnkleX = rAnkleX - CGX(1);
                CGX = CGX - CGX(1);
                pertubation_type=1 % left right pertubation
                cgOut = findCG(lAnkleX, rAnkleX,[],[], CGX,pertubation_type);
                searchIndex = pertubationsTime(2) + 700;

                Vdata(ind).bamper = bamperMovement(timeSlot(1):timeSlot(2));
                Vdata(ind).leftAnkleX = lAnkleX;
                Vdata(ind).rightAnkleX = rAnkleX;
                Vdata(ind).leftStepping = leftStepping;
                Vdata(ind).rightStepping = rightStepping;
                Vdata(ind).CGX = CGX;  
                Vdata(ind).CGX_plot=CGX_plot; 
                Vdata(ind).CGY = CGY;
                Vdata(ind).CGZ = CGZ;
                Vdata(ind).leftArmTotal = leftArmTotal;
                Vdata(ind).rightArmTotal = rightArmTotal;
                Vdata(ind).name = name;
                Vdata(ind).step = stepName;
                Vdata(ind).pertubationsTime = pertubationsTime;
                Vdata(ind).steppingTime = steppingTime;
                Vdata(ind).firstStep = firstStep;
                Vdata(ind).EndFirstStep = EndFirstStep +240;
                Vdata(ind).lastStep = lastStep;              
                Vdata(ind).RightarmsTime = RightarmsTime;
                Vdata(ind).LeftarmsTime = LeftarmsTime;
                Vdata(ind).edited = false;
                Vdata(ind).cgOut = cgOut;
                Vdata(ind).SFdATA = viconData.data((timeSlot(1):timeSlot(2)),3:end);
                Vdata(ind).TypeArmMove=[];
                Vdata(ind).TypeLegMove=[];
                Vdata(ind).Fall=0;
                Vdata(ind).MS=0;%multiple steps
                namestr = cellstr(get(ListBoxPertubation, 'String')); 
                Vdata(ind).StringPer=namestr{ind};
                Vdata(ind).LElbowAng=LElbowAng(timeSlot(1):timeSlot(2));
                Vdata(ind).LShoulderAng=LShoulderAng((timeSlot(1):timeSlot(2)),1:3);       
                Vdata(ind).RElbowAng=RElbowAng(timeSlot(1):timeSlot(2));
                Vdata(ind).RShoulderAng=RShoulderAng((timeSlot(1):timeSlot(2)),1:3); 

                Vdata2(ind).pertubationsTime = pertubationsTime;
                Vdata2(ind).steppingTime = steppingTime;
                Vdata2(ind).firstStep = firstStep;
                Vdata2(ind).EndFirstStep = EndFirstStep +240;
                Vdata2(ind).lastStep = lastStep;            
                Vdata2(ind).RightarmsTime = RightarmsTime;
                Vdata2(ind).LeftarmsTime = LeftarmsTime;
                Vdata2(ind).cgOut = cgOut;
                Vdata2(ind).TypeArmMove=[];
                Vdata2(ind).TypeLegMove=[];
                Vdata2(ind).Fall=0;
                Vdata2(ind).MS=0;%multiple steps
           end
            a=get(pathFolder,'string')
            save([a{2,1} '\Vdata_' stepName], 'Vdata');
            save([a{2,1} '\Vdata2_' stepName], 'Vdata2');
        end
    clear bamperX leftAnkleX rightAnkleX leftAnkleY rightAnkleY leftArmX leftArmY leftArmZ rightArmX rightArmY rightArmZ name stepName rawData viconData
    catch me
        h = errordlg(me.getReport)
    end
end
function drawButtonselected_cb(h,ev)
    try 
     pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
     listbox=get(ListBoxPertubation, 'String');
     currentbox=listbox{get(ListBoxPertubation,'value'),1};
     
      if Vdata(pertNumber).edited==1 % edited-0 (not analyzed) edited -1 (analyzed)   
          israw = 2;
          set(typeOfLegMove,'string',Vdata2(pertNumber).TypeLegMove);
          set(typeOfArmMove,'string',Vdata2(pertNumber).TypeArmMove);
         set(checkBoxFall,'Value',Vdata2(pertNumber).Fall);
         set(checkBoxMS,'Value',Vdata2(pertNumber).MS);
      else         
         israw = 1;
         set(typeOfLegMove,'string','');
         set(typeOfArmMove,'string','');
         set(checkBoxFall,'Value',0);
         set(checkBoxMS,'Value',0);
     end
    clearButtonselected_cb([],[]);
    DrawCOP(patientName, step, pertNumber, israw)
    %set(displayInfoButton, 'visible', 'on')
    set(patientNameLabel,'string', patientName)
        
    catch me
        h = errordlg(me.getReport)
     end
end
function clearButtonselected_cb(h,ev)
    try
    %Clear graphs
    %cla(haxesCG)       
    %cla(haxesStep)
    %cla(haxesBamper)
    %cla(haxesArms)
    set(plotHandleBamper(isPlotted == 1),'Visible','off')
    set(plotHandleCG(isPlotted == 1),'Visible','off')
    set(plotHandleRightStep(isPlotted == 1),'Visible','off')
    set(plotHandleLeftStep(isPlotted == 1),'Visible','off')
    set(plotHandleRightStepA(isPlotted == 1),'Visible','off')
    set(plotHandleLeftStepA(isPlotted == 1),'Visible','off')
    set(plotHandleLeftArm(isPlotted == 1),'Visible','off')
    set(plotHandleRightArm(isPlotted == 1),'Visible','off')
    set(plotHandleLeftCG(isPlotted == 1),'Visible','off')
    set(plotHandleRightCG(isPlotted == 1),'Visible','off')
    set(plotHandleLeftHCG(isPlotted == 1),'Visible','off')
    set(plotHandleRightHCG(isPlotted == 1),'Visible','off')
    set(plotHandleLeftTCG(isPlotted == 1),'Visible','off')
    set(plotHandleRightTCG(isPlotted == 1),'Visible','off')
    set(plotHandleBamper(isPlotted2 == 1),'Visible','off')
    set(plotHandleCG(isPlotted2 == 1),'Visible','off')
    set(plotHandleRightStep(isPlotted2 == 1),'Visible','off')
    set(plotHandleLeftStep(isPlotted2 == 1),'Visible','off')
    set(plotHandleLeftArm(isPlotted2 == 1),'Visible','off')
    set(plotHandleRightArm(isPlotted2 == 1),'Visible','off')
    set(plotHandleLeftCG(isPlotted2 == 1),'Visible','off')
    set(plotHandleRightCG(isPlotted2 == 1),'Visible','off')
    %empty matrixes of the plot
    isPlotted = zeros(size(Vdata));
    plotHandleBamper = zeros(size(Vdata));
    plotHandleCG = zeros(size(Vdata));
    plotHandleLeftCG = zeros(size(Vdata))   
    plotHandleRightCG = zeros(size(Vdata))
    plotHandleLeftHCG = zeros(size(Vdata))   
    plotHandleRightHCG = zeros(size(Vdata))
    plotHandleLeftTCG = zeros(size(Vdata))   
    plotHandleRightTCG = zeros(size(Vdata))
    plotHandleRightStep = zeros(size(Vdata))
    plotHandleLeftStep = zeros(size(Vdata))
    plotHandleRightStepA = zeros(size(Vdata))
    plotHandleLeftStepA = zeros(size(Vdata))
    plotHandleLeftArm = zeros(size(Vdata))
    plotHandleRightArm = zeros(size(Vdata))
    isPlotted2 = zeros(size(Vdata));
    plotHandleBamper2 = zeros(size(Vdata));
    plotHandleCG2 = zeros(size(Vdata));
    plotHandleRightStep2 = zeros(size(Vdata));
    plotHandleLeftStep2 = zeros(size(Vdata));
    plotHandleLeftArm2 = zeros(size(Vdata));
    plotHandleRightArm2 = zeros(size(Vdata));
    set(patientNameLabel,'string', '')
    catch me
        h = errordlg(me.getReport)
    end
end
function DrawCOP(patientName, step, pertNumber, israw)
    try
    if israw == 1
    isPlotted(pertNumber) = 1;
    
    set(checkBoxHideRightArms,'value', 0);
    set(checkBoxHideLeftArms,'value', 0);
    set(checkBoxHideSteps,'value', 0);
    set(checkBoxHideCG,'value', 0);
    set(checkBoxHideBamper,'value', 0);
    
    axes(haxesBamper); 
    set(haxesSFLine3, 'YData', [-5000 5000])
    set(haxesSFLine3, 'XData', [1 1])
     hold on
    plotHandleBamper(pertNumber) = plot(haxesBamper, Vdata(pertNumber).bamper,'color', 'k' ,'LineWidth',1.5); hold on
        
    ylim(haxesBamper,[min(Vdata(pertNumber).bamper)-100, max(Vdata(pertNumber).bamper)+ 100])
    xlim(haxesBamper,[1 length(Vdata(pertNumber).bamper)])
    title(haxesBamper, 'Bamper X movement');  
    haxesBamperLine1.setPosition([240 240], [-50000 50000]);
    haxesBamperLine2.setPosition([length(Vdata(pertNumber).bamper)-360 length(Vdata(pertNumber).bamper)-360], [-50000 50000]);
    haxesBamperLine3.setPosition([Vdata(pertNumber).steppingTime(1) Vdata(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesBamperLine4.setPosition([Vdata(pertNumber).steppingTime(2) Vdata(pertNumber).steppingTime(2)], [-50000 50000]);
    haxesBamperLine5.setPosition([Vdata(pertNumber).RightarmsTime(1) Vdata(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesBamperLine6.setPosition([Vdata(pertNumber).RightarmsTime(2) Vdata(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesBamperLine7.setPosition([Vdata(pertNumber).cgOut(1) Vdata(pertNumber).cgOut(1)], [-50000 50000]);
    haxesBamperLine8.setPosition([Vdata(pertNumber).cgOut(2) Vdata(pertNumber).cgOut(2)], [-50000 50000]);
    haxesBamperLine9.setPosition([Vdata(pertNumber).LeftarmsTime(1) Vdata(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesBamperLine10.setPosition([Vdata(pertNumber).LeftarmsTime(2) Vdata(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesBamperLine11.setPosition([Vdata(pertNumber).EndFirstStep Vdata(pertNumber).EndFirstStep], [-50000 50000]);

    xlabel(haxesBamper,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    ylabel(haxesBamper,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    if Vdata(pertNumber).pertubationsTime(1)< 0
        set(checkBoxBamper, 'value', 1);
    else
        set(checkBoxBamper, 'value', 0);
    end
    set(slider,'min',1);
    set(slider,'max', length(Vdata(pertNumber).bamper));
    set(slider,'value',1);
    
    axes(haxesCG);
    set(haxesSFLine1, 'YData', [-5000 5000])
    set(haxesSFLine1, 'XData', [1 1])
    hold on
    if mod(pertNumber, 2) == 0 || length(Vdata)==12 % left or right pertubation or walking protocol
        plotHandleLeftCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).leftAnkleX,'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleRightCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).rightAnkleX,'color', 'r' ,'LineWidth',1.5); hold on
        
        plotHandleLeftHCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleLeftTCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', 'r' ,'LineWidth',1.5); hold on
        plotHandleRightHCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', [0.5 0.2 0.7] ,'LineWidth',1.5); hold on
        plotHandleRightTCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', [0.4 0.3 0.6] ,'LineWidth',1.5); hold on
        
        plotHandleCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).CGX,'color', 'b' ,'LineWidth',1.5); hold on
        legend([plotHandleLeftCG(pertNumber), plotHandleRightCG(pertNumber),...
        plotHandleCG(pertNumber)], 'left', 'right', 'CG')
        ylim(haxesCG,[min(min(Vdata(pertNumber).rightAnkleX,Vdata(pertNumber).leftAnkleX))-100 max(max(Vdata(pertNumber).leftAnkleX,Vdata(pertNumber).rightAnkleX))+ 100])
        xlim(haxesCG,[1, length(Vdata(pertNumber).bamper)])
    else% front back pertubation\
        plotHandleLeftCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleRightCG(pertNumber) = plot(haxesCG,[-50000 -50000],'color', 'r' ,'LineWidth',1.5); hold on
        plotHandleLeftHCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).leftHeelY,'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleLeftTCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).leftToeY,'color',[ 0.1 0.6 0.4] ,'LineWidth',1.5); hold on
        plotHandleRightHCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).rightHeelY,'color', 'r' ,'LineWidth',1.5); hold on
        plotHandleRightTCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).rightToeY,'color', [0.9 0.3 0.1] ,'LineWidth',1.5); hold on
        plotHandleCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).CGY,'color', 'b' ,'LineWidth',1.5); hold on
        legend([plotHandleLeftHCG(pertNumber), plotHandleLeftTCG(pertNumber),...
        plotHandleRightHCG(pertNumber), plotHandleRightTCG(pertNumber),plotHandleCG(pertNumber)], 'leftHeelY', 'leftToeY','rightHeelY', 'rightToeY', 'CGY')
        ylim(haxesCG,[min(min(Vdata(pertNumber).leftToeY),min(Vdata(pertNumber).rightToeY))-100 max(max(Vdata(pertNumber).leftHeelY),max(Vdata(pertNumber).rightHeelY))+ 100])
        xlim(haxesCG,[1, length(Vdata(pertNumber).bamper)])
    end
    xlabel(haxesCG,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    ylabel(haxesCG,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    title(haxesCG, 'CG and feet movement');
   haxesBamperLine1.setPosition([240 240], [-50000 50000]);
    haxesBamperLine2.setPosition([length(Vdata(pertNumber).bamper)-360 length(Vdata(pertNumber).bamper)-360], [-50000 50000]);
   haxesCGLine3.setPosition([Vdata(pertNumber).steppingTime(1) Vdata(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesCGLine4.setPosition([Vdata(pertNumber).steppingTime(2) Vdata(pertNumber).steppingTime(2)], [-50000 50000]);
    haxesCGLine5.setPosition([Vdata(pertNumber).RightarmsTime(1) Vdata(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesCGLine6.setPosition([Vdata(pertNumber).RightarmsTime(2) Vdata(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesCGLine7.setPosition([Vdata(pertNumber).cgOut(1) Vdata(pertNumber).cgOut(1)], [-50000 50000]);
    haxesCGLine8.setPosition([Vdata(pertNumber).cgOut(2) Vdata(pertNumber).cgOut(2)], [-50000 50000]);
    haxesCGLine9.setPosition([Vdata(pertNumber).LeftarmsTime(1) Vdata(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesCGLine10.setPosition([Vdata(pertNumber).LeftarmsTime(2) Vdata(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesCGLine11.setPosition([Vdata(pertNumber).EndFirstStep Vdata(pertNumber).EndFirstStep], [-50000 50000]);
    if Vdata(pertNumber).cgOut(1)< 0
        set(checkBoxCG, 'value', 1);
    else
        set(checkBoxCG, 'value', 0);
    end
    
    axes(haxesStep);
    hold on
    set(haxesSFLine2, 'YData', [-50000 50000])
    set(haxesSFLine2, 'XData', [1 1])
    if length(Vdata)==24
     plotHandleLeftStep(pertNumber) = plot(haxesStep, Vdata(pertNumber).leftStepping,'color', 'g' ,'LineWidth',1.5); hold on
     plotHandleRightStep(pertNumber) = plot(haxesStep, Vdata(pertNumber).rightStepping,'color', 'r' ,'LineWidth',1.5); hold on
%         VelocityL=(Vdata(pertNumber).leftStepping(2:end)-Vdata(pertNumber).leftStepping(1:end-1))*120;
%        VelocityR=(Vdata(pertNumber).rightStepping(2:end)-Vdata(pertNumber).rightStepping(1:end-1))*120;
%         AccL=(VelocityL(2:end)-VelocityL(1:end-1))*120;
%        AccR=(VelocityR(2:end)-VelocityR(1:end-1))*120;
%    
%         plotHandleLeftStepA(pertNumber) = plot(haxesStep,AccL ,'color', 'c' ,'LineWidth',1.5); hold on
%         plotHandleRightStepA(pertNumber) = plot(haxesStep, AccR ,'color', 'm' ,'LineWidth',1.5); hold on
%         ylabel(haxesStep,'Acceleration', 'fontname' , 'Cambria' , 'fontweight' , 'b');
%         title(haxesStep, 'Step Acceleration');
%          legend([plotHandleLeftStepA(pertNumber), plotHandleRightStepA(pertNumber)...
%        ], 'left', 'right')
     
     %plotHandleLeftStep(pertNumber) = plot(haxesStep, Vdata(pertNumber).leftAnkleX,'color', 'g' ,'LineWidth',1.5); hold on
    %plotHandleRightStep(pertNumber) = plot(haxesStep, Vdata(pertNumber).rightAnkleX,'color', 'r' ,'LineWidth',1.5); hold on
    else % walking 
        plotHandleLeftStep(pertNumber) =plot(haxesStep,0,0,'b'); hold on
       plotHandleRightStep(pertNumber)= plot(haxesStep,0,0); hold on
    end
    if length(Vdata)==12%mod(pertNumber, 2) == 0 || length(Vdata)==12 % left or right pertubation or walking protocol
       
        VelocityL=(Vdata(pertNumber).leftStepping(2:end)-Vdata(pertNumber).leftStepping(1:end-1))*120;
       VelocityR=(Vdata(pertNumber).rightStepping(2:end)-Vdata(pertNumber).rightStepping(1:end-1))*120;
        AccL=(VelocityL(2:end)-VelocityL(1:end-1))*120;
       AccR=(VelocityR(2:end)-VelocityR(1:end-1))*120;
   
        plotHandleLeftStepA(pertNumber) = plot(haxesStep,AccL ,'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleRightStepA(pertNumber) = plot(haxesStep, AccR ,'color', 'r' ,'LineWidth',1.5); hold on
        ylabel(haxesStep,'Acceleration', 'fontname' , 'Cambria' , 'fontweight' , 'b');
        title(haxesStep, 'Step Acceleration');
         legend([plotHandleLeftStepA(pertNumber), plotHandleRightStepA(pertNumber)...
       ], 'left', 'right')
    else
       plotHandleLeftStepA(pertNumber) =plot(haxesStep,0,0,'b'); hold on
       plotHandleRightStepA(pertNumber)= plot(haxesStep,0,0); hold on
       ylabel(haxesStep,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    title(haxesStep, 'Step');
     legend([plotHandleLeftStep(pertNumber), plotHandleRightStep(pertNumber)...
       ], 'left', 'right')
   end % if walking
    xlabel(haxesStep,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    
    haxesBamperLine1.setPosition([240 240], [-50000 50000]);
    haxesBamperLine2.setPosition([length(Vdata(pertNumber).bamper)-360 length(Vdata(pertNumber).bamper)-360], [-50000 50000]);
    haxesStepLine3.setPosition([Vdata(pertNumber).steppingTime(1) Vdata(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesStepLine4.setPosition([Vdata(pertNumber).steppingTime(2) Vdata(pertNumber).steppingTime(2)], [-50000 50000]);
    haxesStepLine5.setPosition([Vdata(pertNumber).RightarmsTime(1) Vdata(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesStepLine6.setPosition([Vdata(pertNumber).RightarmsTime(2) Vdata(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesStepLine7.setPosition([Vdata(pertNumber).cgOut(1) Vdata(pertNumber).cgOut(1)], [-50000 50000]);
    haxesStepLine8.setPosition([Vdata(pertNumber).cgOut(2) Vdata(pertNumber).cgOut(2)], [-50000 50000]);
    haxesStepLine9.setPosition([Vdata(pertNumber).LeftarmsTime(1) Vdata(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesStepLine10.setPosition([Vdata(pertNumber).LeftarmsTime(2) Vdata(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesStepLine11.setPosition([Vdata(pertNumber).EndFirstStep Vdata(pertNumber).EndFirstStep], [-50000 50000]);

    xlim(haxesStep,[1, length(Vdata(pertNumber).bamper)])
    %ylim(haxesStep,[min(min(Vdata(pertNumber).leftStepping),min(Vdata(pertNumber).rightStepping))-100 max(max(Vdata(pertNumber).leftStepping),max(Vdata(pertNumber).rightStepping))+ 100])
    if length(Vdata)==12%mod(pertNumber, 2) == 0 || length(Vdata)==12 % left or right pertubation or walking protocol
        ylim(haxesStep,[min(min(AccL),min(AccR))-20 max(max(AccL),max(AccR))+20])
    else
        ylim(haxesStep,[min(min(Vdata(pertNumber).leftStepping),min(Vdata(pertNumber).rightStepping))-100 max(max(Vdata(pertNumber).leftStepping),max(Vdata(pertNumber).rightStepping))+ 100])

    end
    %legend('slider','left', 'right')
   
    if Vdata(pertNumber).steppingTime(1)< 0
        set(checkBoxStep, 'value', 1);
        set(listBoxStep,'value', 3);

    else
        set(checkBoxStep, 'value', 0);
        if Vdata(pertNumber).firstStep==1
            set(listBoxStep,'value', 1);
        else
            set(listBoxStep,'value', 2);
        end
    end
    
    axes(haxesArms);
    hold on
    set(haxesSFLine4, 'YData', [-50000 50000])
    set(haxesSFLine4, 'XData', [1 1])
    plotHandleLeftArm(pertNumber) = plot(haxesArms, Vdata(pertNumber).leftArmTotal,'color', 'g' ,'LineWidth',1.5); hold on
    plotHandleRightArm(pertNumber) = plot(haxesArms, Vdata(pertNumber).rightArmTotal,'color', 'r' ,'LineWidth',1.5); hold on
    xlabel(haxesArms,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    ylabel(haxesArms,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    title(haxesArms, 'Change in arms distance from CG');
    haxesBamperLine1.setPosition([240 240], [-50000 50000]);
    haxesBamperLine2.setPosition([length(Vdata(pertNumber).bamper)-360 length(Vdata(pertNumber).bamper)-360], [-50000 50000]);
   haxesStepLine3.setPosition([Vdata(pertNumber).steppingTime(1) Vdata(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesStepLine4.setPosition([Vdata(pertNumber).steppingTime(2) Vdata(pertNumber).steppingTime(2)], [-50000 50000]); 
    haxesStepLine5.setPosition([Vdata(pertNumber).RightarmsTime(1) Vdata(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesStepLine6.setPosition([Vdata(pertNumber).RightarmsTime(2) Vdata(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesStepLine7.setPosition([Vdata(pertNumber).cgOut(1) Vdata(pertNumber).cgOut(1)], [-50000 50000]);
    haxesStepLine8.setPosition([Vdata(pertNumber).cgOut(2) Vdata(pertNumber).cgOut(2)], [-50000 50000]);    
    haxesStepLine9.setPosition([Vdata(pertNumber).LeftarmsTime(1) Vdata(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesStepLine10.setPosition([Vdata(pertNumber).LeftarmsTime(2) Vdata(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesStepLine11.setPosition([Vdata(pertNumber).EndFirstStep Vdata(pertNumber).EndFirstStep], [-50000 50000]);
    
    ylim(haxesArms,[min(min(Vdata(pertNumber).leftArmTotal),min(Vdata(pertNumber).rightArmTotal))-100 max(max(Vdata(pertNumber).leftArmTotal),max(Vdata(pertNumber).rightArmTotal))+ 100])
    xlim(haxesArms,[1, length(Vdata(pertNumber).bamper)])
    %legend('slider', 'left', 'right')
    legend([plotHandleLeftArm(pertNumber), plotHandleRightArm(pertNumber)...
       ], 'left', 'right')
    if Vdata(pertNumber).RightarmsTime(1)< 0
        set(checkBoxRightArms, 'value', 1);
    else
        set(checkBoxRightArms, 'value', 0);
    end
     if Vdata(pertNumber).LeftarmsTime(1)< 0
        set(checkBoxLeftArms, 'value', 1);
    else
        set(checkBoxLeftArms, 'value', 0);
    end
    
    set(slider,'min',1);
    set(slider,'max', length(Vdata(pertNumber).bamper));
    set(slider,'value',1);
    
    %ColorLines();  
   
    else % isdraw==2;
   
    isPlotted(pertNumber) = 1;
    axes(haxesBamper);
    set(haxesSFLine3, 'YData', [-50000 50000])
    set(haxesSFLine3, 'XData', [1 1])
    hold on
    plotHandleBamper(pertNumber) = plot(haxesBamper, Vdata(pertNumber).bamper,'color', 'k' ,'LineWidth',1.5); hold on     
    xlabel(haxesBamper,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    ylabel(haxesBamper,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    title(haxesBamper, 'Bamper X movement');
   haxesBamperLine1.setPosition([Vdata2(pertNumber).pertubationsTime(1) Vdata2(pertNumber).pertubationsTime(1)], [-50000 50000]);
    haxesBamperLine2.setPosition([Vdata2(pertNumber).pertubationsTime(2) Vdata2(pertNumber).pertubationsTime(2)], [-50000 50000]);
     haxesBamperLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesBamperLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-50000 50000]);
    haxesBamperLine5.setPosition([Vdata2(pertNumber).RightarmsTime(1) Vdata2(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesBamperLine6.setPosition([Vdata2(pertNumber).RightarmsTime(2) Vdata2(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesBamperLine7.setPosition([Vdata2(pertNumber).cgOut(1) Vdata2(pertNumber).cgOut(1)], [-50000 50000]);
    haxesBamperLine8.setPosition([Vdata2(pertNumber).cgOut(2) Vdata2(pertNumber).cgOut(2)], [-50000 50000]);
    haxesBamperLine9.setPosition([Vdata2(pertNumber).LeftarmsTime(1) Vdata2(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesBamperLine10.setPosition([Vdata2(pertNumber).LeftarmsTime(2) Vdata2(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesBamperLine11.setPosition([Vdata2(pertNumber).EndFirstStep Vdata2(pertNumber).EndFirstStep], [-50000 50000]);  
    ylim(haxesBamper,[min(Vdata( pertNumber).bamper)-100 max(Vdata(pertNumber).bamper)+ 100])
    xlim(haxesBamper,[1, length(Vdata(pertNumber).bamper)])
    if Vdata2(pertNumber).pertubationsTime(1)< 0
        set(checkBoxBamper, 'value', 1);
    else
        set(checkBoxBamper, 'value', 0);
    end
     set(slider,'min',1);
    set(slider,'max', length(Vdata(pertNumber).bamper));
    set(slider,'value',1);
    axes(haxesCG);
    hold on
    set(haxesSFLine1, 'YData', [-50000 50000])
    set(haxesSFLine1, 'XData', [1 1])
    if mod(pertNumber, 2) == 0 || length(Vdata)==12 % left or right pertubation or walking protocol
        plotHandleLeftCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).leftAnkleX,'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleRightCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).rightAnkleX,'color', 'r' ,'LineWidth',1.5); hold on
        
        plotHandleLeftHCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleLeftTCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', 'r' ,'LineWidth',1.5); hold on
        plotHandleRightHCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', [0.5 0.2 0.7] ,'LineWidth',1.5); hold on
        plotHandleRightTCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', [0.4 0.3 0.6] ,'LineWidth',1.5); hold on
                
        plotHandleCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).CGX,'color', 'b' ,'LineWidth',1.5); hold on
        legend([plotHandleLeftCG(pertNumber), plotHandleRightCG(pertNumber),...
        plotHandleCG(pertNumber)], 'left', 'right', 'CG')
        ylim(haxesCG,[min(min(Vdata(pertNumber).rightAnkleX,Vdata(pertNumber).leftAnkleX))-100 max(max(Vdata(pertNumber).leftAnkleX,Vdata(pertNumber).rightAnkleX))+ 100])
        xlim(haxesCG,[1, length(Vdata(pertNumber).bamper)])
    else% front back pertubation
        plotHandleLeftCG(pertNumber) = plot(haxesCG, [-50000 -50000],'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleRightCG(pertNumber) = plot(haxesCG,[-50000 -50000],'color', 'r' ,'LineWidth',1.5); hold on
        
       plotHandleLeftHCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).leftHeelY,'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleLeftTCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).leftToeY,'color', [ 0.1 0.6 0.4] ,'LineWidth',1.5); hold on
        plotHandleRightHCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).rightHeelY,'color',  'r' ,'LineWidth',1.5); hold on
        plotHandleRightTCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).rightToeY,'color',[0.9 0.3 0.1] ,'LineWidth',1.5); hold on
        plotHandleCG(pertNumber) = plot(haxesCG, Vdata(pertNumber).CGY,'color', 'b' ,'LineWidth',1.5); hold on
        legend([plotHandleLeftHCG(pertNumber), plotHandleLeftTCG(pertNumber),...
        plotHandleRightHCG(pertNumber), plotHandleRightTCG(pertNumber),plotHandleCG(pertNumber)], 'leftHeelY', 'leftToeY','rightHeelY', 'rightToeY', 'CGY')
        ylim(haxesCG,[min(min(Vdata(pertNumber).leftToeY),min(Vdata(pertNumber).rightToeY))-100 max(max(Vdata(pertNumber).leftHeelY),max(Vdata(pertNumber).rightHeelY))+ 100])
        xlim(haxesCG,[1, length(Vdata(pertNumber).bamper)])
    end
    xlabel(haxesCG,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    ylabel(haxesCG,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    title(haxesCG, 'CG and feet movement')
   haxesBamperLine1.setPosition([Vdata2(pertNumber).pertubationsTime(1) Vdata2(pertNumber).pertubationsTime(1)], [-50000 50000]);
    haxesBamperLine2.setPosition([Vdata2(pertNumber).pertubationsTime(2) Vdata2(pertNumber).pertubationsTime(2)], [-50000 50000]);
    haxesCGLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesCGLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-50000 50000]);     
    haxesCGLine5.setPosition([Vdata2(pertNumber).RightarmsTime(1) Vdata2(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesCGLine6.setPosition([Vdata2(pertNumber).RightarmsTime(2) Vdata2(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesCGLine7.setPosition([Vdata2(pertNumber).cgOut(1) Vdata2(pertNumber).cgOut(1)], [-50000 50000]);
    haxesCGLine8.setPosition([Vdata2(pertNumber).cgOut(2) Vdata2(pertNumber).cgOut(2)], [-50000 50000]);    
    haxesCGLine9.setPosition([Vdata2(pertNumber).LeftarmsTime(1) Vdata2(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesCGLine10.setPosition([Vdata2(pertNumber).LeftarmsTime(2) Vdata2(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesCGLine11.setPosition([Vdata2(pertNumber).EndFirstStep Vdata2(pertNumber).EndFirstStep], [-50000 50000]);
    if Vdata2(pertNumber).cgOut(1)< 0
        set(checkBoxCG, 'value', 1);
    else
        set(checkBoxCG, 'value', 0);
    end
    
    axes(haxesStep);
    hold on
    set(haxesSFLine2, 'YData', [-50000 50000])
    set(haxesSFLine2, 'XData', [1 1])
    if length(Vdata)==24
    plotHandleLeftStep(pertNumber) = plot(haxesStep, Vdata( pertNumber).leftStepping,'color', 'g' ,'LineWidth',1.5); hold on
    plotHandleRightStep(pertNumber) = plot(haxesStep, Vdata( pertNumber).rightStepping,'color', 'r' ,'LineWidth',1.5); hold on
    else % walking 
        plotHandleLeftStep(pertNumber) =plot(haxesStep,0,0,'b'); hold on
       plotHandleRightStep(pertNumber)= plot(haxesStep,0,0); hold on
        
    end
    
    if length(Vdata)==12%mod(pertNumber, 2) == 0 || length(Vdata)==12 % left or right pertubation or walking protocol
        VelocityL=(Vdata(pertNumber).leftStepping(2:end)-Vdata(pertNumber).leftStepping(1:end-1))*120;
        VelocityR=(Vdata(pertNumber).rightStepping(2:end)-Vdata(pertNumber).rightStepping(1:end-1))*120;
        AccL=(VelocityL(2:end)-VelocityL(1:end-1))*120;
        AccR=(VelocityR(2:end)-VelocityR(1:end-1))*120;

        plotHandleLeftStepA(pertNumber) = plot(haxesStep,AccL ,'color', 'g' ,'LineWidth',1.5); hold on
        plotHandleRightStepA(pertNumber) = plot(haxesStep, AccR ,'color', 'r' ,'LineWidth',1.5); hold on
        ylabel(haxesStep,'Acceleration', 'fontname' , 'Cambria' , 'fontweight' , 'b');
        title(haxesStep, 'Step Acceleration');
         legend([plotHandleLeftStepA(pertNumber), plotHandleRightStepA(pertNumber)...
         ], 'left', 'right')
    else
       plotHandleLeftStepA(pertNumber) =plot(haxesStep,0,0); hold on
       plotHandleRightStepA(pertNumber)= plot(haxesStep,0,0); hold on
        ylabel(haxesStep,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
        title(haxesStep, 'Step');
         legend([plotHandleLeftStep(pertNumber), plotHandleRightStep(pertNumber)...
           ], 'left', 'right')
    end % if walking or left/right perturbation
%     
    xlabel(haxesStep,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
   % ylabel(haxesStep,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    %title(haxesStep, 'Step');
  haxesBamperLine1.setPosition([Vdata2(pertNumber).pertubationsTime(1) Vdata2(pertNumber).pertubationsTime(1)], [-50000 50000]);
    haxesBamperLine2.setPosition([Vdata2(pertNumber).pertubationsTime(2) Vdata2(pertNumber).pertubationsTime(2)], [-50000 50000]);
     haxesStepLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesStepLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-50000 50000]);     
    haxesStepLine5.setPosition([Vdata2(pertNumber).RightarmsTime(1) Vdata2(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesStepLine6.setPosition([Vdata2(pertNumber).RightarmsTime(2) Vdata2(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesStepLine7.setPosition([Vdata2(pertNumber).cgOut(1) Vdata2(pertNumber).cgOut(1)], [-50000 50000]);
    haxesStepLine8.setPosition([Vdata2(pertNumber).cgOut(2) Vdata2(pertNumber).cgOut(2)], [-50000 50000]);
   haxesStepLine9.setPosition([Vdata2(pertNumber).LeftarmsTime(1) Vdata2(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesStepLine10.setPosition([Vdata2(pertNumber).LeftarmsTime(2) Vdata2(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesStepLine11.setPosition([Vdata2(pertNumber).EndFirstStep Vdata2(pertNumber).EndFirstStep], [-50000 50000]);
    if length(Vdata)==12%mod(pertNumber, 2) == 0 || length(Vdata)==12 % left or right pertubation or walking protocol
        ylim(haxesStep,[min(min(AccL),min(AccR))-20 max(max(AccL),max(AccR))+20])
    else
        ylim(haxesStep,[min(min(Vdata(pertNumber).leftStepping),min(Vdata(pertNumber).rightStepping))-100 max(max(Vdata( pertNumber).leftStepping),max(Vdata(pertNumber).rightStepping))+ 100])
    end
        
    xlim(haxesStep,[1, length(Vdata(pertNumber).bamper)])
    %legend('slider','left', 'right')
    
    if Vdata2(pertNumber).steppingTime(1)< 0
        set(checkBoxStep, 'value', 1);
        set(listBoxStep,'value',3);
    else
        set(checkBoxStep, 'value', 0);
        if Vdata2(pertNumber).firstStep==1
            set(listBoxStep, 'value', 1);
        elseif Vdata2(pertNumber).firstStep==2  
            set(listBoxStep, 'value', 2);
        elseif Vdata2(pertNumber).firstStep==3
            set(listBoxStep, 'value', 3);
            set(checkBoxStep, 'value', 1);
        end
    end
    
    axes(haxesArms);
    hold on
    set(haxesSFLine4, 'YData', ylim)
    set(haxesSFLine4, 'XData', [1 1])
    plotHandleLeftArm( pertNumber) = plot(haxesArms, Vdata( pertNumber).leftArmTotal,'color', 'g' ,'LineWidth',1.5); hold on
    plotHandleRightArm(pertNumber) = plot(haxesArms, Vdata( pertNumber).rightArmTotal,'color', 'r' ,'LineWidth',1.5); hold on
    xlabel(haxesArms,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    ylabel(haxesArms,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
    title(haxesArms, 'Change in arms distance from CG');
  haxesBamperLine1.setPosition([Vdata2(pertNumber).pertubationsTime(1) Vdata2(pertNumber).pertubationsTime(1)], [-50000 50000]);
    haxesBamperLine2.setPosition([Vdata2(pertNumber).pertubationsTime(2) Vdata2(pertNumber).pertubationsTime(2)], [-50000 50000]);
     haxesArmsLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-50000 50000]);
    haxesArmsLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-50000 50000]);     
    haxesStepLine5.setPosition([Vdata2(pertNumber).RightarmsTime(1) Vdata2(pertNumber).RightarmsTime(1)], [-50000 50000]);
    haxesStepLine6.setPosition([Vdata2(pertNumber).RightarmsTime(2) Vdata2(pertNumber).RightarmsTime(2)], [-50000 50000]);
    haxesStepLine7.setPosition([Vdata2(pertNumber).cgOut(1) Vdata2(pertNumber).cgOut(1)], [-50000 50000]);
    haxesStepLine8.setPosition([Vdata2(pertNumber).cgOut(2) Vdata2(pertNumber).cgOut(2)], [-50000 50000]);
    haxesStepLine9.setPosition([Vdata2(pertNumber).LeftarmsTime(1) Vdata2(pertNumber).LeftarmsTime(1)], [-50000 50000]);
    haxesStepLine10.setPosition([Vdata2(pertNumber).LeftarmsTime(2) Vdata2(pertNumber).LeftarmsTime(2)], [-50000 50000]);
    haxesStepLine11.setPosition([Vdata2(pertNumber).EndFirstStep Vdata2(pertNumber).EndFirstStep], [-50000 50000]);
    ylim(haxesArms,[min(min(Vdata( pertNumber).leftArmTotal),min(Vdata( pertNumber).rightArmTotal))-100 max(max(Vdata( pertNumber).leftArmTotal),max(Vdata( pertNumber).rightArmTotal))+ 100])
    xlim(haxesArms,[1, length(Vdata(pertNumber).bamper)])
    %legend('slider','left', 'right')
    legend([plotHandleLeftArm(pertNumber), plotHandleRightArm(pertNumber)...
       ], 'left', 'right')
    if Vdata2(pertNumber).RightarmsTime(1)< 0
        set(checkBoxRightArms, 'value', 1);
    else
        set(checkBoxRightArms, 'value', 0);
    end
     if Vdata2(pertNumber).LeftarmsTime(1)< 0
        set(checkBoxLeftArms, 'value', 1);
    else
        set(checkBoxLeftArms, 'value', 0);
    end
    %ColorLines();  
    isPlotted2(pertNumber) = 1;    
    end
%     axes(haxesSF);
%     for ind = 1:3:length(Vdata(indexOfPatient, indexOfStep).SFdATA(1,:))
%         hold on
%         scatter3(haxesSF,Vdata(indexOfPatient, indexOfStep).SFdATA(1,ind),Vdata(indexOfPatient, indexOfStep).SFdATA(1,ind +1),Vdata(indexOfPatient, indexOfStep).SFdATA(1,ind +2), 'o')
%         hold on
%     end
axes(haxesSF);
     set(gca,'ydir','reverse')
     view(-11,-20)
    xlim([min(Vdata(pertNumber).SFdATA(1,1:3:end))-1, max(Vdata(pertNumber).SFdATA(1,1:3:end))+ 1])
    ylim([min(Vdata(pertNumber).SFdATA(1,2:3:end))-1, max(Vdata(pertNumber).SFdATA(1,2:3:end))+ 1])
    zlim([min(Vdata(pertNumber).SFdATA(1,3:3:end))-1, max(Vdata(pertNumber).SFdATA(1,3:3:end))+ 1])
    catch me
        h = errordlg(me.getReport)
    end
end
function saveButtonselected_cb(h,ev)
    try
       pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
     listbox=get(ListBoxPertubation, 'String');
     currentbox=listbox{get(ListBoxPertubation,'value'),1};
     if get(checkBoxHideBamper,'value')==1
         set(checkBoxHideBamper,'value',0)
         checkBoxHideBamper_call
     end
     if get(checkBoxHideCG,'value')==1
         set(checkBoxHideCG,'value',0)
         checkBoxHideCG_call
     end
     if get(checkBoxRightArms,'value')==0 && get(checkBoxHideRightArms,'value')==1
         set(checkBoxHideRightArms,'value',0)
         checkBoxHideRightArms_call
     end
     if get(checkBoxLeftArms,'value')==0 && get(checkBoxHideLeftArms,'value')==1
         set(checkBoxHideLeftArms,'value',0)
         checkBoxHideLeftArms_call
     end
     if get(checkBoxStep,'value')==0 && get(checkBoxHideSteps,'value')==1
         set(checkBoxHideSteps,'value',0)
         checkBoxHideSteps_call
     end
  %if isempty(findstr(currentbox,'green')) % if 1 - not analyzed , 0- analyzed
    
    %get positions of all lines
    haxesCGLine1Pos = round(haxesCGLine1.getPosition()); %bamper start
    haxesCGLine2Pos = round(haxesCGLine2.getPosition()); %bamper end
    haxesCGLine3Pos = round(haxesCGLine3.getPosition()); %step start
    haxesCGLine4Pos = round(haxesCGLine4.getPosition()); %step end
    haxesCGLine5Pos = round(haxesCGLine5.getPosition()); %armright start
    haxesCGLine6Pos = round(haxesCGLine6.getPosition()); %armright end
    haxesCGLine7Pos = round(haxesCGLine7.getPosition()); %cg start
    haxesCGLine8Pos = round(haxesCGLine8.getPosition()); %cg end
    haxesCGLine9Pos = round(haxesCGLine9.getPosition()); %armleft start
    haxesCGLine10Pos = round(haxesCGLine10.getPosition()); %armleft end
    haxesCGLine11Pos = round(haxesCGLine11.getPosition()); %end first step
    %update first and last fot
    if haxesCGLine3Pos(1,1)<0 
        %%%%%%%%%%%%%%%%%
        %%% add if to check if the step is hidden, if so then still do
        %%% updatestepping function
        firstStep = 0; %no steps
        lastStep = 0; %no steps
        
        set(listBoxStep,'value',3);
    else
        
    %update Vdata2: if the data is hidden then it is taken from vdata3    
    [firstStep, lastStep] = updateStepping(Vdata(pertNumber).leftStepping, Vdata(pertNumber).rightStepping, floor(haxesCGLine3Pos(1,1)), round(haxesCGLine4Pos(1,1)));
    end
    if get(listBoxStep,'value')~=firstStep
        listBoxStepvalue=get(listBoxStep,'value');
         Vdata2(pertNumber).firstStep=listBoxStepvalue;
    end
    if get(checkBoxHideRightArms,'value') == 0
        Vdata2(pertNumber).RightarmsTime = [haxesCGLine5Pos(1,1) haxesCGLine6Pos(1,1)];
    else
        Vdata2(pertNumber).RightarmsTime = Vdata3(pertNumber).RightarmsTime;
    end
    if get(checkBoxHideLeftArms,'value') == 0
        Vdata2(pertNumber).LeftarmsTime = [haxesCGLine9Pos(1,1) haxesCGLine10Pos(1,1)];
    else
        Vdata2(pertNumber).LeftarmsTime = Vdata3(pertNumber).LeftarmsTime;
    end
    
    if get(checkBoxHideSteps,'value') == 0
        Vdata2(pertNumber).steppingTime = [haxesCGLine3Pos(1,1) haxesCGLine4Pos(1,1)];
        Vdata2(pertNumber).EndFirstStep=haxesCGLine11Pos(1,1);
    else
        Vdata2(pertNumber).steppingTime = Vdata3(pertNumber).steppingTime;
        Vdata2(pertNumber).EndFirstStep = Vdata3(pertNumber).EndFirstStep;
        
    end
    
    if get(checkBoxHideCG,'value') == 0
        Vdata2(pertNumber).cgOut = [haxesCGLine7Pos(1,1) haxesCGLine8Pos(1,1)];
    else
        Vdata2(pertNumber).cgOut = Vdata3(pertNumber).cgOut;
    end
    
    if get(checkBoxHideCG,'value') == 0
        Vdata2(pertNumber).pertubationsTime = [haxesCGLine1Pos(1,1) haxesCGLine2Pos(1,1)];
    else
        Vdata2(pertNumber).pertubationsTime = Vdata3(pertNumber).pertubationsTime;
    end
    
    Vdata2(pertNumber).lastStep = lastStep;
    
    %update Vdata eddited

    Vdata(pertNumber).edited = true;
    listBoxPertu_call
    namestr = cellstr(get(ListBoxPertubation, 'String')); 
    Vdata(pertNumber).StringPer=namestr{pertNumber};
    %save data
    a=get(pathFolder,'string')
    save([a{2,1} '\Vdata_' patientName], 'Vdata');
    save([a{2,1} '\Vdata2_' patientName], 'Vdata2');
%     save(get(pathFolder,'string'), ['Vdata' get(currentFile,'string')]);
%     save(get(pathFolder,'string'), ['Vdata2' get(currentFile,'string')]); 
    set(typeOfLegMove,'string','');
    set(typeOfArmMove,'string','');
    set(checkBoxFall,'Value',0);
    set(checkBoxMS,'Value',0);
   % clearButtonselected_cb([],[]);
    if get(currentFile,'value')==24 && get(ListBoxPertubation,'value')<24
        set(ListBoxPertubation,'value',get(ListBoxPertubation,'value')+1)
    end
    if get(currentFile,'value')==12 && get(ListBoxPertubation,'value')<12
        set(ListBoxPertubation,'value',get(ListBoxPertubation,'value')+1)
    end  
    pause(0.1)
    drawButtonselected_cb([],[])
    catch me
        h = errordlg(me.getReport)
    end

end
function [stepping, firstStep,EndFirstStep, lastStep] = findStepping(left, right,condition)
    try
    firstStep = 0;
    lastStep = 0;
    if strcmp(condition,'Walking')
    
    
     VelocityL=(left(2:end)-left(1:end-1))*120; % the time is 1/120[sec]
       VelocityR=(right(2:end)-right(1:end-1))*120;
        AccL=(VelocityL(2:end)-VelocityL(1:end-1))*120;
       AccR=(VelocityR(2:end)-VelocityR(1:end-1))*120;
        leftStart = find(abs(AccL( 11:end) - AccL( 1:end -10))>0.9*120*120, 1, 'first');    
        rightStart = find(abs(AccR( 11:end) - AccR( 1:end -10))>0.9*120*120, 1, 'first');
        if isempty(leftStart) && isempty(rightStart)
            stepping(1:2) =-5000;
            EndFirstStep=-5000;
        elseif isempty(leftStart) && ~isempty(rightStart)
            stepping(1) = rightStart;
            %leftEnd = find(abs(left(stepping(1) +  31:end) - left(stepping(1)+ 1:end -30))<0.5, 1, 'last');
            rightEnd = find(abs(AccR(stepping(1) +  11:end) - AccR(stepping(1) + 1:end -10))<0.01*120*120, 1, 'first');
            EndFirstStep = stepping(1) + rightEnd;
            firstStep =1;
            lastStep = 1;
            %[pks,locs] = findpeaks(AccR(stepping(1):stepping(2)));
            [pks,locs] = findpeaks(AccR(EndFirstStep:end));
                 index=find(pks>0.4*120*120,1,'last')
                if isempty(locs) ||isempty(index )
                    stepping(2)=EndFirstStep;
                    %[pks,locs] = max(AccR(stepping(1):stepping(2)))
                else
                     %EndFirstStep=locs(1)+stepping(1);
                     index=find(pks>0.4*120*120,1,'last')
                     stepping(2)=locs(index)+EndFirstStep;
                 end

        elseif ~isempty(leftStart) && isempty(rightStart)
            stepping(1) = leftStart;
            leftEnd = find(abs(AccL(stepping(1) +  11:end) - AccL(stepping(1)+ 1:end -10))<0.01*120*120, 1, 'first');
            EndFirstStep = stepping(1) + leftEnd;
            firstStep =2;
            lastStep = 2;
             %[pks,locs] = findpeaks(AccL(stepping(1):stepping(2)));
             [pks,locs] = findpeaks(AccL(EndFirstStep:end));
             index=find(pks>0.4*120*120,1,'last')
            if isempty(locs) ||isempty(index )
                stepping(2)=EndFirstStep;
                %[pks,locs] = max(AccL(stepping(1):stepping(2)))
            else
                index=find(pks>0.4*120*120,1,'last')
                 stepping(2)=locs(index)+EndFirstStep;

            end

        else
            stepping(1) = min(leftStart, rightStart);
            leftEnd = find(abs(AccL(stepping(1) +  11:end) - AccL(stepping(1)+ 1:end -10))<0.01*120*120, 1, 'first');
            rightEnd = find(abs(AccR(stepping(1) +  11:end) - AccR(stepping(1) + 1:end-10 ))<0.01*120*120, 1, 'first');
            EndFirstStep =stepping(1) + max(leftEnd, rightEnd);
            if(leftStart >rightStart)
                firstStep =1;%right first
                 [pks,locs] = findpeaks(AccR(EndFirstStep:end));
                index=find(pks>0.4*120*120,1,'last')
                if isempty(locs) ||isempty(index )
                     stepping(2)=EndFirstStep;
                    %[pks,locs] = max(AccR(EndFirstStep:end))
                else
                    index=find(pks>0.4*120*120,1,'last')
                     stepping(2)=locs(index)+EndFirstStep;
                end
            else
                firstStep =2;%left first
                 [pks,locs] = findpeaks(AccL(EndFirstStep:end));
                 index=find(pks>0.4*120*120,1,'last')
                if isempty(locs) ||isempty(index )
                     stepping(2)=EndFirstStep;
                   % [pks,locs] = max(AccL(stepping(1):stepping(2)))
                else
                    index=find(pks>0.4*120*120,1,'last')
                     stepping(2)=locs(index)+EndFirstStep;
                end
            end
            
            if leftEnd >= rightEnd
                lastStep = 2;% left last
            else
                lastStep = 1;%right last
            end
            
        end
    end
    
%     if strcmp(condition,'Walking')
%         leftStart = find(abs(left( 31:end) - left( 1:end -30))>40, 1, 'first');    
%         rightStart = find(abs(right( 31:end) - right( 1:end -30))>40, 1, 'first');
%         if isempty(leftStart) && isempty(rightStart)
%             stepping(1:2) =-5000;
%             EndFirstStep=-5000;
%         elseif isempty(leftStart) && ~isempty(rightStart)
%             stepping(1) = rightStart;
%             %leftEnd = find(abs(left(stepping(1) +  31:end) - left(stepping(1)+ 1:end -30))<0.5, 1, 'last');
%             rightEnd = find(abs(right(stepping(1) +  31:end) - right(stepping(1) + 1:end -30))>40, 1, 'last');
%             stepping(2) = stepping(1) + rightEnd;
%             firstStep =1;
%             lastStep = 1;
%             [pks,locs] = findpeaks(right(stepping(1):stepping(2)));
%                 if isempty(locs)
%                     [pks,locs] = max(right(stepping(1):stepping(2)))
%                 end
%              EndFirstStep=locs(1)+stepping(1);
% 
%         elseif ~isempty(leftStart) && isempty(rightStart)
%             stepping(1) = leftStart;
%             leftEnd = find(abs(left(stepping(1) +  31:end) - left(stepping(1)+ 1:end -30))>40, 1, 'last');
%             stepping(2) = stepping(1) + leftEnd;
%             firstStep =2;
%             lastStep = 2;
%              [pks,locs] = findpeaks(left(stepping(1):stepping(2)));
%             if isempty(locs)
%                 [pks,locs] = max(left(stepping(1):stepping(2)))
%             end
%             EndFirstStep=locs(1)+stepping(1);
% 
%         else
%             stepping(1) = min(leftStart, rightStart);
%             leftEnd = find(abs(left(stepping(1) +  31:end) - left(stepping(1)+ 1:end -30))>40, 1, 'last');
%             rightEnd = find(abs(right(stepping(1) +  31:end) - right(stepping(1) + 1:end -30))>40, 1, 'last');
%             stepping(2) =stepping(1) + max(leftEnd, rightEnd);
%             if(leftStart >rightStart)
%                 firstStep =1;%right first
%                  [pks,locs] = findpeaks(right(stepping(1):stepping(2)));
%                 if isempty(locs)
%                     [pks,locs] = max(right(stepping(1):stepping(2)))
%                 end
%                 EndFirstStep=locs(1)+stepping(1);
%             else
%                 firstStep =2;%left first
%                  [pks,locs] = findpeaks(left(stepping(1):stepping(2)));
%                 if isempty(locs)
%                     [pks,locs] = max(left(stepping(1):stepping(2)))
%                 end
%                 EndFirstStep=locs(1)+stepping(1);
%             end
%             
%             if leftEnd >= rightEnd
%                 lastStep = 2;% left last
%             else
%                 lastStep = 1;%right last
%             end
%             
%         end
%     end
    if strcmp(condition,'Standing')
        x = find(abs(left-right)>7, 1, 'first');  
        y = find(abs(left-right)>7, 1, 'last');
        if isempty(x) 
            stepping(1:2) =-5000;
            EndFirstStep=-5000;
        else
            stepping(1)=x;
            stepping(2)=find(abs(left-right)>7, 1, 'last'); 
            if(left(x) > right(x))
                firstStep =2; % left first
                [pks,locs] = findpeaks(left(stepping(1):stepping(2)));
                if isempty(locs)
                    [pks,locs] = max(left(stepping(1):stepping(2)))
                end
                EndFirstStep=locs(1)+stepping(1);
            else
                firstStep =1; % right first
                [pks,locs] = findpeaks(right(stepping(1):stepping(2)));
                if isempty(locs)
                    [pks,locs] = max(right(stepping(1):stepping(2)))
                end
                EndFirstStep=locs(1)+stepping(1);

            end
                
            if(left(y) > right(y))
                lastStep =2; % left last
            else
                lastStep =1; % right last
            end
            
        end
        
    end
    catch me
        h = errordlg(me.getReport)
    end
end
function [firstStep, lastStep] = updateStepping(left, right, startindex, endindex)
    try
    if(left(startindex) >right(startindex))
        firstStep =2;
    else
        firstStep =1;
    end

    if(left(endindex) >right(endindex))
        lastStep =2;
    else
        lastStep =1;
    end
    catch me
        h = errordlg(me.getReport)
    end
    
    
end
function [Rightarms,Leftarms] = findArms(left, right)
    try
    leftStart = find(abs(left( 31:end) - left( 1:end -30))>50, 1, 'first');    
    rightStart = find(abs(right( 31:end) - right( 1:end -30))>50, 1, 'first');
    if isempty(leftStart) && isempty(rightStart)
        Rightarms(1:2) =-5000;
        Leftarms(1:2) =-5000;
    elseif isempty(leftStart) && ~isempty(rightStart)
        Rightarms(1) = rightStart;
        Leftarms(1:2) =-5000;
      %  leftEnd = find(abs(left(arms(1) +  31:end) - left(arms(1)+ 1:end -30))<5, 1, 'last');
    rightEnd = find(abs(right(Rightarms(1) +  31:end) - right(Rightarms(1) + 1:end -30))>50, 1, 'last');
    Rightarms(2) = Rightarms(1) + rightEnd;
    elseif ~isempty(leftStart) && isempty(rightStart)
        Leftarms(1) = leftStart;
        Rightarms(1:2)=-5000;
        leftEnd = find(abs(left(Leftarms(1) +  31:end) - left(Leftarms(1)+ 1:end -30))>50, 1, 'last');
  %  rightEnd = find(abs(right(arms(1) +  31:end) - right(arms(1) + 1:end -30))<5, 1, 'last');
    Leftarms(2) = Leftarms(1) + leftEnd;
    else
        Rightarms(1) = rightStart;
        Leftarms(1) = leftStart;
    leftEnd = find(abs(left(Leftarms(1) +  31:end) - left(Leftarms(1)+ 1:end -30))>40, 1, 'last');
    rightEnd = find(abs(right(Rightarms(1) +  31:end) - right(Rightarms(1) + 1:end -30))>40, 1, 'last');
    Rightarms(2) =Rightarms(1) + rightEnd;
    Leftarms(2) =Leftarms(1) + leftEnd;
    end
    catch me
        h = errordlg(me.getReport)
    end
end
function cgOut = findCG(left, right,HeelR,ToeR, CG,pertubation_type)
    if pertubation_type==1 % left rigth pertubation
        try
        leftout = find(CG> left,1,'first');
        rightout = find(CG< right,1,'first');

       if isempty(leftout) && isempty(rightout)
            cgOut(1:2) =-5000;
        elseif isempty(leftout) && ~isempty(rightout)
            cgOut(1) = rightout;
            %cgOut(2) = find(abs(CG)> abs(right),1,'last');
            cgOut(2) = find(abs(CG(cgOut(1):end))< abs(right(cgOut(1):end)),1,'first')+cgOut(1);
        elseif ~isempty(leftout) && isempty(rightout)
            cgOut(1) = leftout;
            %cgOut(2) = find(abs(CG)> abs(left),1,'last');
            cgOut(2) = find(abs(CG(cgOut(1):end))< abs(left(cgOut(1):end)),1,'first')+cgOut(1);
        else
        cgOut(1) = min(leftout, rightout);
        %leftEnd = find(abs(CG)> abs(left),1,'last');
        %rightEnd = find(abs(CG)> abs(right),1,'last');
        leftEnd = find(abs(CG(cgOut(1):end))< abs(left(cgOut(1):end)),1,'first');
        rightEnd = find(abs(CG(cgOut(1):end))< abs(right(cgOut(1):end)),1,'first');
        cgOut(2) = min(leftEnd, rightEnd)+cgOut(1);
       end
       catch me
            h = errordlg(me.getReport)
        end
    elseif pertubation_type==2 % front back pertubation
        HeelL=left;
        ToeL=right;
        try
        HeelL_out = find((CG> HeelL)&(CG>HeelR),1,'first');
        ToeL_out = find((CG< ToeL)&(CG<ToeR),1,'first');

       if isempty(HeelL_out) && isempty(ToeL_out)
            cgOut(1:2) =-5000;
        elseif isempty(HeelL_out) && ~isempty(ToeL_out)
            cgOut(1) = ToeL_out;
            cgOut(2) = find((CG(cgOut(1):end)>ToeR(cgOut(1):end))|(CG(cgOut(1):end)>ToeL(cgOut(1):end)),1,'first')+cgOut(1);
        elseif ~isempty(HeelL_out) && isempty(ToeL_out)
            cgOut(1) = HeelL_out;
            cgOut(2) = find((CG(cgOut(1):end)<HeelR(cgOut(1):end))|(CG(cgOut(1):end)<HeelL(cgOut(1):end)),1,'first')+cgOut(1);
        else
        cgOut(1) = min(HeelL_out, ToeL_out);
        HeelLEnd = find((CG(cgOut(1):end)<HeelR(cgOut(1):end))|(CG(cgOut(1):end)<HeelL(cgOut(1):end)),1,'first');
        ToeLEnd = find((CG(cgOut(1):end)>ToeR(cgOut(1):end))|(CG(cgOut(1):end)>ToeL(cgOut(1):end)),1,'first');
        cgOut(2) = min(HeelLEnd, ToeLEnd)+cgOut(1);
       end
       catch me
            h = errordlg(me.getReport)
        end
    end
end
function pertubationsTime = findPertubations(bamperX, searchIndex,pervurationType)
    try
    % pervurationType - 1: backward forward; 
    % pervurationType - 2:  right left;
   if pervurationType==2
       % the lines in the % refers only to the file of NOY COHEN DT
       % STANDING!
           %firstSidePertubation = find(abs(bamperX(searchIndex + 31:end -1) - bamperX(searchIndex + 1:end -31))>8, 1, 'first');
    firstSidePertubation = find(abs(bamperX(searchIndex + 31:end -1) - bamperX(searchIndex + 1:end -31))>10, 1, 'first');
   % firstSidePertubation = find(abs(bamperX(searchIndex + 31:end -1) - bamperX(searchIndex + 1:end -31))>12, 1, 'first');

    secondSidePertubation = find(abs(bamperX(searchIndex+firstSidePertubation + 70:end) - bamperX(searchIndex + firstSidePertubation:end -70))<0.1, 1, 'first');
   else % standing
       % the lines in the % refers only to the file of NOY COHEN DT
       % STANDING!
%        if searchIndex>=4000 && searchIndex<=5000
%           firstSidePertubation = find(abs(bamperX(searchIndex + 91:end -1) - bamperX(searchIndex + 1:end -91))>15, 1, 'first');
%        else
          firstSidePertubation = find(abs(bamperX(searchIndex + 61:end -1) - bamperX(searchIndex + 1:end -61))>20, 1, 'first');
%        end
      
       %firstSidePertubation = find(abs(bamperX(searchIndex + 91:end -1) - bamperX(searchIndex + 1:end -91))>15, 1, 'first');
        secondSidePertubation = find(abs(bamperX(searchIndex+firstSidePertubation + 70:end) - bamperX(searchIndex + firstSidePertubation:end -70))<0.1, 1, 'first');
   end
    pertubationstime = [searchIndex + firstSidePertubation, searchIndex + firstSidePertubation + secondSidePertubation];
    % to check again!!
    if pervurationType == 2;
        bampernew=bamperX(pertubationstime(1) :pertubationstime(2));
        [~,maxInd]=max(bampernew);
        [~,minInd]=min(bampernew);
        if minInd<maxInd
            pertubationsTimenew(1)=minInd;
            pertubationsTimenew(2)=maxInd;
        else
            pertubationsTimenew(1)=maxInd;
            pertubationsTimenew(2)=minInd;
        end
        pertubationsTime(1)=pertubationsTimenew(1)+pertubationstime(1) -1;
        pertubationsTime(2)=pertubationstime(1) + pertubationsTimenew(2) -1 ;
    else
        pertubationsTime=pertubationstime;
    end

%     if pervurationType == 2;
%         bampernew=bamperX(pertubationstime(1) -240 :pertubationstime(2)+240);
%         [~,maxInd]=max(bampernew);
%         [~,minInd]=min(bampernew);
%         if minInd<maxInd
%             pertubationsTimenew(1)=find(bampernew(1:maxInd)<=bamperX(pertubationstime(1)),1,'last');
%             pertubationsTimenew(2)=find(bampernew(minInd:end)>=bamperX(pertubationstime(2)),1,'first');
%         else
%             pertubationsTimenew(1)=find(bampernew(1:minInd)>=bamperX(pertubationstime(1)),1,'first');
%             pertubationsTimenew(2)=find(bampernew(maxInd:end)<=bamperX(pertubationstime(2)),1,'last');
%         end
%         pertubationsTime(1)=pertubationsTimenew(1)+pertubationstime(1)-240;
%         pertubationsTime(2)=pertubationsTime(1) + pertubationsTimenew(2) ;
%     else
%         pertubationsTime=pertubationstime;
%     end
    catch me
        h = errordlg(me.getReport)
    end
end
function exportButtonselected_cb(h,ev)
    try
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
    headlineS = {'Step',	'Pertubation side: [1]Right/[2]Left/[3]Forward/[4]Backward',	'Response time [msec])', 'Time from bamper movement until end of 1st step [msec]',	'First step duration [msec]',...
        'First step length [mm]',	'Time from bamper movement until end of all steps [msec]',...
        'Maximal distance of ending-movement foot from its` start point [mm]',...
        'Is CG out of base support before movement 0-in base,1-not in base',...
        'Time between lose of balance and beginning of step [msec]',...
        'Minimal distance of CG from legs before movement [mm]',...
        'Distance of CG from leg at the step-beginning point [mm]',...
        'Maximal distance of CG from balance point [mm]',...
        'Total distance CG made [mm]', 'Right arm distance [mm]', 'Left arm distnace [mm]',...
        'Time from bamper movement until right arm lift [msec]', 'Right arm swing time [msec]',...
        'Time from bamper movement until left arm lift [msec]', 'Left arm swing time [msec]','Fall','MultiSteps','TypeArmMove','TypeLegMove','LElbowAngX[deg]','LShoulderAngX[deg]','LShoulderAngY[deg]','LShoulderAngZ[deg]','RElbowAngX[deg]','RShoulderAngX[deg]','RShoulderAngY[deg]','RShoulderAngZ[deg]','First Step Length[mm] - Bamper FB'};
    if isempty(strfind(patientName, 'Walk')) && isempty(strfind(patientName, 'walk'))%standing protocol
        protocol = repmat([4,2,3,1],1,6)';
        index = (1:24)';
    else %walking protocol
        protocol = repmat([1, 2],1,6)';
        index = (1:12)';
    end
    %set all output arrays nan 
    BamperToEndOfSteps = ones(length(index),1); BamperToEndOfSteps = BamperToEndOfSteps*99999;
    firstStepLengh = ones(length(index),1); firstStepLengh = firstStepLengh*99999;
    firstStepLengh2 = ones(length(index),1); firstStepLengh2 = firstStepLengh2*99999;
    firstStepDuration = ones(length(index),1); firstStepDuration = firstStepDuration*99999;
    responseTime = ones(length(index),1); responseTime = responseTime*99999;
    BamperToEndFirstStep = ones(length(index),1); BamperToEndFirstStep = BamperToEndFirstStep*99999;
    lastStepMax = ones(length(index),1); lastStepMax = lastStepMax*99999;
    cgOutBeforeMovemnent = ones(length(index),1); cgOutBeforeMovemnent = cgOutBeforeMovemnent*99999;
    loseOfBalanceToFirstStep = ones(length(index),1); loseOfBalanceToFirstStep = loseOfBalanceToFirstStep*99999;
    minCGDistFromLeg = ones(length(index),1); minCGDistFromLeg = minCGDistFromLeg*99999;
    CGToNearestAtFirstStep = ones(length(index),1); CGToNearestAtFirstStep = CGToNearestAtFirstStep*99999;
    MaxCGOutFromLeg = ones(length(index),1); MaxCGOutFromLeg = MaxCGOutFromLeg*99999;
    totalDistCGMade = ones(length(index),1); totalDistCGMade = totalDistCGMade*99999;
    rightArmDistance = ones(length(index),1); rightArmDistance = rightArmDistance*99999;
    leftArmDistance = ones(length(index),1); leftArmDistance = leftArmDistance*99999;
    BamperToRightArmTime = ones(length(index),1); BamperToRightArmTime = BamperToRightArmTime*99999;
    rightArmSwingTime = ones(length(index),1); rightArmSwingTime = rightArmSwingTime*99999;
    BamperToLeftArmTime = ones(length(index),1); BamperToLeftArmTime = BamperToLeftArmTime*99999;
    leftArmSwingTime = ones(length(index),1); leftArmSwingTime = leftArmSwingTime*99999;
    Fall=zeros(length(index),1);
    MS=zeros(length(index),1);
    TypeArmMove=cell(length(index),1);
    TypeLegMove=cell(length(index),1);
    Perturbation_dist=[30 30 30 30 60 60 60 60 90 90 90 90 120 120 120 120 150 150 150 150 180 180 180 180];
    % 1-right, 2-left, 3-forward, 4-backward
    direction=[4 2 3 1 4 2 3 1 4 2 3 1 4 2 3 1 4 2 3 1 4 2 3 1] 
    %run over all perturbations
    
        for i =1:length(index)  
            if length(index)==12 || mod(i,2)==0 % walking protocol or standing protocol in pertubations left right
                %get all perturbations with right arm reactions
                Fall(i)= Vdata2( i).Fall;
                MS(i)= Vdata2( i).MS;
                TypeArmMove{i}=Vdata2( i).TypeArmMove;
                TypeLegMove{i}=Vdata2( i).TypeLegMove;
                responseTimeIndexes = Vdata2( i).RightarmsTime(1) >=0;
                if(responseTimeIndexes) %
                    %[rightArmDistance(i), rightMaxInd] = max(abs(Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1):end) - Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1))));            
                   [rightArmDistance(i), rightMaxInd] = max(abs(sqrt(((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),67)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),121))-(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),67)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),121))).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),68)).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),69)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),69)).^2)));
                    BamperToRightArmTime(i) =(Vdata2(i).RightarmsTime(1)-Vdata2(i).pertubationsTime(1))/0.12;
                    rightArmSwingTime(i) = rightMaxInd/0.12;
                    RElbowAng(i)=Vdata(i).RElbowAng(Vdata2(i).RightarmsTime(2))-Vdata(i).RElbowAng(Vdata2(i).RightarmsTime(1));
                    RShoulderAng(i,:)=Vdata(i).RShoulderAng(Vdata2(i).RightarmsTime(2),:)-Vdata(i).RShoulderAng(Vdata2(i).RightarmsTime(1),:);
                end

                responseTimeIndexes = Vdata2( i).LeftarmsTime(1) >=0;
                if(responseTimeIndexes) %
                   % [leftArmDistance(i), leftMaxInd] = max(abs(Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1):end) - Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1))));                  
                   [leftArmDistance(i), leftMaxInd] = max(abs(sqrt(((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),46)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),121))-(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),46)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),121))).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),47)).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),48)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),48)).^2)));
                   BamperToLeftArmTime(i) =(Vdata2(i).LeftarmsTime(1)-Vdata2(i).pertubationsTime(1)) /0.12;
                    leftArmSwingTime(i) = leftMaxInd/0.12;
                    LElbowAng(i)=Vdata(i).LElbowAng(Vdata2(i).LeftarmsTime(2))-Vdata(i).LElbowAng(Vdata2(i).LeftarmsTime(1));
                    LShoulderAng(i,:)=Vdata(i).LShoulderAng(Vdata2(i).LeftarmsTime(2),:)-Vdata(i).LShoulderAng(Vdata2(i).LeftarmsTime(1),:);
                end

                %get all perturbations with stepping reactions
                responseTimeIndexes = Vdata2(i).steppingTime(1) >=0;
                if(responseTimeIndexes)

                    totalDistCGMade(i) = sum(abs(diff(Vdata(i).CGX(241:end))));
                    CGToNearestAtFirstStep(i) = min([abs(Vdata(i).CGX(Vdata2( i).steppingTime(1))...
                        - Vdata(i).leftAnkleX(Vdata2( i).steppingTime(1))),...
                        abs(Vdata(i).CGX(Vdata2( i).steppingTime(1))...
                        - Vdata(i).rightAnkleX(Vdata2(i).steppingTime(1)))])

                    if abs(Vdata(i).CGX(end) - Vdata(i).leftAnkleX(end)) > abs(Vdata(i).CGX(end) - Vdata(i).rightAnkleX(end))
                        cgtoleg = 1; %cg moves towards right foot
                    else
                        cgtoleg = 2; %cg moves towards left foot
                    end
                    if Vdata2(i).cgOut(1) < 0
                        cgOutBeforeMovemnent(i) = 0;
                        if(cgtoleg == 1)
                            minCGDistFromLeg(i) = min(abs(Vdata(i).CGX(1:Vdata2(i).steppingTime(1)) - Vdata(i).rightAnkleX(1:Vdata2(i).steppingTime(1))))
                        else
                            minCGDistFromLeg(i) = min(abs(Vdata(i).CGX(1:Vdata2(i).steppingTime(1)) - Vdata(i).leftAnkleX(1:Vdata2(i).steppingTime(1))))
                        end
                    else

                       % [~, indmax] = max(abs(Vdata(i).CGX(Vdata(i).cgOut(1):Vdata(i).cgOut(2)))-);
                       %indmax=indmax+Vdata(i).cgOut(1);
                        MaxCGOutFromLeg(i) = min([max(abs(Vdata(i).CGX(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)) - Vdata(i).leftAnkleX(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)))),max(abs(Vdata(i).CGX(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)) - Vdata(i).rightAnkleX(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2))))])
                        if Vdata2(i).cgOut(1) < Vdata2(i).steppingTime(1)
                            cgOutBeforeMovemnent(i) = 1;
                            loseOfBalanceToFirstStep(i) = (Vdata2(i).steppingTime(1) - Vdata2(i).cgOut(1))/0.12;
                        else
                            cgOutBeforeMovemnent(i) = 0;
                        if(cgtoleg == 1)
                            minCGDistFromLeg(i) = min(abs(Vdata(i).CGX(1:Vdata2(i).steppingTime(1)) - Vdata(i).rightAnkleX(1:Vdata2( i).steppingTime(1))))
                        else
                            minCGDistFromLeg(i) = min(abs(Vdata(i).CGX(1:Vdata2(i).steppingTime(1)) - Vdata(i).leftAnkleX(1:Vdata2(i).steppingTime(1))))
                        end                    
                        end
                    end

                    responseTime(i) = (Vdata2(i).steppingTime(1) - Vdata2(i).pertubationsTime(1))/0.12;%turn to miliseconds
                    BamperToEndOfSteps(i) = (Vdata2(i).steppingTime(2) -  Vdata2(i).pertubationsTime(1))/0.12;
                    if Vdata2(i).firstStep == 1 %right leg first
                        BamperToEndFirstStep(i) = (Vdata2 (i).EndFirstStep-Vdata2(i).pertubationsTime(1))/0.12;
%                         firstStepLengh(i) = abs(Vdata(i).rightStepping(Vdata2( i).EndFirstStep)...
%                              -  Vdata(i).rightStepping(Vdata2(i).steppingTime(1)));    
                         firstStepLengh(i) = abs(sqrt(((Vdata(i).SFdATA(Vdata2(i).EndFirstStep,109)-Vdata(i).SFdATA(Vdata2(i).EndFirstStep,121))-(Vdata(i).SFdATA(Vdata2(i).steppingTime(1),109)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),121)))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,110)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),110))^2));

                    else
                        BamperToEndFirstStep(i) = (Vdata2 (i).EndFirstStep- Vdata2(i).pertubationsTime(1))/0.12;     
%                         firstStepLengh(i) = abs(Vdata(i).leftStepping(Vdata2(i).EndFirstStep)...
%                              -  Vdata(i).leftStepping(Vdata2(i).steppingTime(1)));
                        firstStepLengh(i) = abs(sqrt(((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,91)-Vdata(i).SFdATA(Vdata2( i).EndFirstStep,121))-(Vdata(i).SFdATA(Vdata2(i).steppingTime(1),91)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),121)))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,92)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),92))^2));    

                    end
                    if Vdata2(i).lastStep == 1 %right leg end 
                        %lastStepMax(i) = abs(max(Vdata(i).rightStepping) - Vdata(i).rightStepping(Vdata2(i).steppingTime(1)));
                        
                        lastStepMax(i) = max(abs(sqrt(((Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),109)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),121))-(Vdata(i).SFdATA(Vdata2(i).steppingTime(1),109)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),121))).^2+(Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),110)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),110)).^2)));  
                    else
                        %lastStepMax(i) = abs(max(Vdata(i).leftStepping) - Vdata(i).leftStepping(Vdata2(i).steppingTime(1)));
                        lastStepMax(i) = max(abs(sqrt(((Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),91)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),121))-(Vdata(i).SFdATA(Vdata2(i).steppingTime(1),91)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),121))).^2+(Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),92)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),92)).^2)));  

                    end           
                    firstStepDuration(i) = BamperToEndFirstStep(i) - responseTime(i);          
                end
                
            else % standing protocol in forward backward pertubation
                
                %get all perturbations with right arm reactions
                Fall(i)= Vdata2( i).Fall;
                MS(i)= Vdata2( i).MS;
                TypeArmMove{i}=Vdata2( i).TypeArmMove;
                TypeLegMove{i}=Vdata2( i).TypeLegMove;
                responseTimeIndexes = Vdata2( i).RightarmsTime(1) >=0;
                if(responseTimeIndexes) %
                    %[rightArmDistance(i), rightMaxInd] = max(abs(Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1):end) - Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1))));            
                    [rightArmDistance(i), rightMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),67)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),67)).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),69)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),69)).^2+((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2),92))-(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),92))).^2)));

                    %[rightArmDistance(i), rightMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,67)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),67)).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),68)).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,69)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),69)).^2)));
                    BamperToRightArmTime(i) =(Vdata2(i).RightarmsTime(1) -Vdata2(1).pertubationsTime(1))/0.12;
                    rightArmSwingTime(i) = rightMaxInd /0.12;
                    RElbowAng(i)=Vdata(i).RElbowAng(Vdata2(i).RightarmsTime(2))-Vdata(i).RElbowAng(Vdata2(i).RightarmsTime(1));
                    RShoulderAng(i,:)=Vdata(i).RShoulderAng(Vdata2(i).RightarmsTime(2),:)-Vdata(i).RShoulderAng(Vdata2(i).RightarmsTime(1),:);

                end

                responseTimeIndexes = Vdata2( i).LeftarmsTime(1) >=0;
                if(responseTimeIndexes) %
                    %[leftArmDistance(i), leftMaxInd] = max(abs(Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1):end) - Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1))));                  
                    [leftArmDistance(i), leftMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),46)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),46)).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),48)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),48)).^2+((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2),92))-(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),92))).^2)));

                    %[leftArmDistance(i), leftMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,46)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),46)).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),47)).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,48)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),48)).^2)));
                    BamperToLeftArmTime(i) =(Vdata2(i).LeftarmsTime(1) -Vdata2(1).pertubationsTime(1))/0.12;
                    leftArmSwingTime(i) = leftMaxInd /0.12;
                    LElbowAng(i)=Vdata(i).LElbowAng(Vdata2(i).LeftarmsTime(2))-Vdata(i).LElbowAng(Vdata2(i).LeftarmsTime(1));
                    LShoulderAng(i,:)=Vdata(i).LShoulderAng(Vdata2(i).LeftarmsTime(2),:)-Vdata(i).LShoulderAng(Vdata2(i).LeftarmsTime(1),:);
                end

                %get all perturbations with stepping reactions
                responseTimeIndexes = Vdata2(i).steppingTime(1) >=0;
                if(responseTimeIndexes)

                    totalDistCGMade(i) = sum(abs(diff(Vdata(i).CGY(241:end))));
                    CGToNearestAtFirstStep(i) = min((min([abs(Vdata(i).CGY(Vdata2( i).steppingTime(1))...
                        - Vdata(i).leftHeelY(Vdata2( i).steppingTime(1))),...
                        abs(Vdata(i).CGY(Vdata2( i).steppingTime(1))...
                        - Vdata(i).leftToeY(Vdata2(i).steppingTime(1)))])),...
                        (min([abs(Vdata(i).CGY(Vdata2( i).steppingTime(1))...
                        - Vdata(i).rightHeelY(Vdata2( i).steppingTime(1))),...
                        abs(Vdata(i).CGY(Vdata2( i).steppingTime(1))...
                        - Vdata(i).rightToeY(Vdata2(i).steppingTime(1)))])))

                    if abs(Vdata(i).CGY(end) - Vdata(i).leftHeelY(end)) > abs(Vdata(i).CGY(end) - Vdata(i).leftToeY(end))
                        cgtoleg = 3; %cg moves towards Toes
                    else
                        cgtoleg = 4; %cg moves towards Ankles
                    end
                    if Vdata2(i).cgOut(1) < 0
                        cgOutBeforeMovemnent(i) = 0;
                        if(cgtoleg == 3) % toes
                            minCGDistFromLeg(i) = min((abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).leftToeY(1:Vdata2(i).steppingTime(1))))),(abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).rightToeY(1:Vdata2(i).steppingTime(1))))))
                        else % heels
                            minCGDistFromLeg(i) = min((abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).leftHeelY(1:Vdata2(i).steppingTime(1))))),(abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).rightHeelY(1:Vdata2(i).steppingTime(1))))))
                        end
                    else % cg out 

                       % [~, indmax] = max(abs(Vdata(i).CGY(Vdata(i).cgOut(1):Vdata(i).cgOut(2))));
                       % indmax=indmax+Vdata(i).cgOut(1);
                        MaxCGOutFromLeg(i) = min([max(abs(Vdata(i).CGY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)) - Vdata(i).leftHeelY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)))),max(abs(Vdata(i).CGY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)) - Vdata(i).leftToeY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)))),max(abs(Vdata(i).CGY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)) - Vdata(i).rightHeelY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)))),max(abs(Vdata(i).CGY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2)) - Vdata(i).rightToeY(Vdata2(i).cgOut(1):Vdata2(i).cgOut(2))))])
                       % MaxCGOutFromLeg(i) = min([max(abs(Vdata(i).CGX(Vdata(i).cgOut(1):Vdata(i).cgOut(2)) - Vdata(i).leftAnkleX(Vdata(i).cgOut(1):Vdata(i).cgOut(2)))),max(abs(Vdata(i).CGX(Vdata(i).cgOut(1):Vdata(i).cgOut(2)) - Vdata(i).rightAnkleX(Vdata(i).cgOut(1):Vdata(i).cgOut(2))))])

                        if Vdata2(i).cgOut(1) < Vdata2(i).steppingTime(1)
                            cgOutBeforeMovemnent(i) = 1;
                            loseOfBalanceToFirstStep(i) = (Vdata2(i).steppingTime(1) - Vdata2(i).cgOut(1))/0.12;
                        else
                            cgOutBeforeMovemnent(i) = 0;
                            if(cgtoleg == 3) % toes
                                minCGDistFromLeg(i) = min((abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).leftToeY(1:Vdata2(i).steppingTime(1))))),(abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).rightToeY(1:Vdata2(i).steppingTime(1))))))
                            else % heels
                                minCGDistFromLeg(i) = min((abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).leftHeelY(1:Vdata2(i).steppingTime(1))))),(abs(min(Vdata(i).CGY(1:Vdata2(i).steppingTime(1)) - Vdata(i).rightHeelY(1:Vdata2(i).steppingTime(1))))))
                            end                  
                        end
                    end

                    responseTime(i) = (Vdata2(i).steppingTime(1) -Vdata2(1).pertubationsTime(1))/0.12;%turn to miliseconds
                    BamperToEndOfSteps(i) = (Vdata2(i).steppingTime(2) - Vdata2(1).pertubationsTime(1))/0.12;
                    if Vdata2(i).firstStep == 1 %right leg first
                        responseTimeIndexes = Vdata2( i).RightarmsTime(1) >=0;
                        if(responseTimeIndexes) %
                            %[rightArmDistance(i), rightMaxInd] = max(abs(Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1):end) - Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1))));            
                            [rightArmDistance(i), rightMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,67)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),67)).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,69)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),69)).^2+((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,92))-(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),92))).^2)));
                            BamperToRightArmTime(i) =(Vdata2(i).RightarmsTime(1) -Vdata2(1).pertubationsTime(1))/0.12;
                            rightArmSwingTime(i) = rightMaxInd /0.12;
                        end
                        responseTimeIndexes = Vdata2( i).LeftarmsTime(1) >=0;
                        if(responseTimeIndexes) %
                            %[leftArmDistance(i), leftMaxInd] = max(abs(Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1):end) - Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1))));                  
                            [leftArmDistance(i), leftMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,46)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),46)).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,48)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),48)).^2+((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,92))-(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),92))).^2)));
                            BamperToLeftArmTime(i) =(Vdata2(i).LeftarmsTime(1) -Vdata2(1).pertubationsTime(1))/0.12;
                            leftArmSwingTime(i) = leftMaxInd /0.12;
                        end
                        BamperToEndFirstStep(i) = (Vdata2 (i).EndFirstStep-Vdata2(1).pertubationsTime(1))/0.12;
%                         firstStepLengh(i) = abs(Vdata(i).rightStepping(Vdata2( i).EndFirstStep)...
%                              -  Vdata(i).leftStepping(Vdata2 (i).EndFirstStep)); 
                        firstStepLengh(i) = abs(sqrt((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,91)-Vdata(i).SFdATA(Vdata2( i).EndFirstStep ,109))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,92)-Vdata(i).SFdATA(Vdata2( i).EndFirstStep ,110))^2));    
                        if direction(i)==4
                            firstStepLengh2(i) = abs(sqrt((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,109)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,109))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,110)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,110)-Perturbation_dist(i))^2)); 
                        elseif  direction(i)==3
                            firstStepLengh2(i) = abs(sqrt((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,109)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,109))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,110)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,110)+Perturbation_dist(i))^2)); 
                        end
                            
                    else % left leg first
                        responseTimeIndexes = Vdata2( i).RightarmsTime(1) >=0;
                        if(responseTimeIndexes) %
                            %[rightArmDistance(i), rightMaxInd] = max(abs(Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1):end) - Vdata(i).rightArmTotal(Vdata2(i).RightarmsTime(1))));            
                            [rightArmDistance(i), rightMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,67)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),67)).^2+(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,69)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),69)).^2+((Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1):Vdata2(i).RightarmsTime(2)+10,110))-(Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),68)-Vdata(i).SFdATA(Vdata2(i).RightarmsTime(1),110))).^2)));
                            BamperToRightArmTime(i) =(Vdata2(i).RightarmsTime(1) -Vdata2(1).pertubationsTime(1))/0.12;
                            rightArmSwingTime(i) = rightMaxInd /0.12;
                        end
                        responseTimeIndexes = Vdata2( i).LeftarmsTime(1) >=0;
                        if(responseTimeIndexes) %
                            %[leftArmDistance(i), leftMaxInd] = max(abs(Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1):end) - Vdata(i).leftArmTotal(Vdata2(i).LeftarmsTime(1))));                  
                            [leftArmDistance(i), leftMaxInd] = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,46)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),46)).^2+(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,48)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),48)).^2+((Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1):Vdata2(i).LeftarmsTime(2)+10,110))-(Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),47)-Vdata(i).SFdATA(Vdata2(i).LeftarmsTime(1),110))).^2)));
                            BamperToLeftArmTime(i) =(Vdata2(i).LeftarmsTime(1) -Vdata2(1).pertubationsTime(1))/0.12;
                            leftArmSwingTime(i) = leftMaxInd /0.12;
                        end
                        BamperToEndFirstStep(i) = (Vdata2 (i).EndFirstStep-Vdata2(1).pertubationsTime(1))/0.12;     
%                         firstStepLengh(i) = abs(Vdata(i).leftStepping(Vdata2(i).EndFirstStep)...
%                              -  Vdata(i).rightStepping(Vdata2 (i).EndFirstStep));
                        firstStepLengh(i) = abs(sqrt((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,91)-Vdata(i).SFdATA(Vdata2( i).EndFirstStep ,109))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,92)-Vdata(i).SFdATA(Vdata2( i).EndFirstStep ,110))^2));
                        if direction(i)==4
                            firstStepLengh2(i) = abs(sqrt((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,91)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,91))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,92)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,92)-Perturbation_dist(i))^2)); 
                        elseif  direction(i)==3
                            firstStepLengh2(i) = abs(sqrt((Vdata(i).SFdATA(Vdata2( i).EndFirstStep,91)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,91))^2+(Vdata(i).SFdATA(Vdata2( i).EndFirstStep,92)-Vdata(i).SFdATA(Vdata2( i).steppingTime(1) ,92)+Perturbation_dist(i))^2)); 
                        end

                    end
                    if Vdata2(i).lastStep == 1 %right leg end 
                        %lastStepMax(i) = abs(max(Vdata(i).rightStepping) - Vdata(i).rightStepping(Vdata2(i).steppingTime(1)));  
                        lastStepMax(i) = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),109)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),109)).^2+(Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),110)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),110)).^2)));  
                   
                    else
                        %lastStepMax(i) = abs(max(Vdata(i).leftStepping) - Vdata(i).leftStepping(Vdata2(i).steppingTime(1)));
                        lastStepMax(i) = max(abs(sqrt((Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),91)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),91)).^2+(Vdata(i).SFdATA(Vdata2(i).steppingTime(1):Vdata2(i).steppingTime(2),92)-Vdata(i).SFdATA(Vdata2(i).steppingTime(1),92)).^2)));  
                    end           
                    firstStepDuration(i) = BamperToEndFirstStep(i) - responseTime(i);          
            end

        end

    end   
    %print to excel
    path=get(pathFolder,'string');
    path=path{2,1};
    xlswrite([path '\' patientName 'Analyzed.xlsx'],headlineS,'Sheet1','A1');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],index,'Sheet1','A2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],protocol,'Sheet1','B2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],responseTime,'Sheet1','C2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],BamperToEndFirstStep,'Sheet1','D2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],firstStepDuration,'Sheet1','E2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],firstStepLengh,'Sheet1','F2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],BamperToEndOfSteps,'Sheet1','G2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],lastStepMax,'Sheet1','H2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],cgOutBeforeMovemnent,'Sheet1','I2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],loseOfBalanceToFirstStep,'Sheet1','J2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],minCGDistFromLeg,'Sheet1','K2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],CGToNearestAtFirstStep,'Sheet1','L2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],MaxCGOutFromLeg,'Sheet1','M2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],totalDistCGMade,'Sheet1','N2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],rightArmDistance,'Sheet1','O2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],leftArmDistance,'Sheet1','P2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],BamperToRightArmTime,'Sheet1','Q2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],rightArmSwingTime,'Sheet1','R2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],BamperToLeftArmTime,'Sheet1','S2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],leftArmSwingTime,'Sheet1','T2'); 
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],Fall,'Sheet1','U2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],MS,'Sheet1','V2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],TypeArmMove,'Sheet1','W2');
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],TypeLegMove,'Sheet1','X2'); 
    
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],LElbowAng','Sheet1','Y2'); % elbow L
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],LShoulderAng(:,1),'Sheet1','Z2');% shoulder x L 
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],LShoulderAng(:,2),'Sheet1','AA2');% shoulder y L 
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],LShoulderAng(:,3),'Sheet1','AB2'); % shoulder z L
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],RElbowAng','Sheet1','AC2');% elbow R 
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],RShoulderAng(:,1),'Sheet1','AD2'); % shoulder x R
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],RShoulderAng(:,2),'Sheet1','AE2'); % shoulder y R
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],RShoulderAng(:,3),'Sheet1','AF2'); % shoulder z R
    xlswrite([path '\'  patientName 'Analyzed.xlsx'],firstStepLengh2,'Sheet1','AG2'); % step length - another calculation

    msgbox('export finished'); %finish notification
    catch me
        h = errordlg(me.getReport)
     end
end
function checkBoxSteps_call(hObject, eventdata, handles)
    try
    checkBoxStepValue = get(checkBoxStep,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    
    if(checkBoxStepValue == 0)
        if Vdata(pertNumber).steppingTime <0        
                haxesStepLine3.setPosition([30 30], [-5000 5000]);
                haxesStepLine4.setPosition([70 70], [-5000 5000]); 
                haxesStepLine11.setPosition([50 50], [-5000 5000]); 
                set(listBoxStep,'value', 1);
        else
                haxesArmsLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-5000 5000]);
                haxesArmsLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-5000 5000]);     
                haxesArmsLine11.setPosition([Vdata2(pertNumber).EndFirstStep,Vdata2(pertNumber).EndFirstStep], [-5000 5000]);     
                if Vdata(pertNumber).firstStep==1
                    set(listBoxStep,'value', 1);
                else
                    set(listBoxStep,'value', 2);
                end
    
        end
    else
            haxesStepLine3.setPosition([-5000 -5000], [-5000 -5000]);
            haxesStepLine4.setPosition([-5000 -5000], [-5000 -5000]); 
            haxesStepLine11.setPosition([-5000 -5000], [-5000 -5000]); 
            set(listBoxStep,'value', 3);
    end
    catch me
        h = errordlg(me.getReport)
    end
end
function listBoxSteps_call(hObject, eventdata, handles)
    try
    listBoxStepValue = get(listBoxStep,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    
    if(listBoxStepValue == 1) % right
        if Vdata(pertNumber).firstStep==0 || Vdata2(pertNumber).steppingTime(1)<0
            Vdata(pertNumber).firstStep=1;
            Vdata2(pertNumber).firstStep=1;
            Vdata3(pertNumber).firstStep=1;
            set(checkBoxStep, 'value', 0);
            haxesArmsLine3.setPosition([100 100], [-5000 5000]);
            haxesArmsLine4.setPosition([300 300], [-5000 5000]);     
            haxesArmsLine11.setPosition([200 200], [-5000 5000]); 
        else
            Vdata(pertNumber).firstStep=1;
            Vdata2(pertNumber).firstStep=1;
            Vdata3(pertNumber).firstStep=1;
            set(checkBoxStep, 'value', 0);
            haxesArmsLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-5000 5000]);
            haxesArmsLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-5000 5000]);     
            haxesArmsLine11.setPosition([Vdata2(pertNumber).EndFirstStep,Vdata2(pertNumber).EndFirstStep], [-5000 5000]);     
        end  
    end
    if(listBoxStepValue == 2)  % left
        if Vdata(pertNumber).firstStep==0 || Vdata2(pertNumber).steppingTime(1)<0
            Vdata(pertNumber).firstStep=2;
            Vdata2(pertNumber).firstStep=2;
            Vdata3(pertNumber).firstStep=2;
            set(checkBoxStep, 'value', 0);
            haxesArmsLine3.setPosition([100 100], [-5000 5000]);
            haxesArmsLine4.setPosition([300 300], [-5000 5000]);     
            haxesArmsLine11.setPosition([200 200], [-5000 5000]); 
        else
            Vdata(pertNumber).firstStep=2;
            Vdata2(pertNumber).firstStep=2;
            Vdata3(pertNumber).firstStep=2;
            set(checkBoxStep, 'value', 0);
            haxesArmsLine3.setPosition([Vdata2(pertNumber).steppingTime(1) Vdata2(pertNumber).steppingTime(1)], [-5000 5000]);
            haxesArmsLine4.setPosition([Vdata2(pertNumber).steppingTime(2) Vdata2(pertNumber).steppingTime(2)], [-5000 5000]);     
            haxesArmsLine11.setPosition([Vdata2(pertNumber).EndFirstStep,Vdata2(pertNumber).EndFirstStep], [-5000 5000]);     
        end
    end
     if(listBoxStepValue == 3) % no step
        Vdata(pertNumber).firstStep=0;
        Vdata2(pertNumber).firstStep=0;
        Vdata3(pertNumber).firstStep=0;
        set(checkBoxStep, 'value', 1);
        haxesStepLine3.setPosition([-5000 -5000], [-5000 -5000]);
        haxesStepLine4.setPosition([-5000 -5000], [-5000 -5000]); 
        haxesStepLine11.setPosition([-5000 -5000], [-5000 -5000]); 
     end
    
    catch me
        h = errordlg(me.getReport)
    end
end 
function checkBoxRightArms_call(hObject, eventdata, handles)
    try
    checkBoxArmsValue = get(checkBoxRightArms,'value')
   pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    
    if(checkBoxArmsValue == 0)
        if Vdata(pertNumber).RightarmsTime <0        
                haxesStepLine5.setPosition([50 50], [-5000 5000]);
                haxesStepLine6.setPosition([100 100], [-5000 5000]); 
        else
                haxesArmsLine5.setPosition([Vdata(pertNumber).RightarmsTime(1) Vdata(pertNumber).RightarmsTime(1)], [-5000 5000]);
                haxesArmsLine6.setPosition([Vdata(pertNumber).RightarmsTime(2) Vdata(pertNumber).RightarmsTime(2)], [-5000 5000]);
    
        end
    else
            haxesStepLine5.setPosition([-30 -30], [-30 -30]);
            haxesStepLine6.setPosition([-30 -30], [-30 -30]);  
    end
    catch me
        h = errordlg(me.getReport)
    end
    
end
function checkBoxLeftArms_call(hObject, eventdata, handles)
    try
    checkBoxArmsValue = get(checkBoxLeftArms,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    
    if(checkBoxArmsValue == 0)
        if Vdata(pertNumber).LeftarmsTime <0        
                 haxesStepLine9.setPosition([50 50], [-5000 5000]);
                haxesStepLine10.setPosition([100 100], [-5000 5000]);
        else
                haxesArmsLine9.setPosition([Vdata(pertNumber).LeftarmsTime(1) Vdata(pertNumber).LeftarmsTime(1)], [-5000 5000]);
                haxesArmsLine10.setPosition([Vdata(pertNumber).LeftarmsTime(2) Vdata(pertNumber).LeftarmsTime(2)], [-5000 5000]);
    
        end
    else
            haxesStepLine9.setPosition([-30 -30], [-30 -30]);
            haxesStepLine10.setPosition([-30 -30], [-30 -30]);  
    end
    catch me
        h = errordlg(me.getReport)
    end
end
function typeArm_call(hObject, eventdata, handles)
    try
    TypeArm=get(typeOfArmMove,'string');
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    Vdata2(pertNumber).TypeArmMove=TypeArm;
    Vdata(pertNumber).TypeArmMove=TypeArm;
   catch me
        h = errordlg(me.getReport)
    end
end
function typeLeg_call(hObject, eventdata, handles)
    try
    TypeLeg=get(typeOfLegMove,'string');
   pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    Vdata2(pertNumber).TypeLegMove=TypeLeg;
    Vdata(pertNumber).TypeLegMove=TypeLeg;
    catch me
        h = errordlg(me.getReport)
    end
end
function checkBoxFall_call(hObject, eventdata, handles)
    try
    Fall=get(checkBoxFall,'value');
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    Vdata2(pertNumber).Fall=Fall;
    Vdata(pertNumber).Fall=Fall;
    catch me
        h = errordlg(me.getReport)
    end
end
function checkBoxMS_call(hObject, eventdata, handles)
    try
    MS=get(checkBoxMS,'value');
   pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    Vdata2(pertNumber).MS=MS;
    Vdata(pertNumber).MS=MS;
    catch me
        h = errordlg(me.getReport)
    end
end
function checkBoxHideRightArms_call(hObject, eventdata, handles)
    try
    checkBoxHideRightArmsValue = get(checkBoxHideRightArms,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    x = haxesStepLine5.getPosition()
    y = haxesStepLine6.getPosition()
    if(checkBoxHideRightArmsValue == 1)
%         haxesStepLine5.Visible='off';
%         haxesStepLine6.Visible='off';
        Vdata3(pertNumber).RightarmsTime(1) = x(1,1);
        Vdata3(pertNumber).RightarmsTime(2) = y(1,1);
        haxesStepLine5.setPosition([-5000 -5000], [-5000 5000]);
        haxesStepLine6.setPosition([-5000 -5000], [-5000 5000]);     
    else
        haxesArmsLine5.setPosition([Vdata3(pertNumber).RightarmsTime(1) Vdata3(pertNumber).RightarmsTime(1)], [-5000 5000]);
        haxesArmsLine6.setPosition([Vdata3(pertNumber).RightarmsTime(2) Vdata3(pertNumber).RightarmsTime(2)], [-5000 5000]);         
    end  
    catch me
        h = errordlg(me.getReport)
    end
end
function checkBoxHideLeftArms_call(hObject, eventdata, handles)
    try
    checkBoxHideLeftArmsValue = get(checkBoxHideLeftArms,'value')
   pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    x = haxesStepLine9.getPosition()
    y = haxesStepLine10.getPosition()
    if(checkBoxHideLeftArmsValue == 1)
        Vdata3(pertNumber).LeftarmsTime(1) = x(1,1);
        Vdata3(pertNumber).LeftarmsTime(2) = y(1,1);
        haxesStepLine9.setPosition([-5000 -5000], [-5000 5000]);
        haxesStepLine10.setPosition([-5000 -5000], [-5000 5000]);     
    else
        haxesArmsLine9.setPosition([Vdata3(pertNumber).LeftarmsTime(1) Vdata3(pertNumber).LeftarmsTime(1)], [-5000 5000]);
        haxesArmsLine10.setPosition([Vdata3(pertNumber).LeftarmsTime(2) Vdata3(pertNumber).LeftarmsTime(2)], [-5000 5000]);         
    end 
    catch me
        h = errordlg(me.getReport)
    end
    
end
function checkBoxHideSteps_call(hObject, eventdata, handles)
    try
    checkBoxHideStepsValue = get(checkBoxHideSteps,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    x = haxesStepLine3.getPosition()
    y = haxesStepLine4.getPosition()
    z = haxesStepLine11.getPosition()

    if(checkBoxHideStepsValue == 1)
        Vdata3(pertNumber).steppingTime(1) = x(1,1);
        Vdata3(pertNumber).steppingTime(2) = y(1,1);
        Vdata3(pertNumber).EndFirstStep = z(1,1);
        haxesStepLine3.setPosition([-5000 -5000], [-5000 5000]);
        haxesStepLine4.setPosition([-5000 -5000], [-5000 5000]); 
        haxesStepLine11.setPosition([-5000 -5000], [-5000 5000]); 
    else
        haxesArmsLine3.setPosition([Vdata3(pertNumber).steppingTime(1) Vdata3(pertNumber).steppingTime(1)], [-5000 5000]);
        haxesArmsLine4.setPosition([Vdata3(pertNumber).steppingTime(2) Vdata3(pertNumber).steppingTime(2)], [-5000 5000]);         
        haxesArmsLine11.setPosition([Vdata3(pertNumber).EndFirstStep Vdata3(pertNumber).EndFirstStep], [-5000 5000]);         

    end 
    catch me
        h = errordlg(me.getReport)
    end
end
function checkBoxHideCG_call(hObject, eventdata, handles)
    try
    checkBoxHideCGValue = get(checkBoxHideCG,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    x = haxesStepLine7.getPosition()
    y = haxesStepLine8.getPosition()
    if(checkBoxHideCGValue == 1)
        Vdata3(pertNumber).cgOut(1) = x(1,1);
        Vdata3(pertNumber).cgOut(2) = y(1,1);
        haxesStepLine7.setPosition([-5000 -5000], [-5000 5000]);
        haxesStepLine8.setPosition([-5000 -5000], [-5000 5000]);     
    else
        haxesArmsLine7.setPosition([Vdata3(pertNumber).cgOut(1) Vdata3(pertNumber).cgOut(1)], [-5000 5000]);
        haxesArmsLine8.setPosition([Vdata3(pertNumber).cgOut(2) Vdata3(pertNumber).cgOut(2)], [-5000 5000]);         
    end 
   catch me
        h = errordlg(me.getReport)
    end
end
function checkBoxHideBamper_call(hObject, eventdata, handles)
    try
    checkBoxHideBamperValue = get(checkBoxHideBamper,'value')
    pertNumber =get(ListBoxPertubation,'value')
     step = get(currentFile,'string') ;
     patientName =step{2,1}(1:end-4);
%     indexOfPatient = find(strcmp(extractfield(Vdata(:,1,1), 'name'), patientName)) ;
%     indexOfStep = find(strcmp(extractfield(Vdata(indexOfPatient,:,pertNumber), 'step'), step));
    x = haxesStepLine1.getPosition()
    y = haxesStepLine2.getPosition()
    if(checkBoxHideBamperValue == 1)
        Vdata3(pertNumber).pertubationsTime(1) = x(1,1);
        Vdata3(pertNumber).pertubationsTime(2) = y(1,1);
        haxesStepLine1.setPosition([-5000 -5000], [-5000 5000]);
        haxesStepLine2.setPosition([-5000 -5000], [-5000 5000]);     
    else
        haxesArmsLine1.setPosition([Vdata3(pertNumber).pertubationsTime(1) Vdata3(pertNumber).pertubationsTime(1)], [-5000 5000]);
        haxesArmsLine2.setPosition([Vdata3(pertNumber).pertubationsTime(2) Vdata3(pertNumber).pertubationsTime(2)], [-5000 5000]);         
    end  
    catch me
        h = errordlg(me.getReport)
    end
end
function callback_line1(pos)
    try
   haxesCGLine1.setPosition(pos);
   haxesBamperLine1.setPosition(pos);
   haxesStepLine1.setPosition(pos);
   haxesArmsLine1.setPosition(pos);
    catch me
        h = errordlg(me.getReport)
    end
   
end
function callback_line2(pos)
    try
   haxesCGLine2.setPosition(pos);
   haxesBamperLine2.setPosition(pos);
   haxesStepLine2.setPosition(pos);
   haxesArmsLine2.setPosition(pos);
    catch me
        h = errordlg(me.getReport)
    end
end
function callback_line3(pos)
    try
   haxesCGLine3.setPosition(pos);
   haxesBamperLine3.setPosition(pos);
   haxesStepLine3.setPosition(pos);
   haxesArmsLine3.setPosition(pos);
    catch me
        h = errordlg(me.getReport)
    end
end
function callback_line4(pos)
    try
   haxesCGLine4.setPosition(pos);
   haxesBamperLine4.setPosition(pos);
   haxesStepLine4.setPosition(pos);
   haxesArmsLine4.setPosition(pos);
    catch me
        h = errordlg(me.getReport)
    end
    
end
function callback_line5(pos)
    try
   haxesCGLine5.setPosition(pos);
   haxesBamperLine5.setPosition(pos);
   haxesStepLine5.setPosition(pos);
   haxesArmsLine5.setPosition(pos);
    catch me
        h = errordlg(me.getReport)
    end
end
function callback_line6(pos)
    try
   haxesCGLine6.setPosition(pos);
   haxesBamperLine6.setPosition(pos);
   haxesStepLine6.setPosition(pos);
   haxesArmsLine6.setPosition(pos);
    catch me
        h = errordlg(me.getReport)
    end
end
function callback_line7(pos)
    try
   haxesCGLine7.setPosition(pos);
   haxesBamperLine7.setPosition(pos);
   haxesStepLine7.setPosition(pos);
   haxesArmsLine7.setPosition(pos);
   catch me
        h = errordlg(me.getReport)
    end
end
function callback_line8(pos)
    try
   haxesCGLine8.setPosition(pos);
   haxesBamperLine8.setPosition(pos);
   haxesStepLine8.setPosition(pos);
   haxesArmsLine8.setPosition(pos);
   catch me
        h = errordlg(me.getReport)
    end
end
function callback_line9(pos)
    try
   haxesCGLine9.setPosition(pos);
   haxesBamperLine9.setPosition(pos);
   haxesStepLine9.setPosition(pos);
   haxesArmsLine9.setPosition(pos);
   catch me
        h = errordlg(me.getReport)
    end
end
function callback_line10(pos)
    try
   haxesCGLine10.setPosition(pos);
   haxesBamperLine10.setPosition(pos);
   haxesStepLine10.setPosition(pos);
   haxesArmsLine10.setPosition(pos);
   catch me
        h = errordlg(me.getReport)
    end
end
function callback_line11(pos)
    try
   haxesCGLine11.setPosition(pos);
   haxesBamperLine11.setPosition(pos);
   haxesStepLine11.setPosition(pos);
   haxesArmsLine11.setPosition(pos);
   catch me
        h = errordlg(me.getReport)
    end
end
function callback_SFline(pos)
    try
        pertNumber =get(ListBoxPertubation,'value')
    axes(haxesSF);
    cla(haxesSF);
    %[x, y] = find(isPlotted == 1);
%     for ind = 1:3:length(Vdata(pertNumber).SFdATA(1,:))
%         hold on
%         scatter3(haxesSF,Vdata(pertNumber).SFdATA(floor(pos(1) +1) ,ind),Vdata(pertNumber).SFdATA(floor(pos(1) +1),ind +1),Vdata.SFdATA(floor(pos(1) +1),ind +2), 'o')
%         hold on
%     end
   stepbound = get(haxesStep,'ylim');
   armsbound = get(haxesArms,'ylim');
   bamperbound = get(haxesBamper,'ylim');
   %haxesSFLine1.setPosition(pos);
   haxesSFLine2.setPosition([pos(1,1), stepbound(1); pos(1,1),stepbound(2)]);
   haxesSFLine3.setPosition([pos(1,1), bamperbound(1); pos(1,1),bamperbound(2)]);
   haxesSFLine4.setPosition([pos(1,1), armsbound(1); pos(1,1),armsbound(2)]);
    catch me
        h = errordlg(me.getReport)
    end
end
function releaseCallback(src,ev)
    try
        pertNumber =get(ListBoxPertubation,'value')
  %  f =  get(b,'CurrentPoint');
  % set(a, 'YData', f(:,2))
   if ispressed == 1
   
    cord =  get(gca,'CurrentPoint');
    %[x, y] = find(isPlotted == 1);
     axes(haxesSF);
    cla(haxesSF);
%     for ind = 1:3:length(Vdata(x, y).SFdATA(1,:))
%         hold on
%         scatter3(haxesSF,Vdata(x, y).SFdATA(floor(cord(1,1) +1) ,ind),Vdata(x, y).SFdATA(floor(cord(1,1) +1),ind +1),Vdata(x, y).SFdATA(floor(cord(1,1) +1),ind +2), 'o')
%         hold on
%     end
 %  stepbound = get(haxesStep,'ylim');
 %  armsbound = get(haxesArms,'ylim');
 %  bamperbound = get(haxesBamper,'ylim');
 %  cgbound = get(haxesCG,'ylim');
   
   set(haxesSFLine1, 'XData', cord(:,1))
   set(haxesSFLine2, 'XData', cord(:,1))
   set(haxesSFLine3, 'XData', cord(:,1))
   set(haxesSFLine4, 'XData', cord(:,1))
   set(slider, 'value', cord(1,1))
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,1) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,4)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,2) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,5)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,3) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,6)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,1) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,7)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,2) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,8)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,3) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,9)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,10) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,4)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,11) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,5)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,12) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,6)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,10) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,7)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,11) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,8)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,12) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,9)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,19) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,28)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,20) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,29)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,21) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,30)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,19) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,49)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,20) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,50)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,21) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,51)]...
        ,'Color', 'k','LineWidth',1.5);     
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,28) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,34)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,29) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,35)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,30) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,36)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,40) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,34)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,41) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,35)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,42) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,36)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,43) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,34)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,44) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,35)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,45) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,36)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,40) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,46)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,41) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,47)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,42) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,48)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,43) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,46)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,44) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,47)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,45) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,48)]...
        ,'Color', 'k','LineWidth',1.5);
 
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,49) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,55)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,50) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,56)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,51) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,57)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,61) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,55)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,62) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,56)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,63) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,57)]...
        ,'Color', 'k','LineWidth',1.5); 
   
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,64) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,55)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,65) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,56)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,66) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,57)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,61) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,67)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,62) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,68)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,63) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,69)]...
        ,'Color', 'k','LineWidth',1.5); 
   
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,64) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,67)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,65) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,68)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,66) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,69)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,70) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,73)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,71) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,74)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,72) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,75)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,70) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,76)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,71) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,77)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,72) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,78)]...
        ,'Color', 'k','LineWidth',1.5); 
  
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,79) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,73)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,80) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,74)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,81) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,75)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,79) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,76)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,80) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,77)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,81) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,78)]...
        ,'Color', 'k','LineWidth',1.5);   
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,70) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,85)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,71) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,86)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,72) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,87)]...
        ,'Color', 'k','LineWidth',1.5); 
   
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,91) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,85)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,92) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,86)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,93) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,87)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,91) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,94)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,92) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,95)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,93) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,96)]...
        ,'Color', 'k','LineWidth',1.5);  

    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,91) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,97)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,92) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,98)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,93) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,99)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,94) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,97)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,95) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,98)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,96) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,99)]...
        ,'Color', 'k','LineWidth',1.5);   
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,73) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,103)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,74) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,104)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,75) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,105)]...
        ,'Color', 'k','LineWidth',1.5);
   
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,109) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,103)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,110) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,104)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,111) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,105)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,109) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,112)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,110) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,113)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,111) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,114)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,109) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,115)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,110) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,116)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,111) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,117)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,112) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,115)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,113) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,116)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,114) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,117)]...
        ,'Color', 'k','LineWidth',1.5);     
    
    line([Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,118) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,121)]...
        , [Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,119) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,122)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,120) Vdata(pertNumber).SFdATA(floor(cord(1,1) +1) ,123)]...
        ,'Color', 'k','LineWidth',1.5); 
    if length(Vdata)==12 % walking protocol
        plot3(Vdata(pertNumber).CGX_plot(floor(cord +1)),Vdata(pertNumber).CGZ(floor(cord +1)),Vdata(pertNumber).CGY(floor(cord +1)),'o','MarkerSize',5,'MarkerFaceColor','r')
    else % standing protocol
        plot3(Vdata(pertNumber).CGX_plot(floor(cord +1)),Vdata(pertNumber).CGZ_plot(floor(cord +1)),Vdata(pertNumber).CGY_plot(floor(cord +1)),'o','MarkerSize',5,'MarkerFaceColor','r')
    end


     xlim([-700, 1500])
     ylim([-200, 2000])
     zlim([-200, 1800])
   %haxesSFLine1.setPosition(pos);
   %haxesSFLine2.setPosition([pos(1,1), stepbound(1); pos(1,1),stepbound(2)]);
   %haxesSFLine3.setPosition([pos(1,1), bamperbound(1); pos(1,1),bamperbound(2)]);
   %haxesSFLine4.setPosition([pos(1,1), armsbound(1); pos(1,1),armsbound(2)]);
   end
   ispressed =0;
    catch me
        h = errordlg(me.getReport)
    end
end
function SFLine1Callback(src,ev)
    try
  %  f =  get(b,'CurrentPoint');
  % set(a, 'YData', f(:,2))
   ispressed = 1;
    catch me
        h = errordlg(me.getReport)
    end
end
function slider_call(h,event) 
    try
     pertNumber =get(ListBoxPertubation,'value')
     cord =  get(slider, 'value')
    %[x, y] = find(isPlotted == 1);
     axes(haxesSF);
     cla(haxesSF);
%     for ind = 1:3:length(Vdata(pertNumber).SFdATA(1,:))
%         hold on
%         scatter3(haxesSF,Vdata(pertNumber).SFdATA(floor(cord +1) ,ind),Vdata(pertNumber).SFdATA(floor(cord +1),ind +1),Vdata(pertNumber).SFdATA(floor(cord +1),ind +2), 'o')
%         hold on
%     end
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,1) Vdata(pertNumber).SFdATA(floor(cord +1) ,4)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,2) Vdata(pertNumber).SFdATA(floor(cord +1) ,5)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,3) Vdata(pertNumber).SFdATA(floor(cord +1) ,6)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,1) Vdata(pertNumber).SFdATA(floor(cord +1) ,7)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,2) Vdata(pertNumber).SFdATA(floor(cord +1) ,8)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,3) Vdata(pertNumber).SFdATA(floor(cord +1) ,9)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,10) Vdata(pertNumber).SFdATA(floor(cord +1) ,4)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,11) Vdata(pertNumber).SFdATA(floor(cord +1) ,5)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,12) Vdata(pertNumber).SFdATA(floor(cord +1) ,6)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,10) Vdata(pertNumber).SFdATA(floor(cord +1) ,7)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,11) Vdata(pertNumber).SFdATA(floor(cord +1) ,8)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,12) Vdata(pertNumber).SFdATA(floor(cord +1) ,9)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,19) Vdata(pertNumber).SFdATA(floor(cord +1) ,28)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,20) Vdata(pertNumber).SFdATA(floor(cord +1) ,29)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,21) Vdata(pertNumber).SFdATA(floor(cord +1) ,30)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,19) Vdata(pertNumber).SFdATA(floor(cord +1) ,49)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,20) Vdata(pertNumber).SFdATA(floor(cord +1) ,50)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,21) Vdata(pertNumber).SFdATA(floor(cord +1) ,51)]...
        ,'Color', 'k','LineWidth',1.5);     
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,28) Vdata(pertNumber).SFdATA(floor(cord +1) ,34)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,29) Vdata(pertNumber).SFdATA(floor(cord +1) ,35)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,30) Vdata(pertNumber).SFdATA(floor(cord +1) ,36)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,40) Vdata(pertNumber).SFdATA(floor(cord +1) ,34)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,41) Vdata(pertNumber).SFdATA(floor(cord +1) ,35)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,42) Vdata(pertNumber).SFdATA(floor(cord +1) ,36)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,43) Vdata(pertNumber).SFdATA(floor(cord +1) ,34)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,44) Vdata(pertNumber).SFdATA(floor(cord +1) ,35)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,45) Vdata(pertNumber).SFdATA(floor(cord +1) ,36)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,40) Vdata(pertNumber).SFdATA(floor(cord +1) ,46)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,41) Vdata(pertNumber).SFdATA(floor(cord +1) ,47)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,42) Vdata(pertNumber).SFdATA(floor(cord +1) ,48)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,43) Vdata(pertNumber).SFdATA(floor(cord +1) ,46)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,44) Vdata(pertNumber).SFdATA(floor(cord +1) ,47)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,45) Vdata(pertNumber).SFdATA(floor(cord +1) ,48)]...
        ,'Color', 'k','LineWidth',1.5);
 
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,49) Vdata(pertNumber).SFdATA(floor(cord +1) ,55)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,50) Vdata(pertNumber).SFdATA(floor(cord +1) ,56)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,51) Vdata(pertNumber).SFdATA(floor(cord +1) ,57)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,61) Vdata(pertNumber).SFdATA(floor(cord +1) ,55)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,62) Vdata(pertNumber).SFdATA(floor(cord +1) ,56)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,63) Vdata(pertNumber).SFdATA(floor(cord +1) ,57)]...
        ,'Color', 'k','LineWidth',1.5); 
   
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,64) Vdata(pertNumber).SFdATA(floor(cord +1) ,55)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,65) Vdata(pertNumber).SFdATA(floor(cord +1) ,56)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,66) Vdata(pertNumber).SFdATA(floor(cord +1) ,57)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,61) Vdata(pertNumber).SFdATA(floor(cord +1) ,67)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,62) Vdata(pertNumber).SFdATA(floor(cord +1) ,68)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,63) Vdata(pertNumber).SFdATA(floor(cord +1) ,69)]...
        ,'Color', 'k','LineWidth',1.5); 
   
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,64) Vdata(pertNumber).SFdATA(floor(cord +1) ,67)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,65) Vdata(pertNumber).SFdATA(floor(cord +1) ,68)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,66) Vdata(pertNumber).SFdATA(floor(cord +1) ,69)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,70) Vdata(pertNumber).SFdATA(floor(cord +1) ,73)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,71) Vdata(pertNumber).SFdATA(floor(cord +1) ,74)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,72) Vdata(pertNumber).SFdATA(floor(cord +1) ,75)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,70) Vdata(pertNumber).SFdATA(floor(cord +1) ,76)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,71) Vdata(pertNumber).SFdATA(floor(cord +1) ,77)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,72) Vdata(pertNumber).SFdATA(floor(cord +1) ,78)]...
        ,'Color', 'k','LineWidth',1.5); 
  
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,79) Vdata(pertNumber).SFdATA(floor(cord +1) ,73)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,80) Vdata(pertNumber).SFdATA(floor(cord +1) ,74)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,81) Vdata(pertNumber).SFdATA(floor(cord +1) ,75)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,79) Vdata(pertNumber).SFdATA(floor(cord +1) ,76)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,80) Vdata(pertNumber).SFdATA(floor(cord +1) ,77)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,81) Vdata(pertNumber).SFdATA(floor(cord +1) ,78)]...
        ,'Color', 'k','LineWidth',1.5);   
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,70) Vdata(pertNumber).SFdATA(floor(cord +1) ,85)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,71) Vdata(pertNumber).SFdATA(floor(cord +1) ,86)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,72) Vdata(pertNumber).SFdATA(floor(cord +1) ,87)]...
        ,'Color', 'k','LineWidth',1.5); 
   
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,91) Vdata(pertNumber).SFdATA(floor(cord +1) ,85)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,92) Vdata(pertNumber).SFdATA(floor(cord +1) ,86)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,93) Vdata(pertNumber).SFdATA(floor(cord +1) ,87)]...
        ,'Color', 'k','LineWidth',1.5);
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,91) Vdata(pertNumber).SFdATA(floor(cord +1) ,94)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,92) Vdata(pertNumber).SFdATA(floor(cord +1) ,95)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,93) Vdata(pertNumber).SFdATA(floor(cord +1) ,96)]...
        ,'Color', 'k','LineWidth',1.5);  

    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,91) Vdata(pertNumber).SFdATA(floor(cord +1) ,97)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,92) Vdata(pertNumber).SFdATA(floor(cord +1) ,98)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,93) Vdata(pertNumber).SFdATA(floor(cord +1) ,99)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,94) Vdata(pertNumber).SFdATA(floor(cord +1) ,97)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,95) Vdata(pertNumber).SFdATA(floor(cord +1) ,98)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,96) Vdata(pertNumber).SFdATA(floor(cord +1) ,99)]...
        ,'Color', 'k','LineWidth',1.5);   
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,73) Vdata(pertNumber).SFdATA(floor(cord +1) ,103)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,74) Vdata(pertNumber).SFdATA(floor(cord +1) ,104)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,75) Vdata(pertNumber).SFdATA(floor(cord +1) ,105)]...
        ,'Color', 'k','LineWidth',1.5);
   
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,109) Vdata(pertNumber).SFdATA(floor(cord +1) ,103)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,110) Vdata(pertNumber).SFdATA(floor(cord +1) ,104)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,111) Vdata(pertNumber).SFdATA(floor(cord +1) ,105)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,109) Vdata(pertNumber).SFdATA(floor(cord +1) ,112)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,110) Vdata(pertNumber).SFdATA(floor(cord +1) ,113)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,111) Vdata(pertNumber).SFdATA(floor(cord +1) ,114)]...
        ,'Color', 'k','LineWidth',1.5);  
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,109) Vdata(pertNumber).SFdATA(floor(cord +1) ,115)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,110) Vdata(pertNumber).SFdATA(floor(cord +1) ,116)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,111) Vdata(pertNumber).SFdATA(floor(cord +1) ,117)]...
        ,'Color', 'k','LineWidth',1.5); 
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,112) Vdata(pertNumber).SFdATA(floor(cord +1) ,115)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,113) Vdata(pertNumber).SFdATA(floor(cord +1) ,116)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,114) Vdata(pertNumber).SFdATA(floor(cord +1) ,117)]...
        ,'Color', 'k','LineWidth',1.5);     
    
    line([Vdata(pertNumber).SFdATA(floor(cord +1) ,118) Vdata(pertNumber).SFdATA(floor(cord +1) ,121)]...
        , [Vdata(pertNumber).SFdATA(floor(cord +1) ,119) Vdata(pertNumber).SFdATA(floor(cord +1) ,122)]...
        ,[Vdata(pertNumber).SFdATA(floor(cord +1) ,120) Vdata(pertNumber).SFdATA(floor(cord +1) ,123)]...
        ,'Color', 'k','LineWidth',1.5); 
    hold on
    if length(Vdata)==12 % walking protocol
        plot3(Vdata(pertNumber).CGX_plot(floor(cord +1)),Vdata(pertNumber).CGZ(floor(cord +1)),Vdata(pertNumber).CGY(floor(cord +1)),'o','MarkerSize',5,'MarkerFaceColor','r')
    else % standing protocol
        plot3(Vdata(pertNumber).CGX_plot(floor(cord +1)),Vdata(pertNumber).CGZ_plot(floor(cord +1)),Vdata(pertNumber).CGY_plot(floor(cord +1)),'o','MarkerSize',5,'MarkerFaceColor','r')
    end    
     xlim([-700, 1500])
     ylim([-200, 2000])
     zlim([-200, 1800])
 %  stepbound = get(haxesStep,'ylim');
 %  armsbound = get(haxesArms,'ylim');
 %  bamperbound = get(haxesBamper,'ylim');
 %  cgbound = get(haxesCG,'ylim');
   
   set(haxesSFLine1, 'XData', [cord cord],'YData',[-50000 50000])
   set(haxesSFLine2, 'XData', [cord cord],'YData',[-50000 50000])
   set(haxesSFLine3, 'XData', [cord cord],'YData',[-50000 50000])
   set(haxesSFLine4, 'XData', [cord cord],'YData',[-50000 50000])
    catch me
        h = errordlg(me.getReport)
    end
end
end
