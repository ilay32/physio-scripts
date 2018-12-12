close all; clear;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
dataroot = uigetdir(syshelpers.driveroot());
groups = SaluteGroups(dataroot);
% for s=3:4
%     for b = RestepGroups.export_basics
%         gflat = groups.main(stages{s},b{:},'flat_average') %#ok<NOPTS>
%     end
% end
for b=SaluteGroups.export_basics
    ltimes = groups.main('',b{:},'joint_symmetries');
end
%gglob = groups.grouped_averages();
