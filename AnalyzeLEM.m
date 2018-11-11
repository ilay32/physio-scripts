close all
clear
addpath 'matclasses';
[lemfile,path] = uigetfile('*.txt','Select LEMOCOT CSV file');
if lemfile == 0
    return
end
lma0 = LEMAnalyzer(fullfile(path,lemfile));
if ~isempty(lma0.find_others())
    lma0.showtouches_multiple();
else
    lma0 = lma0.tare();
    lma0  = lma0.identify();
    lma0.showtouches_single();
end
