close all; clear;
addpath 'matclasses';
addpath 'matfunctions';
dataroot = uigetdir(syshelpers.drive_root());
groups = RestepGroups(dataroot);
gflat = groups.flat_averages();
gglob = groups.grouped_averages();