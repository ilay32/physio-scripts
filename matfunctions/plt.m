function plt(f,s)
    clear d
    if nargin == 1
        s = 52000;
    end
    figure;
    d = importdata(f,',',s);
    bmp = d.data(:,end-2:end);
    plot(bmp);
    hold on;
    ank = d.data(:,93:95);
    plot(ank);
    legend('bmpx','bmpy','bmpz','ankx','anky','ankz');
    grid on;
    hold off;
end