% My first program to control the iXON camera

%% some parameters
addpath(fullfile(matlabroot,'toolbox','Andor'))         %   path for the .dll files
path = '';%fullfile(matlabroot,'toolbox','Andor','Camera Files','atmcd32d.dll');

% amplificationMethod = 1;                                %   1 for conventional; 0 for electron multiplying
exposureTime = 0.022;                                   %   exposure time in s


%% initialize Andor camera if it is not running
[ret,Status] = AndorGetStatus;
if ret==20075  % 20075=DRV_NOT_INITIALIZED
    disp('Start Andor Camera Control');
    returnCode = AndorInitialize(path);
    if returnCode == 20002  
        disp('Camera already initialized');
        gstatus = 0;
        while(gstatus ~= 20073)                                 %   20073=DRV_IDLE
            pause(0.1);
            [ret,gstatus]=AndorGetStatus;
        end
    else
        error('Camera initialization failed');
    end
elseif ret==20002
     disp('Start Andor Camera already initialized');  
else
    error('Error during Camera initilization');
end


%% Set up camera
[ret,XPixels,YPixels]=GetDetector;                      %   Get the CCD size
if ret~=20002
    error('Could not get CCD size');
end
numberOfPixels = XPixels*YPixels;

ret = SetTriggerMode(0);                                %   Set trigger mode; 0 for Internal; 1 for External; 6 for External Start
if ret~=20002
    error('Could not set trigger mode');
end

ret = SetAcquisitionMode(1);                            %   Set acquisition mode; 1 for Single Scan
if ret~=20002
    error('Could not set acquisition mode');
end

ret = SetOutputAmplifier(1);                            %   1 for conventional; 0 for electron multiplying
if ret~=20002
    error('Could not set output amplifier mode');
end

[returnCode,nospeeds]=GetNumberHSSpeeds(0,0);
if ret~=20002
    error('Could not get HS speeds');
end
ret = SetHSSpeed(0,nospeeds-1);
if ret~=20002
    error('Could not set HS speeds');
end
[ret,HSspeed] = GetHSSpeed(0,0,nospeeds-1);
fprintf('HS speed is %fMHz\n',HSspeed);
[ret,nospeeds]=GetNumberVSSpeeds;
ret = SetVSSpeed(nospeeds-1);
[ret,VSspeed] = GetVSSpeed(nospeeds-1);
fprintf('VS speed is %fMHz\n',VSspeed);

ret = SetImage(1,1,1,XPixels,1,YPixels);                %   set image size
if ret~=20002
    error('Could not set image dimensions');
end

ret = SetExposureTime(exposureTime);                    %   Set exposure time in second
ret = SetReadMode(4);                                   %   Set read mode; 4 for Image
ret = SetShutterEx(1,1,27,27,1);                        %   Set external and internal shutter to open

[ret,Exposure,Accumulateb,Kinetic]=GetAcquisitionTimings;    %   Get acquisition setting


%% wait for camera to be ready
tic;
[ret,gstatus] = AndorGetStatus;                         %   Make sure the system is at idle waiting for instruction
while(gstatus ~= 20073)                                 %   20073=DRV_IDLE
    pause(0.1);
    [ret,gstatus]=AndorGetStatus;
end
ret = StartAcquisition;                                 %   Start the acquisition
if ret~=20002
    error('Could not start acquisition');
end
disp('waiting for trigger event');
[ret]=WaitForAcquisition;
if ret==20002
    disp('image was acquired');
end

[ret,ResultArray1]=GetAcquiredData(numberOfPixels);      %   Copy the data to the ResultArray
if ret~=20002
    error('Could not get acquired data');
end
ResultArray1=reshape(ResultArray1,512,512);               %   turn data-vector into 2d array
ResultArray1=(rot90(ResultArray1));                       %   


%% take second image
[ret,gstatus] = AndorGetStatus;                         %   Make sure the system is at idle waiting for instruction
while(gstatus ~= 20073)                                 %   20073=DRV_IDLE
    pause(0.1);
    [ret,gstatus]=AndorGetStatus;
end
ret = StartAcquisition;                                 %   Start the acquisition
if ret~=20002
    error('Could not start acquisition');
end
disp('waiting for trigger event');
[ret]=WaitForAcquisition;
if ret==20002
    disp('image was acquired');
end

[ret,ResultArray2]=GetAcquiredData(numberOfPixels);      %   Copy the data to the ResultArray
if ret~=20002
    error('Could not get acquired data');
end
ResultArray2=reshape(ResultArray2,512,512);               %   turn data-vector into 2d array
ResultArray2=(rot90(ResultArray2)); 
toc;

%% plot data
figure(1);
colormap(gray);

subplot (1,2,1);
imagesc(ResultArray1);
axis image;

subplot (1,2,2);
imagesc(ResultArray2);
axis image;


%% shut down camera
% pause(3);
ret = SetShutterEx(1,2,27,27,2);                        %   Set external and internal shutter to close
[ret]=AndorShutDown;








