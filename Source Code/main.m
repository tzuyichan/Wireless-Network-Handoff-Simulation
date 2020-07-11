clear; clc; close all;

tic  %... start timer
simDuration = 1800;  %... unit in sec (actually simDuration = 86400 but sim takes a long time)
T = 1:1:simDuration;

% initialize (x, y) coordinates for car entry positions 1~12 (see Problem_Discription_Labeling_Convention.jpg)
Init_Coors = [750, 750, 1] .* [0, 1, 2; 0, 2, 2; 0, 3, 2;
                               1, 4, 3; 2, 4, 3; 3, 4, 3;
                               4, 3, 4; 4, 2, 4; 4, 1, 4;
                               3, 0, 1; 2, 0, 1; 1, 0, 1;];  %... clockwise assignment

nCar = 0;  %... current number of cars in the system
nHandoffArray = zeros(86400, 4);  %... accumulated number of handoffs per method (best, threshold, entropy, my)
Psum = zeros(86400, 5);  %... sum of signal power per second per method (best, threshold, entropy, my)
nXBoundHandoff = 0;  %... number of handoffs from cars that exited the system this sec
for t=1:length(T)
% 1. Add new cars
    nNew = 0;  %... number of new cars added this sec
    for i=1:length(Init_Coors)
        if poissonGenerateCar
            nCar = nCar + 1;
            nNew = nNew + 1;
            CarRoster(nCar) = CCar(Init_Coors(i,1), Init_Coors(i,2), Init_Coors(i,3));
        else
            continue
        end
    end

    if nCar > 0
% 2. Drive cars forward one step
        stepDrive(CarRoster);
        
% 3. Get number of handoffs from cars that exited the system (went off-bounds) during this sec
        nXBoundHandoff = getNXBoundHandoff(CarRoster, nXBoundHandoff);
        
% 4. Remove car if car exited system
        CarRoster = isInbounds(CarRoster);
        nCar = numel(CarRoster);
        
% 5. Perform handoff methods
        bestSigMethod(CarRoster);
        thresholdMethod(CarRoster);
        entropyMethod(CarRoster);
        myMethod(CarRoster);
        
% Plot simulation (Optional)
        plotCCar(CarRoster, nCar, "my");  %... 3rd parameter 'method' = 'best', 'threshold', 'entropy', 'my'
        pause(0.01);
    end
    
% 6. Tally accumulated number of handoffs up to t sec
    if nCar == 0
        nHandoffArray(t,:) = 0;
    else
        nHandoffArray(t,:) = tallyHandoff(CarRoster, nXBoundHandoff);
    end
    
% 7. Record sum of signal power at t sec
    if nCar == 0
        Psum(t,:) = 0;
    else
        Psum(t,:) = getPsumPerSec(CarRoster);
    end
    
end

% 8. Calculate average signal power per day per method (best, threshold, entropy, my)
Pavg = sum(Psum(:,2:5)) / sum(Psum(:,1));

toc  %... end timer



%% plot

figure
grid on; hold on;
% best relative signal
lgn_txt = sprintf('Best, Pavg = %.3f dBm', Pavg(1));
plot(T, nHandoffArray(1:length(T), 1), 'DisplayName',lgn_txt, 'LineWidth',0.75);
% threshold
lgn_txt = sprintf('Threshold, Pavg = %.3f dBm', Pavg(2));
plot(T, nHandoffArray(1:length(T), 2), 'DisplayName',lgn_txt, 'LineWidth',0.75);
% entropy
lgn_txt = sprintf('Entropy, Pavg = %.3f dBm', Pavg(3));
plot(T, nHandoffArray(1:length(T), 3), 'DisplayName',lgn_txt, 'LineWidth',0.75);
% my (threshold distance)
lgn_txt = sprintf('Mine, Pavg = %.3f dBm', Pavg(4));
plot(T, nHandoffArray(1:length(T), 4), 'DisplayName',lgn_txt, 'LineWidth',0.75);

lgn = legend; lgn.FontSize = 16;
xlabel('Time (Sec)', 'FontSize',16);
ylabel('Number of Handoffs', 'FontSize',16);



%% functions

% Simulate next step for every car
function stepDrive(ObjArray)
    for i=1:numel(ObjArray)
        ObjArray(i).stepDrive;
    end
end

% Get number of handoffs from the cars that exited the system during this sec
function new_nXBoundHandoff = getNXBoundHandoff(ObjArray, nXBoundHandoff)
    car_num = numel(ObjArray);
    nXBoundHandoffThisSec = 0;
    for i=car_num:-1:1
        if ObjArray(i).status == 0
            nXBoundHandoffThisSec = nXBoundHandoffThisSec + ObjArray(i).Handoff;
        end
    end
    new_nXBoundHandoff = nXBoundHandoff + nXBoundHandoffThisSec;
end

% Check if cars are in bound (in the system)
function ObjArray = isInbounds(ObjArray)
    car_num = numel(ObjArray);
    for i=car_num:-1:1
        if ObjArray(i).status == 0
            ObjArray(i) = [];
        end
    end
end

function bestSigMethod(ObjArray)
    for i=1:numel(ObjArray)
        ObjArray(i).bestSigMethod;
    end
end

function thresholdMethod(ObjArray)
    for i=1:numel(ObjArray)
        ObjArray(i).thresholdMethod;
    end
end

function entropyMethod(ObjArray)
    for i=1:numel(ObjArray)
        ObjArray(i).entropyMethod;
    end
end

function myMethod(ObjArray)
    for i=1:numel(ObjArray)
        ObjArray(i).myMethod;
    end
end

% Tally accumulated number of handoffs up to current sec for each method
function nHandoff = tallyHandoff(ObjArray, nXBoundHandoff)
    nInBoundHandoff = 0;
    for i=1:numel(ObjArray)
        nInBoundHandoff = nInBoundHandoff + ObjArray(i).Handoff;
    end
    nHandoff = nInBoundHandoff + nXBoundHandoff;
end

% Get sum of signal power at t sec. instance for each method
function PsumPerSec = getPsumPerSec(ObjArray)
    PsumPerSec = zeros(5, 1);
    PsumPerSec(1) = numel(ObjArray);
    for i=1:numel(ObjArray)
        PsumPerSec(2:5) = PsumPerSec(2:5) + ObjArray(i).Signal_power;
    end
end

% Plot simulation animation
function plotCCar(CarRoster, nCar, method)
    if method == "best"
        type = 1;
    elseif method == "threshold"
        type = 2;
    elseif method == "entropy"
        type = 3;
    elseif method == "my"
        type = 4;
    end
    % Assign cars' (x, y) coordinates to the BSs they are connected to
    nB1 = 0; nB2 = 0; nB3 = 0; nB4 = 0;
    X_B1 = zeros(1, 100); Y_B1 = zeros(1, 100);
    X_B2 = zeros(1, 100); Y_B2 = zeros(1, 100);
    X_B3 = zeros(1, 100); Y_B3 = zeros(1, 100);
    X_B4 = zeros(1, 100); Y_B4 = zeros(1, 100); 
    for j=1:nCar
        if CarRoster(j).Base(type) == 1
            nB1 = nB1 + 1;
            X_B1(nB1) = CarRoster(j).x;
            Y_B1(nB1) = CarRoster(j).y;
        elseif CarRoster(j).Base(type) == 2
            nB2 = nB2 + 1;
            X_B2(nB2) = CarRoster(j).x;
            Y_B2(nB2) = CarRoster(j).y;
        elseif CarRoster(j).Base(type) == 3
            nB3 = nB3 + 1;
            X_B3(nB3) = CarRoster(j).x;
            Y_B3(nB3) = CarRoster(j).y;
        elseif CarRoster(j).Base(type) == 4
            nB4 = nB4 + 1;
            X_B4(nB4) = CarRoster(j).x;
            Y_B4(nB4) = CarRoster(j).y;
        end
    end
    % If # of cars > 0, plot the cars according to their BSs' colors
    if nB1 > 0
        plot(X_B1, Y_B1, 'squareb', 'LineWidth',1)
        hold on;
    end
    if nB2 > 0
        plot(X_B2, Y_B2, 'squarer', 'LineWidth',1)
        hold on;
    end
    if nB3 > 0
        plot(X_B3, Y_B3, 'squarek', 'LineWidth',1)
        hold on;
    end
    if nB4 > 0
        plot(X_B4, Y_B4, 'squareg', 'LineWidth',1)
        hold on;
    end
    % Draw base stations 1~4
    viscircles([750, 750], 150, 'Color',[0.4660 0.6740 0.1880], 'LineWidth',0.5);  %... BS4
    viscircles([750, 2250], 150, 'Color',[0 0.4470 0.7410], 'LineWidth',0.5);  %... BS1
    viscircles([2250, 2250], 150, 'Color',[0.6350 0.0780 0.1840], 'LineWidth',0.5);  %... BS2
    viscircles([2250, 750], 150, 'Color',[0 0 0], 'LineWidth',0.5);  %... BS3
    
    grid on; hold off;
    xticks(0:750:3000);   xlim([0 3000]);
    yticks(0:750:3000);   ylim([0 3000]);
end
