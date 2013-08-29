% Stop and deinitialize the iXon camera

%% check camera status
[ret, status] = AndorGetStatus();                       
if ret~=20002
    error('System not initialized');
else
    if status==20072
        disp('camera is acquiring');
        ret = AbortAcquisition();
        if ret==20002
            disp('acquisition was aborted');
        else
            error('Error when aborting acquisition');
        end
        pause(1);
    elseif status==20074
        disp('camera in Temperature Cycle');
        [~, currentTemp] = GetTemperature;
        fprintf('  current temperature is: %f\n', currentTemp);
        pause(1);
    end
end


%% close shutter and stop temperature control
ret = CoolerOFF();
if ret~=20002
    error('Error switching off cooler');
end

ret = SetShutterEx(1,2,27,27,2);                       	% Set external and internal shutter to close
if ret~=20002
    error('Error closing shutter');
end

[ret, status] = AndorGetStatus();                       % check again for status
if ret~=20002
    error('System not initialized');
else
    if status~=20073
        error('camera cannot be shut down');
    end
end


%% shut down camera
pause(1);
[ret] = AndorShutDown;
disp('***  camera was shut down  ***');




