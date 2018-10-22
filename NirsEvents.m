%NIRSEVENT.m Order data by Events
% input: .nirs file with events and processed data and writes an excel file
% to disk, with the data divided by found events.
clear; close all;
addpath 'matclasses';
% let the user choose a file
[file,path,~] = uigetfile([syshelpers.driveroot() '/*.nirs']);
nor = NirsOrderer(path,file);
nor = nor.learn_events();
nor.plotevents();
nor.export_walks();


  
