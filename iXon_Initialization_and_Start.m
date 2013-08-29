% This script starts and configures the Andor iXon camera,
% so that images can be quicklt acquired with another 
% script


%% set parameters

amplificationMethod = 0;
% 0 for electron multiplying; 1 for conventional

exposureTime        = 0.022;                                	
% exposure time in s

numberKineticSeries = 2;                                
% number of images to take in kinetic series

triggerMode         = 0;
% set trigger mode; 0 for Internal; 1 for External; 6 for External Start

acquisitionMode     = 1;
% Set acquisition mode; 1 for Single Scan; 3 for Kinetic Series; 5 Run till abort

outputAmplification = 0;
% 1 for conventional; 0 for electron multiplying

readMode            = 4;
% Set read mode; 4 for Image


addpath(fullfile(matlabroot,'toolbox','Andor'))        	%   path for the .dll files
path = fullfile(matlabroot,'toolbox','Andor','Camera Files','atmcd32d.dll');




%% initialize Andor camera if it is not running
[retS, status] = AndorGetStatus();
if retS==20075                                           % 20075=DRV_NOT_INITIALIZED -> initialize it
    disp('Start Andor Camera Control');
    ret = AndorInitialize(path);
    if ret~=20002
        error('Camera could not be initialized');
    end
    gstatus = 0;
    while(gstatus ~= 20073)                             % 20073=DRV_IDLE -> wait for camera to be idle
        pause(0.1);
        [~, gstatus]=AndorGetStatus;
    end
elseif retS==20002                                       % DRV_SUCCESS
    disp('Andor Camera already initialized');
    if status==20074
        disp('camera in Temperature Cycle');
        [~, currentTemp] = GetTemperature;
        fprintf('  current temperature is: %C\n', currentTemp);
    elseif status==20072                                % camera is still acquiring something
        disp('camera is acquiring');
        ret = AbortAcquisition();
        if ret==20002
            disp('acquisition was aborted');
        else
            error('Error when aborting acquisition');
        end
    else
        error('Camera Status Error');
    end
else
    error('Error during Camera initilization');
end

gstatus = 0;
[~, gstatus] = AndorGetStatus();                        % check again that camera is ready
while(gstatus ~= 20073)                                 % 20073=DRV_IDLE -> wait for camera to be idle
    pause(0.1);
    [~, gstatus]=AndorGetStatus;
end
disp('camera is ready');

ret = FreeInternalMemory();                             % free the memory in the internal buffer of the camera
if ret~=20002
    error('Could not free memory');
end


%% Set up camera
ret = SetTriggerMode(triggerMode);                      
if ret~=20002
    error('Could not set trigger mode');
end

ret = SetAcquisitionMode(acquisitionMode);                            
if ret~=20002
    error('Could not set acquisition mode');
end

ret = SetKineticCycleTime(0);

ret = SetOutputAmplifier(outputAmplification);                            
if ret~=20002
    error('Could not set output amplifier mode');
end

if amplificationMethod==0                               % 0 for electron multiplying; 1 for conventional
    ret = SetEMCCDGain(EMCCDgain);
    if ret~=20002
        error('Could not set EMCCD gain');
    end
end

[ret,nospeeds]=GetNumberHSSpeeds(amplificationMethod,0);
if ret~=20002
    error('Could not get HS speeds');
end
ret = SetHSSpeed(amplificationMethod,0);
if ret~=20002
    error('Could not set HS speeds');
end

[ret,nospeeds]=GetNumberVSSpeeds;
ret = SetVSSpeed(nospeeds-1);

[ret, xPixels, yPixels] = GetDetector();                %   Get the CCD size
if ret~=20002
    error('Could not get CCD size');
end
numberOfPixels = xPixels*yPixels;

ret = SetImage(1,1,1,xPixels,1,yPixels);                %   set image size
if ret~=20002
    error('Could not set image dimensions');
end

ret = SetExposureTime(exposureTime);                    %   Set exposure time in second
ret = SetReadMode(readMode);                          	%   Set read mode; 4 for Image
ret = SetShutterEx(1,1,27,27,1);                       	%   Set external and internal shutter to open


%% read out and display status
disp('\n###  Current Camera Parameters  ###');

ampMethod = 'mylittleplaceholderstring';
[~, ampMethod] = GetAmpDesc(amplificationMethod, length(ampMethod));
fprintf(['Amplification Method: ' ampMethod ]);

[ret, gain] = GetEMCCDGain();
fprintf('EMCCD Gain: %fMHz\n', gain);

[ret, isCoolerOn] = IsCoolerOn();
if isCoolerOn==0
fprintf('Cooler is OFF');
elseif isCoolerOn==1
   fprintf('Cooler is ON');
else
    error('Error retrieving cooler information')
end 

[ret, currentTemp] = GetTemperatureF();
if ret==20034
    disp('Temperature is OFF');
elseif ret==20035
    disp('Temperature has stabilized');
end
  fprintf('current temperature is: %f\n',currentTemp);  
    
[ret,HSspeed] = GetHSSpeed(amplificationMethod,0,0);
fprintf('HS speed: %fMHz\n',HSspeed);

[ret,VSspeed] = GetVSSpeed(nospeeds-1);
fprintf('VS speed: %fMHz\n',VSspeed);

[ret,ExposureT,AccumulationT,KineticT] = GetAcquisitionTimings();    %   Get acquisition setting
fprintf('Acquisition Timings:\n  Exposure: %f \nAcc. Cycle Time: %f \nKinetic Cycle Time: %f \n',ExposureT,AccumulationT,KineticT);

gstatus = 0;
[~, gstatus] = AndorGetStatus();                        % check again that camera is ready
while(gstatus ~= 20073)                                 % 20073=DRV_IDLE -> wait for camera to be idle
    pause(0.1);
    [~, gstatus]=AndorGetStatus;
end
disp('** camera is idle **');


