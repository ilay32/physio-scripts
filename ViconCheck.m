function ViconCheck
tarfile = '';
close all;
tip = [-5000,5000];

%% setup gui
h = figure('Units', 'normalized', 'Color', [.925 .914 .847], 'Position', [0 0 1 0.91]);
set(h,'NextPlot', 'add', 'NumberTitle', 'off', 'Toolbar', 'figure')
Choose = uicontrol('String', 'Select File to Process', 'Units', 'normalized','FontSize',12,'FontWeight','Bold',...
    'Position', [.01 .95 .1 .04] , 'callback', @setTarget,...
    'TooltipString', 'choose file for processing');   %#ok<NASGU>
%TargetDir = uicontrol('String', 'CSV Path', 'Units', 'normalized', 'Style', 'Text',...
%    'Position', [.01 .91 .1 .03], 'BackgroundColor',  [1 1 1]);
%TargetFile = uicontrol('String', 'CSV File', 'Units', 'normalized', 'Style', 'Text',...
%    'Position', [.01 .87 .1 .03], 'BackgroundColor',  [1 1 1]);
%PertubationNumber = uicontrol('String', 'Pertubation Number', 'Units', 'normalized', 'Style', 'Text',...
%    'Position', [.01 .82 .11 .03], 'BackgroundColor',  [1 1 1],'FontWeight','Bold','FontSize',12);
ListBoxPertubation = uicontrol('style','listbox','units','normalized','FontSize',12,'FontWeight','Bold',...
        'Position',[.01 .15 .05 .64],'string',{},'callback', @listBoxPertu_call);

uiwait(h)

%% load the data
vcd = ViconData(tarfile).LoadData();

warnings = vcd.ValidateData(30); % will warn if any data is more than 30% NaN
goon = true;
if ~isempty(warnings)
    w = warndlg(strjoin(warnings(:),'\n'),'modal');
    set(w,'Resize','on');
    abrt = uicontrol(w,'String', 'Abort','callback',@abort,...
    'tooltipString', ' this will close everything and exit after you click OK '); %#ok<NASGU>
    uiwait(w);
end

function abort(~,~,~)
    goon = false;
end

if ~goon
    close all;
    return;
end

if ~isdir(vcd.savefolder)
    mkdir(vcd.savefolder);
    vcd.savedata();
end

Vdata = vcd.fixed;
Vdata2 = vcd.mutables;
set(ListBoxPertubation,'String',{Vdata.StringPer}')

Vdata3 = Vdata2; % for hidden data
plotHandles = struct;
for v={...
        'Bamper',...
        'LeftCG',...
        'RightCG',...
        'LeftHCG',...
        'RightHCG',...
        'LeftTCG',...
        'RightTCG',...
        'CG',...
        'LeftStep',...
        'RightStep',...
        'LeftStepA',...
        'RightStepA',...
        'LeftArm',...
        'RightArm',...
        'Bamper2',...
        'CG2',...
        'LeftStep2',...
        'RightStep2',...
        'LeftArm2',...
        'RightArm2',...
    }
    plotHandles.handles.(v{:}) = zeros(size(Vdata));
    plotHandles.isplotted = struct;
    plotHandles.isplotted.fixed = zeros(size(Vdata));
    plotHandles.isplotted.mutables = zeros(size(Vdata));
end
     
drawButton = uicontrol('String', 'Load', 'Units', 'normalized','FontSize',12,...
    'position', [.020 .06 .062 .058] , 'callback', @drawButtonselected_cb,...
    'tooltipString', ' Plot selection '); %#ok<NASGU>

saveButton = uicontrol('String', 'Save', 'Units', 'normalized','FontSize',12,...
    'position', [.100 .06 .062 .058] , 'callback', @saveButtonselected_cb,...
    'tooltipString', ' average ');%#ok<NASGU>

exportButton = uicontrol('String', 'Export', 'Units', 'normalized','FontSize',12,...
    'position', [.180 .06 .062 .058] , 'callback', @exportButtonselected_cb,...
    'tooltipString', ' export '); %#ok<NASGU>

patientInfoLabel = uicontrol('String', 'Patient information', 'Units', 'normalized','FontSize',12, 'Style', 'Text',...
    'fontweight', 'bold','Position', [.845 .93 .13 .05], 'BackgroundColor',  [.925 .914 .847]); %#ok<NASGU>    

patientNameLabel =  uicontrol('String', '', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
    'position', [.84 .91 .150 .03], 'BackgroundColor',  [1 1 1]);

checkBoxSteps = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.17 .15 .05 .03],'string','no step','callback', @checkBoxSteps_call);

listBoxStep = uicontrol('style','listbox','units','normalized','FontSize',11,...
    'position',[.395 .13 .05 .05],'string',{'Right';'Left';'No Step'},'callback', @listBoxSteps_call);

PatientFirstLeg =  uicontrol('String', 'Side Of First Step:', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
    'position', [.340 .13 .05 .05]);%#ok<NASGU>

EndFirstStep = uicontrol('String', 'end of all step', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
    'fontweight', 'bold','Position', [.46 .1 .09 .03],'Foregroundcolor','c');%#ok<NASGU>  

checkBoxRightArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[0.47,0.15,0.12,0.03],'string','no Right arms movement',...
    'callback', @checkBoxArms_call); 

checkBoxLeftArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[0.66,0.15,0.12,0.03],'string','no Left arms movement','callback', @checkBoxArms_call); 

checkBoxBamper = uicontrol('style','checkbox','units','normalized','enable', 'off','FontSize',11,...
    'position',[.170 .57 .11 .03],'string','no bamper movement','callback', @checkBoxBamper_call); 

checkBoxCG = uicontrol('style','checkbox','units','normalized', 'enable', 'off','FontSize',11,...
    'position',[0.49,0.57,0.1,0.03],'string','no CG out of bound','callback', @checkBoxCG_call); 

checkBoxHideSteps = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.46 .06 .09 .03],'string','hide first step', 'Foregroundcolor', 'b',...
    'callback', @checkBoxHide);

checkBoxHideBamper = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.26 .1 .09 .03],'string','hide Bamper', 'Foregroundcolor', 'k','callback',@checkBoxHide);                          
 
checkBoxHideCG = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[0.26,0.06,0.09,0.03],'string','hide CG', 'Foregroundcolor',...
    [0.8003 0.1524 0.8443],'callback',@checkBoxHide);

checkBoxHideRightArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.36 .1 .09 .03],'string','hide Right arm', 'Foregroundcolor', 'r',...
    'callback', @checkBoxHide); 

checkBoxHideLeftArms = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.36 .06 .09 .03],'string','hide Left arm', 'Foregroundcolor', [0.3922 0.7782 0.5277],...
    'callback', @checkBoxHide);

checkBoxFall = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.56 .06 .05 .03],'string','Fall','callback', @simplecb);

checkBoxMS = uicontrol('style','checkbox','units','normalized','FontSize',11,...
    'position',[.56 .1 .05 .03],'string','MS','callback', @simplecb);

%slider
slider = uicontrol('Style','slider','units','normalized','Position',[.82 .1 .14 .03],'Callback',@slider_call);

typeOfArmMove=uicontrol('Style','edit','units','normalized','FontSize',11,...
    'Position',[0.70 0.06 0.10 0.03],'string','','Callback',@simplecb);


typeOfLegMove=uicontrol('Style','edit','units','normalized','FontSize',11,...
    'Position',[0.70 0.10 0.10 0.03],'string','','Callback',@simplecb);

typeLegs_Move = uicontrol('String', 'Type Of Legs Move:', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
    'fontweight', 'bold','Position', [0.60 0.10 0.10 0.03], 'BackgroundColor',  [.925 .914 .847]);%#ok<NASGU>

TypeArms_Move = uicontrol('String', 'Type Of Arms Move:', 'Units', 'normalized','FontSize',11, 'Style', 'Text',...
    'fontweight', 'bold','Position', [0.60 0.06 0.10 0.03], 'BackgroundColor',  [.925 .914 .847]);%#ok<NASGU>

set(gcf,'windowButtonUpFcn',@releaseCallback); % set release callback for SF line 
ispressed = 0; % flag for SF line being pressed


%% whatf are haxes?
haxes = struct;
subs = {'CG','Bamper','Step','Arms'};
colors = {'k','k','b','c','r','r',...
    [0.8003,0.1524,0.8443],[0.8003,0.1524,0.8443],...
    [0.3922 0.7782 0.5277],[0.3922 0.7782 0.5277],'b'...
};


for sub = 1:length(subs)
    ax = axes();
    xlabel(ax,'Time', 'fontname' , 'Cambria' , 'fontweight' , 'b')
    ylabel(ax,'Position', 'fontname' , 'Cambria' , 'fontweight' , 'b')
    SFLines{sub} = line([0 0], [0 0],'Color', [0.6557 0.1067 0.3111],...
        'lineWidth',1.5,'Parent',ax,'ButtonDownFcn',@SFLine1Callback); %#ok<SHVAI>
    lines = {};
    s = struct;
    for j=1:11
        l = imline(ax,[0 0], [0 0]);
        l.setColor(colors{j});
        addNewPositionCallback(l,@(pos)linecb(pos,j));
        lines{j} = l;
    end
    s.lines = lines;
    s.coords = ax;
    haxes.(subs{sub}) = s;
end

function linecb(pos,ind)
    haxes.CG.lines{ind}.setPosition(pos);
    haxes.Bamper.lines{ind}.setPosition(pos);
    haxes.Step.lines{ind}.setPosition(pos);
    haxes.Arms.lines{ind}.setPosition(pos);
end

function simplecb(hObject,~,~)
    if strcmp(hObject.Style,'edit')
        val = hObject.String;
    else
        val = hObject.Value;
    end
    if hObject == typeOfArmMove
        datName = 'TypeArmMove';
    elseif hObject == typeOfLegMove
        datName = 'TypeLegMove';
    elseif hObject == checkBoxMS
        datName = 'MS';
    elseif hObject == checkBoxFall
        datName = 'Fall';
    else
        error('simplecb registered as callback for inappropriate element');
    end
    pertNumber = ListBoxPertubation.Value;
    Vdata2(pertNumber).(datName) = val;
    Vdata(pertNumber).(datName) = val;
end

%cg
set(haxes.CG.coords,'Units', 'normalized','Position', [.49 .635 .3 .300], 'Box', 'on');
title(haxes.CG.coords, 'CG and feet movement')

% bamper axes
set(haxes.Bamper.coords,'Units', 'normalized','Position', [.15 .635 .3 .300], 'Box', 'on');
title(haxes.Bamper.coords,'Bamper X movement')

% arms axes
set(haxes.Arms.coords,'Units', 'normalized','Position', [.49 .225 .3 .300], 'Box', 'on');
title(haxes.Arms.coords,'Change in arms distance from CG')

% step axes
set(haxes.Step.coords,'Units', 'normalized','Position', [.15 .225 .3 .300], 'Box', 'on');
title(haxes.Step.coords, 'Step')

% stick figures
haxes.SF = axes('Units', 'normalized','Position', [.83 .18 .14 .70], 'Box', 'on');
title(haxes.SF, 'Stick Figure')   


%% functions of the GUI 
function setTarget(~,~,~)
    [f,p,indicator]  = uigetfile('C:\Users\Public\Stick-Figures\*.csv');
    if indicator == 0
        return;
    end
    if isempty(regexpi(f,'(walk|stand)','match'))
        errordlg('The Data File Must Contain the Word "Standing" or "Walking" (case insensitive)',...
            'Incorrect File Name','replace');
    end
    h.set('name',['processing: ',p,f]);
    tarfile = fullfile(p,f);
    uiresume(h);
end

function listBoxPertu_call(~,~,~)   
    contents = cellstr(ListBoxPertubation.String); 
    validx = ListBoxPertubation.Value; 
    NewText = contents{validx}; 
    NewColor = sprintf('<HTML><BODY bgcolor="%s">%s', 'green', NewText);
    newstr = regexprep(NewColor, '"red"','"blue"'); 
    contents{validx} = newstr; 
    ListBoxPertubation.String = contents;
end 


function drawButtonselected_cb(~,~)
    pertNumber =get(ListBoxPertubation,'Value');
    if Vdata(pertNumber).edited % edited-0 (not analyzed) edited -1 (analyzed)
        israw = 2;
        set(typeOfLegMove,'String',Vdata2(pertNumber).TypeLegMove);
        set(typeOfArmMove,'String',Vdata2(pertNumber).TypeArmMove);
        set(checkBoxFall,'Value',Vdata2(pertNumber).Fall);
        set(checkBoxMS,'Value',Vdata2(pertNumber).MS);
    else         
        israw = 1;
        set(typeOfLegMove,'String','');
        set(typeOfArmMove,'String','');
        set(checkBoxFall,'Value',0);
        set(checkBoxMS,'Value',0);
    end
    clearButtonselected_cb();
    DrawCOP(pertNumber, israw);
    set(patientNameLabel,'string',vcd.subjname)
end

function clearButtonselected_cb()
    fields = fieldnames(plotHandles.handles);
    % one loop to set active handles off
    for i=1:length(fields)
        f = fields{i};
        o = plotHandles.handles.(strip(f,'2'));
        set(o(plotHandles.isplotted.fixed == 1 & o ~= 0),'Visible','off');
        if endsWith(f,'2') || ~isempty(regexp(f,'(Left|Right)CG','ONCE'))
            set(o(plotHandles.isplotted.mutables == 1 & o ~= 0),'Visible','off');
        end
    end
    % and a second loop for the reset.. (long story)
    for i=1:length(fields)
        plotHandles.handles.(fields{i}) = zeros(size(Vdata));
    end
    plotHandles.isplotted.fixed = zeros(size(Vdata));
    plotHandles.isplotted.mutables = zeros(size(Vdata));
    set(patientNameLabel,'string', '')
end

function DrawCOP(pertNumber, israw)
    d1 = Vdata(pertNumber);
    d2 = Vdata2(pertNumber);
    function set_line_positions(obj,source)
        %% to check
        %obj.lines{1}.setPosition([240 240],tip);
        %obj.lines{2}.setPosition([length(d.bamper)-360 length(d.bamper)-360], [-50000 50000]);
        ylims = obj.coords.YLim + [-100,100];
        le = length(d1.bamper)-360;
        haxes.Bamper.lines{1}.setPosition([240,240],ylims);
        haxes.Bamper.lines{2}.setPosition([le,le],ylims);
        datas = {'','','steppingTime','','RightarmsTime','','cgOut','','LeftarmsTime'};
        for i=3:2:9
            xposition = source.(datas{i});
            obj.lines{i}.setPosition([xposition(1),xposition(1)],ylims);
            obj.lines{i+1}.setPosition([xposition(2),xposition(2)],ylims);
        end
        obj.lines{11}.setPosition([source.EndFirstStep source.EndFirstStep],ylims);
    end
    if israw == 1
        source = d1;
    else
        source = d2;
    end
    plotHandles.isplotted.fixed(pertNumber) = 1;
    set(checkBoxHideRightArms,'Value', 0);
    set(checkBoxHideLeftArms,'Value', 0);
    set(checkBoxHideSteps,'Value', 0);
    set(checkBoxHideCG,'Value', 0);
    set(checkBoxHideBamper,'Value', 0);

    axes(haxes.Bamper.coords); 
    set(SFLines{3}, 'YData',ylim,'XData',[1,1])
    hold on
    plotHandles.handles.Bamper(pertNumber) = plot(haxes.Bamper.coords,d1.bamper,'color', 'k' ,'LineWidth',1.5); 
    ylim(haxes.Bamper.coords,[min(d1.bamper)-100, max(d1.bamper)+ 100]);
    xlim(haxes.Bamper.coords,[1 length(d1.bamper)]);
    title(haxes.Bamper.coords, 'Bamper X movement');  

    set_line_positions(haxes.Bamper,source);

    if d1.pertubationsTime(1)< 0
        set(checkBoxBamper, 'value', 1);
    else
        set(checkBoxBamper, 'value', 0);
    end
    set(slider,'min',1);
    set(slider,'max', length(d1.bamper));
    set(slider,'value',1)

    axes(haxes.CG.coords);
    set(SFLines{1}, 'YData',tip,'XData',[1,1])
    hold on
    if strcmp(vcd.perturbation_type(pertNumber),'ML')
        plotHandles.handles.LeftCG(pertNumber) = plot(haxes.CG.coords,d1.leftAnkleX,'color', 'g' ,'LineWidth',1.5); 
        hold on
        plotHandles.handles.RightCG(pertNumber) = plot(haxes.CG.coords, d1.rightAnkleX,'color', 'r' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.LeftHCG(pertNumber) = plot(haxes.CG.coords,tip,'color', 'g' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.LeftTCG(pertNumber) = plot(haxes.CG.coords,tip,'color', 'r' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.RightHCG(pertNumber) = plot(haxes.CG.coords,tip,'color', [0.5 0.2 0.7] ,'LineWidth',1.5);
        hold on
        plotHandles.handles.RightTCG(pertNumber) = plot(haxes.CG.coords,tip,'color', [0.4 0.3 0.6] ,'LineWidth',1.5);
        hold on
        plotHandles.handles.CG(pertNumber) = plot(haxes.CG.coords, d1.CGX,'color', 'b' ,'LineWidth',1.5); 
        hold on
        legend([plotHandles.handles.LeftCG(pertNumber), plotHandles.handles.RightCG(pertNumber),...
                    plotHandles.handles.CG(pertNumber)], 'left', 'right', 'CG');
        ylim(haxes.CG.coords,[min(min(d1.rightAnkleX,d1.leftAnkleX))-100,max(max(d1.leftAnkleX,d1.rightAnkleX))+ 100])
        xlim(haxes.CG.coords,[1, length(d1.bamper)])
    else 
        plotHandles.handles.LeftCG(pertNumber) = plot(haxes.CG.coords,tip,'color', 'g' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.RightCG(pertNumber) = plot(haxes.CG.coords,tip,'color', 'r' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.LeftHCG(pertNumber) = plot(haxes.CG.coords, d1.leftHeelY,'color', 'g' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.LeftTCG(pertNumber) = plot(haxes.CG.coords,d1.leftToeY,'color',[ 0.1 0.6 0.4],'LineWidth',1.5);
        hold on
        plotHandles.handles.RightHCG(pertNumber) = plot(haxes.CG.coords,d1.rightHeelY,'color', 'r' ,'LineWidth',1.5); 
        hold on
        plotHandles.handles.RightTCG(pertNumber) = plot(haxes.CG.coords, d1.rightToeY,'color', [0.9 0.3 0.1] ,'LineWidth',1.5);
        hold on
        plotHandles.handles.CG(pertNumber) = plot(haxes.CG.coords, Vdata(pertNumber).CGY,'color', 'b' ,'LineWidth',1.5);
        hold on
        legend([plotHandles.handles.LeftHCG(pertNumber), plotHandles.handles.LeftTCG(pertNumber),...
            plotHandles.handles.RightHCG(pertNumber), plotHandles.handles.RightTCG(pertNumber),...
            plotHandles.handles.CG(pertNumber)], 'leftHeelY', 'leftToeY','rightHeelY', 'rightToeY', 'CGY');
        ylim(haxes.CG.coords,[min(min(d1.leftToeY),min(d1.rightToeY))-100 max(max(d1.leftHeelY),max(d1.rightHeelY))+ 100])
        xlim(haxes.CG.coords,[1, length(d1.bamper)])
    end
    title(haxes.CG.coords, 'CG and feet movement');
    set_line_positions(haxes.CG,source); % check first two -- they are bamper in orig for some reason
    if d1.cgOut(1)< 0
        set(checkBoxCG, 'Value', 1);
    else
        set(checkBoxCG, 'Value', 0);
    end

    axes(haxes.Step.coords);
    hold on
    set(SFLines{2}, 'YData',tip, 'XData', [1 1])

    if strcmp(vcd.condition,'stand')
        plotHandles.handles.LeftStep(pertNumber) = plot(haxes.Step.coords,d1.leftStepping,'color', 'g' ,'LineWidth',1.5); 
        hold on
        plotHandles.handles.RightStep(pertNumber) = plot(haxes.Step.coords,d1.rightStepping,'color', 'r' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.RightStep(pertNumber) = plot(haxes.Step.coords,d1.rightAnkleX,'color', 'r' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.LeftStepA(pertNumber) =plot(haxes.Step.coords,0,0,'b');
        hold on
        plotHandles.handles.RightStepA(pertNumber)= plot(haxes.Step.coords,0,0);
        hold on
        ylabel(haxes.Step.coords,'Poisition', 'fontname' , 'Cambria' , 'fontweight' , 'b');
        title(haxes.Step.coords, 'Step');
        legend([plotHandles.handles.LeftStep(pertNumber),...
            plotHandles.handles.RightStep(pertNumber)], 'left', 'right');

    else % walking 
        plotHandles.handles.LeftStep(pertNumber) = plot(haxes.Step.coords,0,0,'b');
        hold on
        plotHandles.handles.RightStep(pertNumber)= plot(haxes.Step.coords,0,0);
        hold on
        VelocityL = (d1.leftStepping(2:end)-d1.leftStepping(1:end-1))*vcd.datarate;
        VelocityR = (d1.rightStepping(2:end)-d1.rightStepping(1:end-1))*vcd.datarate;
        AccL=(VelocityL(2:end)-VelocityL(1:end-1))*vcd.datarate;
        AccR=(VelocityR(2:end)-VelocityR(1:end-1))*vcd.datarate;
        plotHandles.handles.LeftStepA(pertNumber) = plot(haxes.Step.coords,AccL ,'color', 'g' ,'LineWidth',1.5);
        hold on
        plotHandles.handles.RightStepA(pertNumber) = plot(haxes.Step.coords, AccR ,'color', 'r' ,'LineWidth',1.5);
        hold on
        ylabel(haxes.Step.coords,'Acceleration', 'fontname' , 'Cambria' , 'fontweight' , 'b');
        title(haxes.Step.coords, 'Step Acceleration');
        legend([plotHandles.handles.LeftStepA(pertNumber), plotHandles.handles.RightStepA(pertNumber)], 'left', 'right');
    end
    xlim(haxes.Step.coords,[1, length(d1.bamper)])
    if strcmp(vcd.condition,'walk')
        ylim(haxes.Step.coords,[min(min(AccL),min(AccR))-20,max(max(AccL),max(AccR))+20])
    else
        ylim(haxes.Step.coords,[min(min(d1.leftStepping),min(d1.rightStepping))-100 max(max(d1.leftStepping),max(d1.rightStepping))+ 100])
    end
    set_line_positions(haxes.Step,source);
    
    if d1.steppingTime(1)< 0
        set(checkBoxSteps, 'value', 1);
        set(listBoxStep,'value', 3);

    else
        set(checkBoxSteps, 'value', 0);
        if d1.firstStep==1
            set(listBoxStep,'value', 1);
        else
            set(listBoxStep,'value', 2);
        end
    end

    axes(haxes.Arms.coords);
    hold on
    set(SFLines{4}, 'YData', ylim,'XData', [1 1]);
    plotHandles.handles.LeftArm(pertNumber) = plot(haxes.Arms.coords,d1.leftArmTotal,'color', 'g' ,'LineWidth',1.5);
    hold on
    plotHandles.handles.RightArm(pertNumber) = plot(haxes.Arms.coords,d1.rightArmTotal,'color', 'r' ,'LineWidth',1.5);
    hold on
    title(haxes.Arms.coords, 'Change in arms distance from CG');
    %set_line_positions(haxes.Step,source); % again?
    ylim(haxes.Arms.coords,[min(min(d1.leftArmTotal),min(d1.rightArmTotal))-100 max(max(d1.leftArmTotal),max(d1.rightArmTotal))+ 100])
    xlim(haxes.Arms.coords,[1, length(Vdata(pertNumber).bamper)])

    legend([plotHandles.handles.LeftArm(pertNumber), plotHandles.handles.RightArm(pertNumber)], 'left', 'right')
    if d1.RightarmsTime(1)< 0
        set(checkBoxRightArms, 'value', 1);
    else
        set(checkBoxRightArms, 'value', 0);
    end
     if d1.LeftarmsTime(1)< 0
        set(checkBoxLeftArms, 'value', 1);
    else
        set(checkBoxLeftArms, 'value', 0);
     end
    set(slider,'min',1);
    set(slider,'max', length(d1.bamper));
    set(slider,'value',1);
    if israw == 2
        plotHandles.isplotted.mutables(pertNumber) = 1; 
    end
    axes(haxes.SF);
    set(gca,'ydir','reverse');
    view(-11,-20);
    xlim([min(d1.SFdATA(1,1:3:end))-1, max(d1.SFdATA(1,1:3:end))+ 1]);
    ylim([min(d1.SFdATA(1,2:3:end))-1, max(d1.SFdATA(1,2:3:end))+ 1]);
    zlim([min(d1.SFdATA(1,3:3:end))-1, max(d1.SFdATA(1,3:3:end))+ 1]);
end


function saveButtonselected_cb(~,~)
    pertNumber = ListBoxPertubation.Value;
    % reset buttons
    for chk = {checkBoxHideBamper,checkBoxHideCG}
        if chk{:}.Value == 1
            chk{:}.Value = 0; %#ok<FXSET>
            checkBoxHide(chk{:});
        end
    end
    for chk = {'RightArms','LeftArms','Steps'}
        if eval(['checkBox' chk{:} '.Value == 0']) && eval(['checkBoxHide' chk{:} '.Value == 1'])
             eval(['checkBoxHide' chk{:} ' = 0']);
             checkBoxHide(eval(['checkBoxHide' chk{:}]));
        end
    end 
    
    function pos = linepos(n)
        pos = round(haxes.CG.lines{n}.getPosition());
        pos = pos(1,1);
    end
    
    % update first and last fot
    if linepos(3) < 0 
        %%%%%%%%%%%%%%%%%
        %%% add if to check if the step is hidden, if so then still do
        %%% updatestepping function
        firstStep = 0; %no steps
        lastStep = 0; %no steps
        set(listBoxStep,'value',3);
    else
        %update Vdata2: if the data is hidden then it is taken from Vdata3    
        [firstStep, lastStep] = updateStepping(Vdata(pertNumber).leftStepping, Vdata(pertNumber).rightStepping, floor(linepos(3)), linepos(4));
    end
    if listBoxStep.Value ~= firstStep
         Vdata2(pertNumber).firstStep = listBoxStep.Value;
    end
    
    for specs = {{checkBoxHideRightArms,{'RightarmsTime'},[5,6]},...
        {checkBoxHideLeftArms,{'LeftarmsTime'},[9,10]},...
        {checkBoxHideSteps,{'steppingTime'},[3,4,11]},...
        {checkBoxHideCG,{'cgOut','pertubationsTime'},[7,8,1,2]}}
        hider = specs{1,1}{1};
        datcols = specs{1,1}{2};
        linenumber = specs{1,1}{3};
        if hider.Value == 0
            Vdata2(pertNumber).(datcols{1}) = [linepos(linenumber(1)) linepos(linenumber(2))];
            if length(datcols) == 2
                Vdata2(pertNumber).(datcols{2}) = [linepos(linenumber(3)) linepos(linenumber(4))];
            end
        else
            for dc = datcols
                Vdata2(pertNumber).(dc{:}) = Vdata3(pertNumber).(dc{:});
            end
        end
    end

    Vdata2(pertNumber).lastStep = lastStep;
    
    %update Vdata eddited
    Vdata(pertNumber).edited = true;
    listBoxPertu_call
    namestr = cellstr(ListBoxPertubation.String); 
    Vdata(pertNumber).StringPer=namestr{pertNumber};
    %save data
    vcd.fixed = Vdata;
    vcd.mutables = Vdata2;
    vcd.savedata();
    set(typeOfLegMove,'String','');
    set(typeOfArmMove,'String','');
    set(checkBoxFall,'Value',0);
    set(checkBoxMS,'Value',0);
    if pertNumber < vcd.numperts
        ListBoxPertubation.Value = pertNumber+1;
    end
    pause(0.1);
    drawButtonselected_cb
end

function [firstStep, lastStep] = updateStepping(left, right, startindex, endindex)
    if(left(startindex) > right(startindex))
        firstStep =2;
    else
        firstStep =1;
    end
    if(left(endindex) >right(endindex))
        lastStep =2;
    else
        lastStep =1;
    end
end


function exportButtonselected_cb(~,~)
    % initialize the export variables in an ordered struct
    tomillis = 1000/vcd.datarate;
    export = struct('data',struct);
    export.header = {'Step','Perturbation side: [1]Right/[2]Left/[3]Forward/[4]Backward',...
        'Response time [msec])','Time from bamper movement until end of 1st step [msec]',...
        'First step duration [msec]','first step length [mm]',...
        'Time from bamper movement until end of all steps [msec]',...
        'maximal distance of ending-movement foot from its` start point [mm]',...
        'is CG out of base support before movement 0-in base,1-not in base',...
        'time between lose of balance and beginning of step [msec]',...
        'minimal distance of CG from legs before movement [mm]',...
        'distance of CG from leg at the step-beginning point [mm]',...
        'maximal distance of CG from balance point [mm]',...
        'total distance CG made [mm]', 'Right arm distance [mm]','Left arm distnace [mm]',...
        'time from bamper movement until right arm lift [msec]','Right arm swing time [msec]',...
        'time from bamper movement until left arm lift [msec]','Left arm swing time [msec]',...
        'Fall','MultiSteps','TypeArmMove','TypeLegMove','LElbowAngX[deg]','LShoulderAngX[deg]',...
        'LShoulderAngY[deg]','LShoulderAngZ[deg]','RElbowAngX[deg]','RShoulderAngX[deg]',...
        'RShoulderAngY[deg]','RShoulderAngZ[deg]','First Step Length[mm] - Bamper FB'};
    
    if strcmp(vcd.condition,'stand')
        protocol = repmat([4,2,3,1],1,6)';
    else
        protocol = repmat([1, 2],1,6)';
    end
    
    export.specs ={{'BamperToEndOfSteps','G',1},... % object name, excell location, type of data 1 - 9999*ones, 2 - zeros, 3 - cell...
            {'firstStepLength','F',1},...
            {'firstStepLength2','AG',1},...
            {'firstStepDuration','E',1},...
            {'responseTime','C',1},...
            {'BamperToEndFirstStep','D',1},...
            {'lastStepMax','H',1},...
            {'cgOutBeforeMovement','I',1},...
            {'loseOfBalanceToFirstStep','J',1},...
            {'minCGDistFromLeg','K',1},...
            {'CGToNearestAtFirstStep','L',1},...
            {'MaxCGOutFromLeg','M',1},...  
            {'totalDistCGMade','N',1},...
            {'rightArmDistance','O',1},...
            {'leftArmDistance','P',1},...
            {'BamperToRightArmTime','Q',1},...
            {'rightArmSwingTime','R',1},...
            {'BamperToLeftArmTime','S',1},...
            {'leftArmSwingTime','T',1},...
            {'LElbowAng','Y',1},...
            {'RElbowAng','AC',1},...
            {'Fall','U',2},...
            {'MS','V',2},...
            {'TypeArmMove','W',3},...
            {'TypeLegMove','X',3},...
            {'LShoulderAng','Z:AB',4},...
            {'RShoulderAng','AD:AF',4}...
        };
    for spec=export.specs
        switch spec{:}{3}
            case 1
                initializer = ones(vcd.numperts,1)*99999;
            case 2
                initializer = zeros(vcd.numperts,1);
            case 3
                initializer = cell(vcd.numperts,1);
            case 4
                initializer = zeros(vcd.numperts,3);
        end
        export.data.(spec{:}{1}) = initializer;
    end      
    
    Perturbation_dist= [];
    for i = 1:6
        Perturbation_dist = [Perturbation_dist repmat(30,1,4)*i];
    end
    % 1-right, 2-left, 3-forward, 4-backward
    direction= repmat([4,3,2,1],1,6); 
    
    function [dist,ind] = maxdist(row,column,marker,offset_anchor,spare)
        targetx = vcd.cellindex(vcd.trajcolumns,marker);
        anchor = vcd.cellindex(vcd.trajcolumns,offset_anchor);
        source = Vdata(row).SFdATA;
        range = Vdata2(row).(column)(1):Vdata2(row).(column)(2)+spare;
        % x,y,z - bamper now (separately because of the offsets).
        dx = source(range,targetx) - source(range(1),targetx);
        dy = source(range,targetx+1) - source(range(1),targetx+1);
        dz = source(range,targetx+2) - source(range(1),targetx+2);
        % ML perturbation -- offset the x component from bamper
        if strcmp(offset_anchor,'bamperL')
            dx = (dx - source(range,anchor)) + source(range(1),anchor);
        else
        % AP perturbation -- offset the y component from bamper
            dy = (dy - source(range,anchor)) + source(range(1),anchor);
        end
        [dist,ind] = max(vecnorm([dx,dy,dz]'));
    end
    function estl = edge_step_length(row,leftorright,firstorlast)
        if leftorright == 1
            ank = 'RANK';
        else
            ank = 'LANK';
        end
        ankx = vcd.cellindex(vcd.trajcolumns,ank);
        ankle_range = Vdata2(row).EndFirstStep;
        if firstorlast == 1 % get max last
            ankle_range = t:Vdata2(row).steppingTime(2);
        end
        bamp = vcd.cellindex(vcd.trajcolumns,'bamperL');
        source = Vdata(row).SFdATA;
        dxs = (source(ankle_range,ankx) - source(t,ankx)) - source(ankle_range,bamp) + source(t,bamp) ; % x displacement of every point in the range, with bamper set off
        dys = source(ankle_range,ankx+1) - source(t,ankx+1); % same but without the bamper offset
        estl = max(vecnorm([dxs,dys]'));
    end
    %run over all perturbations
    for i =1:vcd.numperts
        d = Vdata(i);
        d2 = Vdata2(i);
        
        export.data.Fall(i)= d2.Fall;
        export.data.MS(i)= d2.MS;
        export.data.TypeArmMove{i}=d2.TypeArmMove;
        export.data.TypeLegMove{i}=d2.TypeLegMove;
        
        % detect step and arm reactions
        rightArmTimes = d2.RightarmsTime(1) >=0;
        leftArmTimes = d2.LeftarmsTime(1) >= 0;
        reactionStepTimes = d2.steppingTime(1) >=0;
        if strcmp(vcd.perturbation_type(i),'ML')
            offstanchor = 'bamperL';
            spare = 0;
        else
            % to check with Inbal
            if d2.firstStep == 1
                offstanchor = 'LANK';
            else
                offstanchor = 'RANK';
            end
            spare = 10;
        end
        
        if(rightArmTimes)
            [rightArmDistance, rightMaxInd] = maxdist(i,'RightarmsTime','RFIN',offstanchor,spare);
            export.data.BamperToRightArmTime(i) =(d2.RightarmsTime(1) - d2.pertubationsTime(1))*tomillis; %% check with Inbal originally written as Vdata2(1).pertubationsTime(1) everywhere
            export.data.rightArmSwingTime(i) = rightMaxInd*tomillis;
            export.data.RElbowAng(i)=d.RElbowAng(d2.RightarmsTime(2))-d.RElbowAng(d2.RightarmsTime(1));
            export.data.RShoulderAng(i,:)=d.RShoulderAng(d2.RightarmsTime(2),:)-d.RShoulderAng(d2.RightarmsTime(1),:);
            export.data.rightArmDistance(i) = rightArmDistance;
        end
        if(leftArmTimes)
            [leftArmDistance, leftMaxInd] = maxdist(i,'LeftarmsTime','LFIN',offstanchor,spare);
            export.data.BamperToLeftArmTime(i) =(d2.LeftarmsTime(1)-d2.pertubationsTime(1))*tomillis;
            export.data.leftArmSwingTime(i) = leftMaxInd*tomillis;
            export.data.LElbowAng(i)=d.LElbowAng(d2.LeftarmsTime(2))-d.LElbowAng(d2.LeftarmsTime(1));
            export.data.LShoulderAng(i,:)=d.LShoulderAng(d2.LeftarmsTime(2),:)-d.LShoulderAng(d2.LeftarmsTime(1),:);
            export.data.leftArmDistance(i) = leftArmDistance;
        end
        if(reactionStepTimes)
            t = d2.steppingTime(1);
            cgr = d2.cgOut(1):d2.cgOut(2);
            export.data.responseTime(i) = (t - d2.pertubationsTime(1))*tomillis;
            export.data.BamperToEndOfSteps(i) = (d2.steppingTime(2) -  d2.pertubationsTime(1))*tomillis;
            export.data.BamperToEndFirstStep(i) = (d2.EndFirstStep - d2.pertubationsTime(1))*tomillis;


            if strcmp(vcd.perturbation_type(i),'ML')
                export.data.totalDistCGMade(i) = sum(abs(diff(d.CGX(2*vcd.datarate+1:end))));
                export.data.CGToNearestAtFirstStep(i) = min([...
                    abs(d.CGX(t) - d.leftAnkleX(t)),...
                    abs(d.CGX(t)- d.rightAnkleX(t))...
                ]);
                if abs(d.CGX(end) - d.leftAnkleX(end)) > abs(d.CGX(end) - d.rightAnkleX(end))
                    cgtoleg = 1; %cg moves towards right foot
                    ref = 'rightAnkleX';
                else
                    cgtoleg = 2; %cg moves towards left foot
                    ref = 'leftAnkleX';
                end
                if d2.cgOut(1) < 0
                    export.data.cgOutBeforeMovement(i) = 0;
                    export.data.minCGDistFromLeg(i) = min(abs(d.CGX(1:t) - d.(ref)(1:t)));
                else
                    export.data.MaxCGOutFromLeg(i) = min([...
                        max(abs(d.CGX(cgr) - d.leftAnkleX(cgr))),...
                        max(abs(d.CGX(cgr) - d.rightAnkleX(cgr)))...
                    ]);
                    if cgr(1) < t
                        export.data.cgOutBeforeMovement(i) = 1;
                        export.data.loseOfBalanceToFirstStep(i) = (t - cgr(1))*tomillis;
                    else
                        export.data.cgOutBeforeMovement(i) = 0;
                        if(cgtoleg == 1)
                            export.data.minCGDistFromLeg(i) = min(abs(d.CGX(1:t) - d.rightAnkleX(1:t)));
                        else
                            export.data.minCGDistFromLeg(i) = min(abs(d.CGX(1:t) - d.leftAnkleX(1:t)));
                        end                    
                    end
                end
                
                export.data.firstStepLength(i) = edge_step_length(i,d2.firstStep,0);
                export.data.lastStepMax(i)  = edge_step_length(i,d2.firstStep,1);
            
            else % AP perturbation
                export.data.totalDistCGMade(i) = sum(abs(diff(d.CGY(241:end))));
                export.data.CGToNearestAtFirstStep(i) = min(abs([d.leftHeelY(t),d.leftToeY(t),d.rightHeelY(t),d.rightToeY(t)] - d.CGY(t)));
                if abs(d.CGY(end) - d.leftHeelY(end)) > abs(d.CGY(end) - d.leftToeY(end))
                    cgtoleg = 3; % cg moves towards Toes
                    ref = 'Toe';
                else
                    cgtoleg = 4; % cg moves towards Ankles
                    ref = 'Heel';
                end
                if d2.cgOut(1) < 0
                    export.data.cgOutBeforeMovement(i) = 0;
                    export.data.minCGDistFromLeg(i) = min(abs([min(d.CGY(1:t) - d.(['left' ref 'Y'])(1:t)),min(d.CGY(1:t) - d.(['right' ref 'Y'])(1:t))]));
                else % cg out is >= 0 whatever that means
                    export.data.MaxCGOutFromLeg(i) = min([...
                        max(abs(d.CGY(cgr) - d.leftHeelY(cgr))),...
                        max(abs(d.CGY(cgr) - d.leftToeY(cgr))),...
                        max(abs(d.CGY(cgr) - d.rightHeelY(cgr))),...
                        max(abs(d.CGY(cgr) - d.rightToeY(cgr)))...
                    ]);
                    if cgr(1) < t
                        export.data.cgOutBeforeMovement(i) = 1;
                        export.data.loseOfBalanceToFirstStep(i) = (t - cgr(1))*tomillis;
                    else
                        export.data.cgOutBeforeMovement(i) = 0;
                        if(cgtoleg == 3) % toes
                            export.data.minCGDistFromLeg(i) = min(...
                                (abs(min(d.CGY(1:t) - d.leftToeY(1:t)))),...
                                (abs(min(d.CGY(1:t) - d.rightToeY(1:t))))...
                            );
                        else % heels
                            export.data.minCGDistFromLeg(i) = min(...
                                (abs(min(d.CGY(1:t) - d.leftHeelY(1:t)))),...
                                (abs(min(d.CGY(1:t) - d.rightHeelY(1:t))))...
                            );
                        end                  
                    end
                end

                prdist = Perturbation_dist(i)^2;
                do2 = false;
                rankx = vcd.cellindex(vcd.trajcolumns,'RANK');
                lankx = vcd.cellindex(vcd.trajcolumns,'LANK');
                % sort out the various conditions
                if d2.firstStep == 1 %right leg first: refer to right ankle
                    ref2 = rankx;
                else
                    ref2 = lankx; % left first to left
                end

                if direction(i) > 2
                    do2 = true;
                    if direction(i) == 4 % subtract if 4 add if 3, do nothing if 1 or 2
                        prdist = -1 * prdist;
                    end
                end
                if d2.lastStep == 1
                    lastref = rankx;
                else
                    lastref = lankx;
                end
                % compute once!! accordingly 
                export.data.firstStepLength(i) = vecnorm(diff(d.SFdATA(d2.EndFirstStep,[lankx:lankx+1,rankx:rankx+1]))');
                if do2
                    dx2 = diff(d.SFdATA([d2.EndFirstStep,t],ref2));
                    dy2 = diff(d.SFdATA([d2.EndFirstStep,t],ref2)) + prdist;
                    export.data.firstStepLength2(i) = vecnorm([dx2,dy2]');                
                end
                export.data.lastStepMax(i) = max(vecnorm(d.SFdATA(t:d2.steppingTime(2),lastref:lastref+1) - d.SFdATA(t,lastref:lastref+1)')); 
            end
            export.data.firstStepDuration(i) = export.data.BamperToEndFirstStep(i) - export.data.responseTime(i);          
        end
    end   
    
    %print to excel
    savefile = strcat('Analyzed-',vcd.subjname,'-',vcd.condition,'-',vcd.distract,'.xlsx');
    saveto = fullfile(vcd.savefolder,savefile);
    saveto = saveto{:}; % stupid matlab
    xlswrite(saveto,export.header,'Sheet1','A1');
    xlswrite(saveto,(1:vcd.numperts)','Sheet1','A2');
    xlswrite(saveto,protocol,'Sheet1','B2');
    for spec=export.specs
        cols = spec{:}{2};
        m = export.data.(spec{:}{1});
        if ~contains(cols,':')
            xlswrite(saveto,m,'Sheet1',[cols '2']);
        else
            for r = 1:size(m,1)
                row = r+1;
                col = [strrep(cols,':',[num2str(row) ':']) num2str(row)]; % for example Z:AB --> Z3:AB3 when the row is 3
                xlswrite(saveto,m(r,:),col);
            end
        end
    end
    msgbox('export finished');
end

function checkBoxSteps_call(~,~,~)
    pertNumber = get(ListBoxPertubation,'Value');
    lines = [3,4,11];
    posxs = [30,70,50];
    stptime = Vdata2(pertNumber).steppingTime;
    invtip = [1,-1] .* tip; 
    for line = 1:3 %#ok<FXUP>
        lineid = lines(line);
        posx = posxs(line);
        if checkBoxSteps.Value == 0
            if Vdata(pertNumber).steppingTime < 0 
                haxes.Step.lines{lineid}.setPosition([posx,posx],tip);
                lbp = 1;
            else 
                if lineid == 3
                    xs = stptime(1);
                elseif lineid == 4
                    xs = stptime(2);
                else
                    xs = Vdata2(pertNumber).EndFirstStep;
                end
                haxes.Arms.lines{lineid}.setPosition([xs,xs],tip);
                lbp = 1;
                if Vdata(pertNumber).firstStep ~= 1
                    lbp = 2;
                end
            end
        else
            haxes.Step.lines{lineid}.setPosition(invtip,tip);
            lbp = 3;
        end
    end
    set(listBoxStep,'Value',lbp); 
end

function listBoxSteps_call(~, ~, ~)
    % define relevant vars
    pertNumber = get(ListBoxPertubation,'Value');
    leftright = listBoxStep.Value;
    d = Vdata2(pertNumber);
    stpt = d.steppingTime;
    something = Vdata(pertNumber).firstStep==0 || stpt(1)<0;
    frstval = 0;
    chkbxval = 1;
    lineids = [2,4,11];
    linesin = 'Arms';
    
    % figure out the firstStep and checkBoxStep values
    % and where to plot the lines
    if leftright < 3
        frstval = leftright;
        chkbxval = 0;
    else
        linesin = 'Step';
    end

    % update the data objects and the check box accordingly
    for obj = {Vdata,Vdata2,Vdata3}
        obj{:}(pertNumber).firstStep = frstval; %#ok<FXSET>
    end
    set(checkBoxSteps,'value',chkbxval);

    % figure out the line xs
    if leftright < 3
        if something
            xs = [100,300,200];
        else
            xs = [stpt,d.EndFirstStep];
        end
    else
        xs = repmat(tip(1),1,3);
    end

    % loop the lines to set the values
    for i = 1:3
        lineid = lineids(i);
        x = xs(i);
        haxes.(linesin).lines{lineid}.setPosition([x,x],tip);
    end
end 

function checkBoxArms_call(hObj,~,~)
    if hObj == checkBoxLeftArms
        line_numbers = [9,10];
        f = 'LeftarmsTime';
    elseif hObj == checkBoxRightArms
        line_numbers = [5,6];
        f = 'RightarmsTime';
    else
        disp('??');
    end
    pertNumber = get(ListBoxPertubation,'Value');
    ys = tip;
    d = Vdata(pertNumber);
    linesin = 'Arms';
    if(hObj.Value == 0)
        if d.(f) <0        
            xs = [50,100];
            linesin = 'Step';
        else
            xs = d.(f);
        end
    else
        xs = [-30,-30];
        ys = xs;
        linesin = 'Step';
    end
    for i = 1:2
        current_line = line_numbers(i);
        x = xs(i);
        haxes.(linesin).lines{current_line}.setPosition([x,x],ys);
    end
end

function checkBoxHide(hObject,~,~)
    do11 = false;
    pert = get(ListBoxPertubation,'Value');
    % sort out what to work on
    switch hObject.String
        case 'hide Right arm'
            tline = 5; 
            f = 'RightarmsTime';
        case 'hide CG'
            tline = 7;
            f = 'cgOut';
        case 'hide Bamper'
            tline = 1;
            f = 'pertubationsTime';
        case 'hide Left arm'
            tline = 9;
            f = 'LeftarmsTime';
        case 'hide first step'
            tline = 3;
            do11 = ~do11;
            f = 'steppingTime';
        otherwise
            disp(hObject.String);
    end
    
    invtip = [1,-1] .* tip;
    line1 = haxes.Step.lines{tline};
    line2 = haxes.Step.lines{tline+1};
    
    % hide if checked and show if unchecked
    if hObject.Value == 1
        % hide box was checked, get current position of the Step line
        x = line1.getPosition();
        y = line2.getPosition();
        Vdata3(pert).(f) = [x(1,1),y(1,1)];
        if do11
            line3 = haxes.Step.lines{11};
            z = line3.getPosition();
            Vdata3(pert).EndFirstStep = z(1,1);
            line3.setPosition(invtip,tip);
        end
        line1.setPosition(invtip,tip);
        line2.setPosition(invtip,tip);
    else
        p1 = Vdata3(pert).(f)(1);
        p2 = Vdata3(pert).(f)(2);
        haxes.Arms.lines{tline}.setPosition([p1 p1],tip);
        haxes.Arms.lines{tline+1}.setPosition([p2 p2],tip);
        if do11
            e = Vdata3(pert).EndFirstStep;
            haxes.Arms.lines{11}.setPosition([e,e],tip);
        end
    end
end

function SFLine1Callback(~,~)
    ispressed = 1;
end

% function callback_SFline(pos)
%     axes(haxes.SF.coords);
%     cla(haxes.SF.coords);
%     boundsrcs = {'Step','Bamper','Arms'};
%     bamperbound = get(haxes.Bamper.coords,'ylim');
%     for i=1:length(boundsrcs) 
%         bound = haxes.(boundsrcs{i}).coords.ylim;
%         SFLines{i+1}.setPosition([pos(1,1), bound(1); pos(1,1),bound(2)]);
%     end
% end

function releaseCallback(~,~)
    if ispressed == 0
        return;
    end
    t =  get(gca,'CurrentPoint');
    axes(haxes.SF);
    cla(haxes.SF);
    for sfl = SFLines
       set(sfl{:}, 'XData', t(:,1));
    end
    set(slider, 'Value', t(1,1));
    plotSF(ceil(t(1,1)));
    ispressed =0;
end

function plotSF(time_point)
    pertNumber = get(ListBoxPertubation,'value');
    c = ceil(time_point);
    axes(haxes.SF);
    cla(haxes.SF);
    xcols = ViconData.stick_figure_markers;
    row = Vdata(pertNumber).SFdATA(c,:);
    for i=1:length(xcols)
        xcol1 = vcd.cellindex(vcd.trajcolumns,xcols{i}{1});
        xcol2 = vcd.cellindex(vcd.trajcolumns,xcols{i}{2});
        xyz = row([xcol1:1:xcol1+2;xcol2:1:xcol2+2]);
        line(xyz(:,1)',xyz(:,2)',xyz(:,3)','Color','k','LineWidth',1.5);
    end
    hold on
    plot3(Vdata(pertNumber).CGX_plot(c),Vdata(pertNumber).CGZ_plot(c),...
        Vdata(pertNumber).CGY_plot(c),'o','MarkerSize',5,'MarkerFaceColor','r');
    xlim([-700, 1500])
    ylim([-200, 2000])
    zlim([-200, 1800])
end

function slider_call(h,~)
    t =  ceil(get(h, 'value'));
    plotSF(t);
    for l=SFLines %#ok<FXUP>
        set(l{:}, 'XData', [t t],'YData',[-50000 50000])
    end
end
end
