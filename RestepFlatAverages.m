close all; clear;
addpath 'matclasses';
addpath 'matfunctions';
stages = {'adaptation','post_adaptation'};
dataroot = uigetdir(syshelpers.drive_root());
groups = RestepGroups(dataroot,stages);
for s=1:length(stages)
    gflat = groups.flat_averages(stages{s}) %#ok<NOPTS>
end
%gglob = groups.grouped_averages();