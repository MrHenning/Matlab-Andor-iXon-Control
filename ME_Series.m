% My first program to control the iXON camera

%% some parameters
addpath(fullfile(matlabroot,'toolbox','Andor'))        	%   path for the .dll files
path = fullfile(matlabroot,'toolbox','Andor','Camera Files','atmcd32d.dll');

% amplificationMethod = 1;                          	%   1 for conventional; 0 for electron multiplying
exposureTime = 0.022;                                	%   exposure time in s
numberKineticSeries = 2;                                %   number of images to take in kinetic series

%% initialize Andor camera if it is not running
[ret, Status] = AndorGetStatus;
if ret==20075  % 20075=DRV_NOT_INITIALIZED
    disp('Start Andor Camera Control');
    returnCode = AndorInitialize(path);
    if returnCode~=20002
        disp('Camera could not be initialized');
        gstatus = 0;
        
        while(gstatus ~= 20073)                         %   20073=DRV_IDLE
            pause(0.1);
            [ret, gstatus]=AndorGetStatus;
        end
    end
elseif ret==20002
    disp('Andor Camera already initialized');
elseif ret==20072
    disp('Ending camera acquisition');
    ret = AbortAcquisition;
else
    error('Error during Camera initilization');
end

ret = FreeInternalMemory;


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

ret = SetAcquisitionMode(5);                            %   Set acquisition mode; 1 for Single Scan; 3 for Kinetic Series; 5 Run till abort
if ret~=20002
    error('Could not set acquisition mode');
end

ret = SetKineticCycleTime(0);

ret = SetOutputAmplifier(1);                            %   1 for conventional; 0 for electron multiplying
if ret~=20002
    error('Could not set output amplifier mode');
end

[ret,nospeeds]=GetNumberHSSpeeds(0,0);
if ret~=20002
    error('Could not get HS speeds');
end
ret = SetHSSpeed(0,0);
if ret~=20002
    error('Could not set HS speeds');
end
[ret,HSspeed] = GetHSSpeed(0,0,0);
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
ret = SetShutterEx(1,1,0,0,1);                          %   Set external and internal shutter to open

[ret,ExposureT,AccumulationT,KineticT]=GetAcquisitionTimings;    %   Get acquisition setting
fprintf('Acquisition Timings:\n  Exposure: %f \nAcc. Cycle Time: %f \nKinetic Cycle Time: %f \n',ExposureT,AccumulationT,KineticT);



%% wait for camera to be ready
[ret,gstatus] = AndorGetStatus;                         %   Make sure the system is at idle waiting for instruction
while(gstatus ~= 20073)                                 %   20073=DRV_IDLE
    pause(0.1);
    [ret,gstatus]=AndorGetStatus;
end

ret = StartAcquisition;                                 %   Start the acquisition
if ret~=20002
    error('Could not start acquisition');
end

% [ret, totalNumberImagesAcquired] = GetTotalNumberImagesAcquired;  %   get indeces of the images that have not been retrieved from internal camera memory yet
% if idxFirstNewImage~=1 || idxLastNewImage~=numberKineticSeries
%     disp('something went wrong with the image indexing...');
% end

ResultArray = zeros(YPixels,XPixels);
figure(1);
colormap(gray);
imagesc(ResultArray);
axis image;

FS = stoploop({'Stop me'}) ;                            % Stop Button
tic;

while ~FS.Stop()
    toc;                        % display elapsed time
    tic;
    
    [ret] = WaitForAcquisition;
    [ret, ResultArray] = GetMostRecentImage(numberOfPixels);
    if ret~=20002
        error('Could not get acquired data');
    end
    
    ResultArray = rot90(reshape(ResultArray,512,512));                %   turn data-vector into 2d array    

    imagesc(ResultArray);
    axis image;
    
%     pause(0.1);

    [ret, totalNumberImagesAcquired] = GetTotalNumberImagesAcquired;  %   get indeces of the images that have not been retrieved from internal camera memory yet
end

[ret] = WaitForAcquisition;
[ret] = AbortAcquisition;
if ret==20002
        disp('Acquisition aborted');
else
    disp('Error with aborting acquisition');
end

%% shut down camera
% pause(3);
ret = SetShutterEx(1,2,27,27,2);                        %   Set external and internal shutter to open
[ret]=AndorShutDown;








