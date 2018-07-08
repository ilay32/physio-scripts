[lemfile,path] = uigetfile('*.txt','Select LEMOCOT CSV file');
if lemfile == 0
    return
end
lma = LEMAnalyzer(fullfile(path,lemfile));
lma = lma.tare();
lma  = lma.identify();
touch_points = lma.validate_touches('raw');
lma.showtouches(touch_points);
