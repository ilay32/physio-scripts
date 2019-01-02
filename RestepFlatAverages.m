close all; clear;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
dataroot = uigetdir(syshelpers.driveroot());
groups = RestepGroups(dataroot);
%groups.regenerate_gists();
%for b=RestepGroups.export_basics
%   groups.main({'adaptation','de_adaptation'},b{:},'flat_averages');
%end
for b=RestepGroups.export_basics
    ltimes.(b{:}) = groups.main({},b{:},'joint_symmetries');
end
groups.save_joint_learning(ltimes);