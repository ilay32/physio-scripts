
%SUBJECTANALYSIS wrapper script for analyzing step length data
%   First, it (optionally) prompts the user to mark the walking stages
%   With the stages, it finds step lengths and computes step symmetry
%   accordingly
clear; clc; close all;
addpath 'matclasses';
addpath 'matfunctions';

% construct a QualySubject instance by file and part
[datfile,path] = uigetfile('*.mat', 'Select data file');

if datfile == 0
   error('No log file specified'); 
end
part = input('which part to process? ');
qs = QualySubject(datfile,path,part);

% find boundaries and collect data
qs = qs.mark_stages();
% I put this here to make sure that the user looks at the plotted
% boundaries even in the load from file case

qs = qs.find_gait_events();
qs = qs.compile_stages();

% visualize symmetries and compute learning data
qs = qs.get_visualizer();


plotseparate = input('\n\nplot per-stage graphs [y/n]? ','s');
if strcmp(plotseparate,'y')
    for s=1:QualySubject.numstages
        qs.visu.plot_symmetries(s);
    end
end
ltimes = qs.visu.plot_global(true);

% write stuff down
qs.save_step_lengths();
qs.export_learning_data(ltimes);


