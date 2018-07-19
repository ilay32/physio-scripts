close all
clear
[lemfile,path] = uigetfile('*.txt','Select LEMOCOT CSV file');
if lemfile == 0
    return
end
lma = LEMAnalyzer(fullfile(path,lemfile));
lma = lma.tare();
lma  = lma.identify();
touch_points = lma.validate_touches('raw');
lma.showtouches(touch_points);
fprintf('counted %d touches on the near side, %d on the far side, and %d invalid\n',...
    length(touch_points.near),length(touch_points.far),length(touch_points.out));
