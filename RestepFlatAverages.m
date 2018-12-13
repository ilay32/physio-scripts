close all; clear;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
%dataroot = uigetdir(syshelpers.driveroot());
dataroot = 'Q:\testdata\katherin-all';
groups = RestepGroups(dataroot);
gflats = struct;
for s=3:4
    for b = RestepGroups.export_basics
        gflats.(b{:}) = groups.main(s,b{:},'flat_averages') %#ok<NOPTS>
    end
end
% for b=RestepGroups.export_basics
%     ltimes = groups.main('',b{:},'joint_symmetries');
% end