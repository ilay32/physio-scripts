function [coeffs,cp,long_term_end] = sdf_parameters3(timeinterval,sdf,good,transition,long_term_end)
% SDF_PARAMETERS3.M	Calculates Stabilogram diffusion paramteters based upon input of SDF function
% Usage: [coeffs,cp,long_term_end] = sdf_parameters3(timeinterval,sdf,good,transition,long_term_end)
% Inputs:
% 	TIMEINTERVAL = column vector of time intervals
% 	SDF = [sdfx, sdfy] 
% 	GOOD = minimum R value acceptable for Dxl & Dyl. If the regression is worse, user is prompted to redefine long term region
%			 GOOD = 0 accepts any R value
% 	TRANSITION: Number of points to be ignored on either side of Critical Time when calculating regressions. Default = 0;
% 	LONG_TERM_END: Default end of the long term regions, in samples. Will be automatically doubled if Ct is greater.
%
% Outputs:
% 	Coeffs format
%      95%Conf   Param   95%Conf   R^2  p  Intercept
% 	Dxs
% 	Dys
% 	Drs
% 	Dxl
% 	Dyl
% 	Drl
% 	Hxs
% 	Hys
% 	Hrs
% 	Hxl
% 	Hyl
% 	Hrl
%
% 	CP Format
%    CP by loglog slope  CP by intersection
% 	Ctx
% 	Cty
% 	Ctr
% 	Cdx
% 	Cdy
% 	Cdr
% Use with stabilogram_diffusion.m
% Requires LPFILT.M
% VERSION 3     Peter Meyer 10/12/01
% Version 3.1   Peter Meyer 9/6/02- minor revisions

sampling_period = timeinterval(5,1)-timeinterval(4,1); % Determines sampling period

if nargin == 2
   good = 0;
   transition = 0;
   long_term_end =10/sampling_period; %10s
elseif nargin == 3
   good = good*good; % Convert from R to R^2
   transition = 0;
   long_term_end = 10/sampling_period; %10s
elseif nargin == 4
   good = good*good; % Convert from R to R^2
   long_term_end = 10/sampling_period; %10s
end;

long_term_end = [long_term_end long_term_end long_term_end]; % Start with the same end of long-term region for x, y, & r directions


% Calculate resultant SDF curve
sdf(:,3) = sdf(:,1)+sdf(:,2);


% Calculate derivative of log-log plots- 
   % LPFilter the sdf at 20Hz to remove HF system noise for CP determination- zero phase
   	[filt_sdf, begin]=lpfilt_new(sdf,20,1/sampling_period,1/sampling_period,'y','cheby',4); % Filter transients removed
   	filt_time = timeinterval(begin:size(timeinterval,1)-begin+1,1); % Account for removal of filter transients
            
   	A=log10(filt_sdf); % Log base 10 of filtered data
   	logtime = log10(filt_time);
   	[rows] = size(A,1); % Columns always = 3 (x & y & r)
      
           
    % Calculate slope of log-log (filtered) plot
      B = ones(rows,2)*NaN; % Initialize variable
		for column = 1:3	% Here cols = 3: X & Y & R
    		B(1,column) = ( -3*A(1,column) + 4*A(2,column) -A(3,column) ) / (2*(logtime(2)-logtime(1)));	% First Point
    		B(rows,column) = ( A(rows-2,column) - 4*A(rows-1,column) +3*A(rows,column)) / (2*(logtime(rows)-logtime(rows-1)));	% Last Point

			for row = 2:rows-1
         	    B(row,column) = ( -A(row-1,column) + A(row+1,column) ) / ((logtime(row+1)-logtime(row-1))); % Three point differentiation
      	    end;
      end;
   
      
% Determine the end of the short-time interval for X & Y &r
for column = 1:3
   
   % Initialize counter & future mean
      row =1; cont = 2; % Due to filter transient removal, row 1 = .05s, or 20Hz at sample_rate=100Hz
      
   % Find row to start with (make sure initial slope is greater than 1)
   	while ((B(row,column)) <= 1) % Skip over segments that start antipersistent
      	row = row + 1;
   	end;
    short_term_regress_begin(column) = row; 
      
      % Find where slope goes <1 and stays there
      while ((B(row,column)) >1) | any(B(row+1:row+10,column) > 1)		% Find point where slope goes <1 and stays there for an average of 10 samples
           	row = row + 1;
   	  end;
      short_term_end(column) = row;
      
  end;
   
   %figure,
   %subplot(2,1,1),loglog(timeinterval,sdf(:,1:3))
  	%title(['Slope of LogLog SDF plots']);
   %	xlabel('Time interval (Note logarithmic scaling)')
   %	ylabel('Mean Squared Displacement')
  %subplot(2,1,2), semilogx(filt_time,B(:,1:3))
   %set(gca,'YGrid','on','Xgrid','on');
   %ylim([0 2]);
   %	xlabel('Time interval (Note linear scaling)')
   %  ylabel('First Derivative of Mean Squared Displacement')
     %print
   %  disp(num2str(short_term_end))
   %pause
   %close
   
   
   % Check for error
   if any(short_term_end == 1)
      error('Error: SD Function exhibits antipersistence at start!')
   end;
   
   %Adjust the critical time to the unfiltered time axis
   short_term_end = short_term_end + begin-1;
   short_term_regress_end = short_term_end - transition;
   short_term_regress_begin = short_term_regress_begin + begin-1;
   
   % Set end of Long term region for calculation of slopes
   long_term_regress_begin = short_term_end + transition + 1;
   disp(['Short term ' num2str(short_term_regress_begin*sampling_period) ' to ' num2str(short_term_regress_end*sampling_period) 's, Long Term ' num2str(long_term_regress_begin*sampling_period) ' to ' num2str(long_term_end*sampling_period) 's.']);
   
   % Check for error
   for i = 1:3
      if long_term_end(i) <=long_term_regress_begin(i)-10 % If there is are <= 10 samples in long term region, double its size
         figure, subplot(2,1,1),loglog(timeinterval,sdf(:,i))
         subplot(2,1,2), plot(filt_time,B(:,i))
         title(['Error in identification of critical time- dimension ' num2str(i) ]);
         long_term_end(i) = long_term_end(i) *2;	% Extend long term region to 20s in cases where ST region is greater than 10s
         disp(['Error in identification of critical time- dimension ' num2str(i) '. Extending to ' num2str(long_term_end(i)*sampling_period) 's.']);
      end;
   end;
      
   % Redefine A and LOGTIME to unfiltered signal
   clear A logtime
   A=log10(sdf);
   logtime = log10(timeinterval);
   [rows,cols] = size(A);
   
   % Calc linear regression coeffs
   %[B,BINT,R,RINT,STATS] = REGRESS(y,X,alpha) 
   [myDxs,myDxs_int,junk,crap,myDxs_stats] = regress(sdf(short_term_regress_begin(1):short_term_regress_end(1),1),[timeinterval(short_term_regress_begin(1):short_term_regress_end(1)) ones(short_term_regress_end(1)-short_term_regress_begin(1)+1,1)],.05);		% Linear Regression w/95% confidence limits
   [myDys,myDys_int,junk,crap,myDys_stats] = regress(sdf(short_term_regress_begin(2):short_term_regress_end(2),2),[timeinterval(short_term_regress_begin(2):short_term_regress_end(2)) ones(short_term_regress_end(2)-short_term_regress_begin(2)+1,1)],.05);
   [myDrs,myDrs_int,junk,crap,myDrs_stats] = regress(sdf(short_term_regress_begin(3):short_term_regress_end(3),3),[timeinterval(short_term_regress_begin(3):short_term_regress_end(3)) ones(short_term_regress_end(3)-short_term_regress_begin(3)+1,1)],.05);
   
   [myDxl,myDxl_int,junk,crap,myDxl_stats] = regress(sdf(long_term_regress_begin(1):long_term_end(1),1),[timeinterval(long_term_regress_begin(1):long_term_end(1)) ones(long_term_end(1)-long_term_regress_begin(1)+1,1)],.05);
   [myDyl,myDyl_int,junk,crap,myDyl_stats] = regress(sdf(long_term_regress_begin(2):long_term_end(2),2),[timeinterval(long_term_regress_begin(2):long_term_end(2)) ones(long_term_end(2)-long_term_regress_begin(2)+1,1)],.05);
   [myDrl,myDrl_int,junk,crap,myDrl_stats] = regress(sdf(long_term_regress_begin(3):long_term_end(3),3),[timeinterval(long_term_regress_begin(3):long_term_end(3)) ones(long_term_end(3)-long_term_regress_begin(3)+1,1)],.05);

   [myHxs,myHxs_int,junk,crap,myHxs_stats] = regress(A(short_term_regress_begin(1):short_term_regress_end(1),1),[logtime(short_term_regress_begin(1):short_term_regress_end(1)) ones(short_term_regress_end(1)-short_term_regress_begin(1)+1,1)],.05);			% Linear Regression w/95% confidence limits
   [myHys,myHys_int,junk,crap,myHys_stats] = regress(A(short_term_regress_begin(2):short_term_regress_end(2),2),[logtime(short_term_regress_begin(2):short_term_regress_end(2)) ones(short_term_regress_end(2)-short_term_regress_begin(2)+1,1)],.05);
   [myHrs,myHrs_int,junk,crap,myHrs_stats] = regress(A(short_term_regress_begin(3):short_term_regress_end(3),3),[logtime(short_term_regress_begin(3):short_term_regress_end(3)) ones(short_term_regress_end(3)-short_term_regress_begin(3)+1,1)],.05);
   
   [myHxl,myHxl_int,junk,crap,myHxl_stats] = regress(A(long_term_regress_begin(1):long_term_end(1),1),[logtime(long_term_regress_begin(1):long_term_end(1)) ones(long_term_end(1)-long_term_regress_begin(1)+1,1)],.05);
   [myHyl,myHyl_int,junk,crap,myHyl_stats] = regress(A(long_term_regress_begin(2):long_term_end(2),2),[logtime(long_term_regress_begin(2):long_term_end(2)) ones(long_term_end(2)-long_term_regress_begin(2)+1,1)],.05);
   [myHrl,myHrl_int,junk,crap,myHrl_stats] = regress(A(long_term_regress_begin(3):long_term_end(3),3),[logtime(long_term_regress_begin(3):long_term_end(3)) ones(long_term_end(3)-long_term_regress_begin(3)+1,1)],.05);
   
   if good ~= 0 % Check long term region for good fit of regression
      if myDxl_stats(1,1) < good		% .7225 Corresponds to r=.85
      	
      	    disp(['Check end of long term region- r2 is only ' num2str(myDxl_stats(1,1))]);
      	    figure
      		    plot(sdf(:,1))
         	    title('SDF Function: X direction');
         	    xlabel('Time Interval (s)');
         	    ylabel('Mean Squared Displacement (mm^2)');
         
      	        long_term_end = input([num2str(long_term_end) ' does not work for X. Long term region goes from ' num2str(short_term_end(1)) ' to: ']);
      	        [myDxl,myDxl_int,junk,crap,myDxl_stats] = regress(sdf(long_term_regress_begin(1):long_term_end(1),1),[timeinterval(long_term_regress_begin(1):long_term_end(1)) ones(long_term_end(1)-long_term_regress_begin(1)+1,1)],.05);
   		        [myHxl,myHxl_int,junk,crap,myHxl_stats] = regress(A(long_term_regress_begin(1):long_term_end(1),1),[logtime(long_term_regress_begin(1):long_term_end(1)) ones(long_term_end(1)-long_term_regress_begin(1)+1,1)],.05);
      	    disp(['New r2 is ' num2str(myDxl_stats(1,1))]);
   	end;
   
   	if myDyl_stats(1,1) < good    % .7225 Corresponds to r=.85
      	
      	disp(['Check end of long term region- r2 is only ' num2str(myDyl_stats(1,1))]);
     		figure
      		    plot(sdf(:,2))
         	    title('SDF Function: Y direction');
         	    xlabel('Time Interval (s)');
        	    ylabel('Mean Squared Displacement (mm^2)');
         
      	        long_term_end = input([num2str(long_term_end) ' does not work for Y. Long term region goes from ' num2str(short_term_end(2)) ' to: ']);
      	        [myDyl,myDyl_int,junk,crap,myDyl_stats] = regress(sdf(long_term_regress_begin(2):long_term_end(2),2),[timeinterval(long_term_regress_begin(2):long_term_end(2)) ones(long_term_end(2)-long_term_regress_begin(2)+1,1)],.05);
   		        [myHyl,myHyl_int,junk,crap,myHyl_stats] = regress(A(long_term_regress_begin(2):long_term_end(2),2),[logtime(long_term_regress_begin(2):long_term_end(2)) ones(long_term_end(2)-long_term_regress_begin(2)+1,1)],.05);
   		disp(['New r2 is ' num2str(myDyl_stats(1,1))]);
    end;
      
    if myDrl_stats(1,1) < good    % .7225 Corresponds to r=.85
      	
      	disp(['Check end of long term region- r2 is only ' num2str(myDrl_stats(1,1))]);
     		figure
      		plot(sdf(:,3))
         	title('SDF Function: R direction');
         	xlabel('Time Interval (s)');
        	ylabel('Mean Squared Displacement (mm^2)');
         
      	    long_term_end = input([num2str(long_term_end) ' does not work for R. Long term region goes from ' num2str(short_term_end(3)) ' to: ']);
      	    [myDrl,myDrl_int,junk,crap,myDrl_stats] = regress(sdf(long_term_regress_begin(3):long_term_end(3),3),[timeinterval(long_term_regress_begin(3):long_term_end(3)) ones(long_term_end(3)-long_term_regress_begin(3)+1,1)],.05);
			[myHrl,myHrl_int,junk,crap,myHrl_stats] = regress(A(long_term_regress_begin(3):long_term_end(3),3),[logtime(long_term_regress_begin(3):long_term_end(3)) ones(long_term_end(3)-long_term_regress_begin(3)+1,1)],.05);
   		disp(['New r2 is ' num2str(myDyl_stats(1,1))]);
      end;

   end;
   
   
   
   % Critical Point by two methods
        % Intersection method ala Collins & De Luca ("critical Point")
        intersectCtx = (myDxl(2,1) - myDxs(2,1))/(myDxs(1,1) - myDxl(1,1));
        intersectCty = (myDyl(2,1) - myDys(2,1))/(myDys(1,1) - myDyl(1,1));
        intersectCtr = (myDrl(2,1) - myDrs(2,1))/(myDrs(1,1) - myDrl(1,1));
        intersectCdx = myDxs(1,1)*intersectCtx + myDxs(2,1);
        intersectCdy = myDys(1,1)*intersectCty + myDys(2,1);
        intersectCdr = myDrs(1,1)*intersectCtr + myDrs(2,1);
        
        % End of short-term region ("transition point")
        myCtx = short_term_end(1) * sampling_period;  	
        myCty = short_term_end(2) * sampling_period; 
        myCtr = short_term_end(3) * sampling_period;
        myCdx = sdf(short_term_end(1),1);
        myCdy = sdf(short_term_end(2),2);
        myCdr = sdf(short_term_end(3),3);
   
      
   %Scale D & H by 1/2
   	myDxs(1,1) = .5*myDxs(1,1);
      myDys(1,1) = .5*myDys(1,1);
      myDrs(1,1) = .5*myDrs(1,1);
   	myDxl(1,1) = .5*myDxl(1,1);
      myDyl(1,1) = .5*myDyl(1,1);
      myDrl(1,1) = .5*myDrl(1,1);
   	myDxs_int(1,:) = .5*myDxs_int(1,:);
      myDys_int(1,:) = .5*myDys_int(1,:);
      myDrs_int(1,:) = .5*myDrs_int(1,:);
   	myDxl_int(1,:) = .5*myDxl_int(1,:);
      myDyl_int(1,:) = .5*myDyl_int(1,:);
      myDrl_int(1,:) = .5*myDrl_int(1,:);
   	myHxs(1,1) = .5*myHxs(1,1);
      myHys(1,1) = .5*myHys(1,1);
      myHrs(1,1) = .5*myHrs(1,1);
   	myHxl(1,1) = .5*myHxl(1,1);
      myHyl(1,1) = .5*myHyl(1,1);
      myHrl(1,1) = .5*myHrl(1,1);
   	myHxs_int(1,:) = .5*myHxs_int(1,:);
      myHys_int(1,:) = .5*myHys_int(1,:);
      myHrs_int(1,:) = .5*myHrs_int(1,:);
   	myHxl_int(1,:) = .5*myHxl_int(1,:);
   	myHyl_int(1,:) = .5*myHyl_int(1,:);
		myHrl_int(1,:) = .5*myHrl_int(1,:);
	     
    % Store the parameters for comparison
    %                95% Conf       Param        95% Conf       R^2            p           Intercept
    coeffs(1,:) = [myDxs_int(1,2) myDxs(1,1) myDxs_int(1,1) myDxs_stats(1) myDxs_stats(3) myDxs(2,1)];
	coeffs(2,:) = [myDys_int(1,2) myDys(1,1) myDys_int(1,1) myDys_stats(1) myDys_stats(3) myDys(2,1)];
    coeffs(3,:) = [myDrs_int(1,2) myDrs(1,1) myDrs_int(1,1) myDrs_stats(1) myDrs_stats(3) myDrs(2,1)];
    coeffs(4,:) = [myDxl_int(1,2) myDxl(1,1) myDxl_int(1,1) myDxl_stats(1) myDxl_stats(3) myDxl(2,1)];
	coeffs(5,:) = [myDyl_int(1,2) myDyl(1,1) myDyl_int(1,1) myDyl_stats(1) myDyl_stats(3) myDyl(2,1)];
    coeffs(6,:) = [myDrl_int(1,2) myDrl(1,1) myDrl_int(1,1) myDrl_stats(1) myDrl_stats(3) myDrl(2,1)];
    coeffs(7,:) = [myHxs_int(1,2) myHxs(1,1) myHxs_int(1,1) myHxs_stats(1) myHxs_stats(3) myHxs(2,1)];
	coeffs(8,:) = [myHys_int(1,2) myHys(1,1) myHys_int(1,1) myHys_stats(1) myHys_stats(3) myHys(2,1)];
    coeffs(9,:) = [myHrs_int(1,2) myHrs(1,1) myHrs_int(1,1) myHrs_stats(1) myHrs_stats(3) myHrs(2,1)];
    coeffs(10,:) = [myHxl_int(1,2) myHxl(1,1) myHxl_int(1,1) myHxl_stats(1) myHxl_stats(3) myHxl(2,1)];
	coeffs(11,:) = [myHyl_int(1,2) myHyl(1,1) myHyl_int(1,1) myHyl_stats(1) myHyl_stats(3) myHyl(2,1)];
    coeffs(12,:) = [myHrl_int(1,2) myHrl(1,1) myHrl_int(1,1) myHrl_stats(1) myHrl_stats(3) myHrl(2,1)];
    
        % Coeffs format
        %      95%Conf   Param   95%Conf   R^2  p  Intercept
        % Dxs
        % Dys
        % Drs
        % Dxl
        % Dyl
        % Drl
        % Hxs
        % Hys
        % Hrs
        % Hxl
        % Hyl
        % Hrl
      
    % CP by loglog slope  CP by intersection
		cp(1,:) = [myCtx intersectCtx];
		cp(2,:) = [myCty intersectCty];
		cp(3,:) = [myCtr intersectCtr];
   	    cp(4,:) = [myCdx intersectCdx];
		cp(5,:) = [myCdy intersectCdy];
		cp(6,:) = [myCdr intersectCdr];
   
        % CP Format
        %    CP by loglog slope  CP by intersection
        % Ctx
        % Cty
        % Ctr
		% Cdx
		% Cdy
		% Cdr