close all; clear;
addpath 'matclasses';
addpath 'matfunctions';
addpath 'yamlmatlab';
%stages = {'adaptation','post_adaptation'};
stages = {'slow','fast','adaptation','post_adaptation','re_adaptation'};
%dataroot = uigetdir(syshelpers.driveroot());
dataroot = 'Q:\testdata\katherin-all';
groups = RestepGroups(dataroot,stages);
groups.regenerate_gists();
% for s=3:4
%     for b = RestepGroups.export_basics
%         gflat = groups.main(stages{s},b{:},'flat_average') %#ok<NOPTS>
%     end
% end
for b=RestepGroups.export_basics
    ltimes = groups.main('',b{:},'joint_symmetries');
end
%gglob = groups.grouped_averages();