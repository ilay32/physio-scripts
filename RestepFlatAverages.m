close all; clear;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
%dataroot = uigetdir(syshelpers.driveroot());
dataroot = 'Q:\testdata\katherin-all';
groups = RestepGroups(dataroot);
%groups.regenerate_gists();
%for b=RestepGroups.export_basics
%   groups.main({'adaptation','de_adaptation'},b{:},'flat_averages');
%end
for b=RestepGroups.export_basics
    ltimes = groups.main({},b{:},'joint_symmetries');
end