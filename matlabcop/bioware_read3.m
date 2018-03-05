function [cop_net,forces,sample_rate]= bioware_read3(filename,filtcop,dist)
% BIOWARE_READ3		Reads COP data from Bioware generated binary file 
% Usage: [cop_net,forces,sample_rate] = bioware_read3(filename,filtcop,dist)
%			Output format for cop_net is [COPx COPy]
%			Output format for (raw) forces(:,16) is Fx1,Fy1,Fz1,Mx1,My1,Mz1,Copx1,Copy1,Fx2,Fy2,Fz2,Mx2,My2,Mz2,Copx2,Copy2
%	  		If filtcop = 1, Data is filtered by 4th Order Zero Phase Butterworth Filter, 15Hz
%			If 2 plates are used, dist is the distance between the center of plate 1 & center of plate 2 in x-direction.
%			(Tandem placement assumed)
%			Assumes No auxillary data channels are used.
% 
% Version 3.0 Peter Meyer 10/26/01: Provides net COP from 2 forceplates
% Version 3.2 Peter Meyer 04/12/02: Substitutes NaN's for COP's greater than forceplate size.
%												(Assumes Kistler 9284, 500mm x 500mm)
% Version 3.3 Peter Meyer 9/5/02: Provides sampling rate as output. Filter option no longer assumes 100Hz

warning off

	fid = fopen(filename,'r');
	fread(fid,80,'uchar'); % File title header
	fread(fid,14,'uchar'); % Time
	fread(fid,14,'uchar'); % Date
	fread(fid,31,'uchar'); % patient name
	fread(fid,31,'uchar'); % patient ID
	fread(fid,51,'uchar'); % Trial description 1
	fread(fid,51,'uchar'); % Trial description 2
	sample_rate = fread(fid,1,'float32'); % Sample rate
	sample_time = fread(fid,1,'float32'); % Sample time
	fread(fid,1,'int16'); % # A/D channels
	num_plates = fread(fid,1,'int16'); % # Force Plates
	fread(fid,1,'float32'); % Plate 1 width
	fread(fid,1,'float32'); % Plate 2 width
	fread(fid,1,'float32'); % Plate 1 length
	fread(fid,1,'float32'); % Plate 2 length
	plate1_a = fread(fid,1,'float32')* 10; % Plate 1 a in mm!
	plate2_a = fread(fid,1,'float32')* 10; % Plate 2 a
	plate1_b = fread(fid,1,'float32')* 10; % Plate 1 b in mm!
	plate2_b = fread(fid,1,'float32')* 10; % Plate 2 b
	plate1_Az = fread(fid,1,'float32')* 10; % Plate 1 Az in mm!
	plate2_Az = fread(fid,1,'float32') * 10; % Plate 2 Az
	plate1_X_sensitivity = fread(fid,1,'float32'); % Plate 1 X sensitivity
	plate2_X_sensitivity = fread(fid,1,'float32'); % Plate 2 X sensitivity
	plate1_Y_sensitivity = fread(fid,1,'float32'); % Plate 1 Y sens
	plate2_Y_sensitivity = fread(fid,1,'float32'); % Plate 2 Y sens
	plate1_Z_sensitivity = fread(fid,1,'float32'); % Plate 1 Z sens
	plate2_Z_sensitivity = fread(fid,1,'float32'); % Plate 2 Z sens
	fread(fid,1,'int16'); % data taken in reverse
	chargeamp1_XY_range = fread(fid,1,'float32'); % ChargeAmp1 XY range
	chargeamp2_XY_range = fread(fid,1,'float32'); % ChargeAmp2 XY range
	chargeamp1_Z_range = fread(fid,1,'float32'); % ChargeAmp1 Z range
	chargeamp2_Z_range = fread(fid,1,'float32'); % ChargeAmp2 Z range
	fread(fid,1,'uchar'); % Aux device 1 enabled
	fread(fid,1,'uchar'); % Aux device 2 enabled
	fread(fid,1,'uchar'); % Aux device 3 enabled
	fread(fid,1,'uchar'); % Aux device 4 enabled
	fread(fid,1,'uchar'); % Aux device 5 enabled
	fread(fid,1,'uchar'); % Aux device 6 enabled
	fread(fid,1,'uchar'); % Aux device 7 enabled
	fread(fid,1,'uchar'); % Aux device 8 enabled
	fread(fid,1,'float32'); % Aux device 1 MU
	fread(fid,1,'float32'); % Aux device 2 MU
	fread(fid,1,'float32'); % Aux device 3 MU
	fread(fid,1,'float32'); % Aux device 4 MU
	fread(fid,1,'float32'); % Aux device 5 MU
	fread(fid,1,'float32'); % Aux device 6 MU
	fread(fid,1,'float32'); % Aux device 7 MU
	fread(fid,1,'float32'); % Aux device 8 MU
	fread(fid,10,'uchar'); % Aux device 1 label
	fread(fid,40,'uchar'); % Aux device 1 title 
	fread(fid,10,'uchar'); % Aux device 2 label
	fread(fid,40,'uchar'); % Aux device 2 title
	fread(fid,10,'uchar'); % Aux device 3 label
	fread(fid,40,'uchar'); % Aux device 3 title
	fread(fid,10,'uchar'); % Aux device 4 label
	fread(fid,40,'uchar'); % Aux device 4 title
	fread(fid,10,'uchar'); % Aux device 5 label
	fread(fid,40,'uchar'); % Aux device 5 title
	fread(fid,10,'uchar'); % Aux device 6 label
	fread(fid,40,'uchar'); % Aux device 6 title
	fread(fid,10,'uchar'); % Aux device 7 label
	fread(fid,40,'uchar'); % Aux device 7 title
	fread(fid,10,'uchar'); % Aux device 8 label
	fread(fid,40,'uchar'); % Aux device 8 title
	rawdata = fread(fid,[(num_plates * 8),inf],'int16'); % Read in data from 1 or 2 plates w/o aux devices
	rawdata = rawdata'; % Fx12 Fx34 Fy14 Fy23 Fz1 Fz2 Fz3 Fz4	 
	fclose(fid);
	%disp('Data read');
   
    
   if (num_plates == 1)
	% Convert rawdata from bits to newtons
		rawdata(:,1:2) = -rawdata(:,1:2) * .004882 * (chargeamp1_XY_range)/plate1_X_sensitivity;
		rawdata(:,3:4) = -rawdata(:,3:4) * .004882 * (chargeamp1_XY_range)/plate1_Y_sensitivity;
		rawdata(:,5:8) = -rawdata(:,5:8) * .004882 * (chargeamp1_Z_range)/plate1_Z_sensitivity;
		%disp('Data in newtons');

	% Convert to reduced data in N, Nmm, and mm
		reduced(:,1) = rawdata(:,1) + rawdata(:,2); % Fx
		reduced(:,2) = rawdata(:,3) + rawdata(:,4); % Fy
		reduced(:,3) = rawdata(:,5) + rawdata(:,6) + rawdata(:,7) + rawdata(:,8); % Fz
		reduced(:,4) = plate1_b*(rawdata(:,5) + rawdata(:,6) - rawdata(:,7) - rawdata(:,8)); % Mx
		reduced(:,5) = plate1_a*(-rawdata(:,5) + rawdata(:,6) + rawdata(:,7) - rawdata(:,8)); % My
		reduced(:,6) = plate1_b*(-rawdata(:,1) + rawdata(:,2)) - plate1_a*(rawdata(:,3) - rawdata(:,4)); % Mz
		reduced(:,7) = (reduced(:,1)*plate1_Az - reduced(:,5))./reduced(:,3); % COPx
      reduced(:,8) = (reduced(:,2)*plate1_Az + reduced(:,4))./reduced(:,3); % COPy
      reduced(:,9:16) = zeros(size(reduced)); % Zeros for 2nd force plate
      
      reduced(find(abs(reduced(:,7))>250),7) = nan; % Eliminate any COP values greater than the forceplate
      reduced(find(abs(reduced(:,8))>250),8) = nan;
      
      cop_net(:,1:2) = reduced(:,7:8);
      
   elseif (num_plates == 2)
	% Convert rawdata from bits to newtons
      rawdata(:,1:2) = -rawdata(:,1:2) * .004882 * (chargeamp1_XY_range)/plate1_X_sensitivity;
		rawdata(:,3:4) = -rawdata(:,3:4) * .004882 * (chargeamp1_XY_range)/plate1_Y_sensitivity;
      rawdata(:,5:8) = -rawdata(:,5:8) * .004882 * (chargeamp1_Z_range)/plate1_Z_sensitivity;
      rawdata(:,9:10) = -rawdata(:,9:10) * .004882 * (chargeamp2_XY_range)/plate2_X_sensitivity;
		rawdata(:,11:12) = -rawdata(:,11:12) * .004882 * (chargeamp2_XY_range)/plate2_Y_sensitivity;
      rawdata(:,13:16) = -rawdata(:,13:16) * .004882 * (chargeamp2_Z_range)/plate2_Z_sensitivity;
	% Convert to reduced data in N, Nmm, and mm
		reduced(:,1) = rawdata(:,1) + rawdata(:,2); % Fx
		reduced(:,2) = rawdata(:,3) + rawdata(:,4); % Fy
		reduced(:,3) = rawdata(:,5) + rawdata(:,6) + rawdata(:,7) + rawdata(:,8); % Fz
		reduced(:,4) = plate1_b*(rawdata(:,5) + rawdata(:,6) - rawdata(:,7) - rawdata(:,8)); % Mx
		reduced(:,5) = plate1_a*(-rawdata(:,5) + rawdata(:,6) + rawdata(:,7) - rawdata(:,8)); % My
		reduced(:,6) = plate1_b*(-rawdata(:,1) + rawdata(:,2)) - plate1_a*(rawdata(:,3) - rawdata(:,4)); % Mz
		reduced(:,7) = (reduced(:,1)*plate1_Az - reduced(:,5))./reduced(:,3); % COPx
      reduced(:,8) = (reduced(:,2)*plate1_Az + reduced(:,4))./reduced(:,3); % COPy
      reduced(:,9) = rawdata(:,9) + rawdata(:,10); % Fx2
		reduced(:,10) = rawdata(:,11) + rawdata(:,12); % Fy2
		reduced(:,11) = rawdata(:,13) + rawdata(:,14) + rawdata(:,15) + rawdata(:,16); % Fz2
		reduced(:,12) = plate2_b*(rawdata(:,13) + rawdata(:,14) - rawdata(:,15) - rawdata(:,16)); % Mx2
		reduced(:,13) = plate2_a*(-rawdata(:,13) + rawdata(:,14) + rawdata(:,15) - rawdata(:,16)); % My2
		reduced(:,14) = plate2_b*(-rawdata(:,9) + rawdata(:,10)) - plate2_a*(rawdata(:,11) - rawdata(:,12)); % Mz2
		reduced(:,15) = (reduced(:,9)*plate2_Az - reduced(:,13))./reduced(:,11); % COPx2
      reduced(:,16) = (reduced(:,10)*plate2_Az + reduced(:,12))./reduced(:,11); % COPy2
      
      % Adjust meaningless values of COP (>250mm)
      % Set COP(COP>250) to zero for purposes of calculating net COP
      	weight = ones(size(reduced,1),4);
      	weight(reduced(:,[7:8 15:16])>250) = 0; % Will be used to eliminate whole term if COP is >250
        adj_COP = reduced(:,[7:8 15:16]);		 % temporarily sets COP>250 to 0 so that whole term can be made 0
      	adj_COP(abs(adj_COP)>250) = 0;
      % Set COP(COP>250) to nan for purposes of saving individual COPs from each forceplate
         reduced(find(abs(reduced(:,7))>250),7) = nan; % Eliminate any COP values greater than the forceplate
         reduced(find(abs(reduced(:,8))>250),8) = nan;  % Eliminate any COP values greater than the forceplate
         reduced(find(abs(reduced(:,15))>250),15) = nan; % Eliminate any COP values greater than the forceplate
         reduced(find(abs(reduced(:,16))>250),16) = nan; % Eliminate any COP values greater than the forceplate
         
         
      % COPx = weight*(-dist/2 + COPx1)*Fz1  + weight*(dist/2 + COPx2)*Fz2) /(Fz1+Fz2);
      cop_net(:,1) = weight(:,1).*((-dist/2 + adj_COP(:,1)).*reduced(:,3)  + weight(:,3).*(dist/2 + adj_COP(:,3)).*reduced(:,11))./(reduced(:,3)+reduced(:,11));
      cop_net(:,2) = ((adj_COP(:,2)).*reduced(:,3)  + (adj_COP(:,4)).*reduced(:,11))./(reduced(:,3)+reduced(:,11));
  end
   

   	
   % Filter the data at 15Hz, 4th order zero phase
   if exist('filtcop') == 1 & filtcop == 1
      forces = lpfilt(reduced,15,sample_rate,sample_rate,'n','butter',2);
      cop_net = lpfilt(cop_net,15,sample_rate,sample_rate,'n','butter',2);
      disp('Data lp filtered at 15Hz')
  else
      forces = reduced;   
  end
   
   % Check output
   
   %figure
   %plot(forces(:,7)+255,forces(:,8),'b')
   %hold on,
   %plot(forces(:,15)-255,forces(:,16),'r');
   %hold on,
   %plot(cop_net(:,1),cop_net(:,2),'m');
   %axis equal  
   %set(gca,'Xdir','reverse');
   
   
   %figure
   %subplot(1,3,1)
   %plot(forces(:,7),forces(:,8),'b')
   %set(gca,'Xdir','reverse');
   %subplot(1,3,2)
   %plot(cop_net(:,1),cop_net(:,2),'m');
   %set(gca,'Xdir','reverse');
   %subplot(1,3,3)
   %plot(forces(:,15),forces(:,16),'r');
   %set(gca,'Xdir','reverse');
   
   %figure,
   %subplot(4,1,1)
   %plot(forces(:,3),'b'), hold on, plot(forces(:,11),'r');
   %ylabel('Vert F');
   %subplot(4,1,2)
   %plot(forces(:,7),'b')
   %ylabel('LFoot');
   %subplot(4,1,3)
   %plot(forces(:,15),'r');
   %ylabel('RFoot');
   %subplot(4,1,4)
   %plot(cop_net(:,1),'m');
   
   %pause
   