classdef CCar < handle
    
    properties 
        status = 1  %... in system = 1, offbounds = 0
        x {mustBeNumeric}  %... x coordinate
        y {mustBeNumeric}  %... y coordinate
        direction {mustBeNumeric}  %... direction car is heading towards
        Base {mustBeNumeric}  %... BS car is connected to
        Signal_power {mustBeNumeric}  %... received signal power from BS
        Handoff = zeros(4, 1)  %... default # of handoff = 0
    end
    properties (SetAccess = private, Hidden = true)
        Pt = -50;     P1 = -60;     Pmin = -125;  %... dBm
        T = -110;     E = 5;  %... dBm
        square_length = 750;
        x_boundary = 3000;
        y_boundary = 3000;
        BS1_Coor = [750, 2250];
        BS2_Coor = [2250, 2250];
        BS3_Coor = [2250, 750];
        BS4_Coor = [750, 750];
        BS_Coor_Array = [[750, 2250]; [2250, 2250]; [2250, 750]; [750, 750]];
    end
    
    methods
        % Constructor
        function obj = CCar(x, y, direction)
            obj.x = x;
            obj.y = y;
            obj.direction = direction;
            
            % assign car to corresponding BS based on position of spawn
            if obj.direction == 2
                if obj.y == obj.square_length * 3
                    obj.Base = 1 * ones(4, 1);
                else
                    obj.Base = 4 * ones(4, 1);
                end
            elseif obj.direction == 3
                if obj.x == obj.square_length * 3
                    obj.Base = 2 * ones(4, 1);
                else
                    obj.Base = 1 * ones(4, 1);
                end
            elseif obj.direction == 4
                if obj.y == obj.square_length * 1
                    obj.Base = 3 * ones(4, 1);
                else
                    obj.Base = 2 * ones(4, 1);
                end
            elseif obj.direction == 1
                if obj.x == obj.square_length * 1
                    obj.Base = 4 * ones(4, 1);
                else
                    obj.Base = 3 * ones(4, 1);
                end
            end
            
            % initialize signal power received from 4 BSs
            SignalPower = sigPower(obj);
            obj.Signal_power = SignalPower(obj.Base(1)) * ones(4, 1);
        end
        
        % Drive Car Per Second
        function stepDrive(obj)
            [obj.x, obj.y, obj.direction] = stepDrive(obj.x, obj.y, obj.direction);
            % check if car is offbound
            if obj.x < 0 || obj.y < 0 || obj.x > obj.x_boundary || obj.y > obj.y_boundary
                obj.status = 0;
            end
        end
        
        % Determine Signal Power
        function SignalPower = sigPower(obj)
            Obj_Coor = [obj.x, obj.y];
            Distance = [norm(Obj_Coor - obj.BS1_Coor);
                        norm(Obj_Coor - obj.BS2_Coor);
                        norm(Obj_Coor - obj.BS3_Coor);
                        norm(Obj_Coor - obj.BS4_Coor)];
            SignalPower = obj.P1 - 20*log10(Distance);  %... 4x1 double
            for i=1:4  %... Pr = Inf when car just below base station
                if SignalPower(i) == Inf
                    SignalPower(i) = -50;
                end
            end
        end
        
        % (1) Best Relative Signal Method
        function bestSigMethod(obj)
            SignalPower = sigPower(obj);
            best_signal = max(SignalPower);
            % idx of base stations that have best signal
            BestSigBaseIdx = find(SignalPower == best_signal);
            % change base station
            if numel(BestSigBaseIdx) == 2 && ~ismember(obj.Base(1), BestSigBaseIdx)
                obj.Base(1) = randi(BestSigBaseIdx);
                obj.Handoff(1) = obj.Handoff(1) + 1;
            elseif numel(BestSigBaseIdx) == 1 && obj.Base(1) ~= BestSigBaseIdx
                obj.Base(1) = BestSigBaseIdx;
                obj.Handoff(1) = obj.Handoff(1) + 1;
            end
            % assign updated signal power to car
            obj.Signal_power(1) = best_signal;
        end
        
        % (2) Threshold Method
        function thresholdMethod(obj)
            % Pold < Threshold
            SignalPower = sigPower(obj);
            if obj.Signal_power(2) < obj.T
                best_signal = max(SignalPower);
                % idx of base stations that have best signal
                BestSigBaseIdx = find(SignalPower == best_signal);
                % change base station
                if numel(BestSigBaseIdx) == 2 && ~ismember(obj.Base(2), BestSigBaseIdx)
                    obj.Base(2) = randi(BestSigBaseIdx);
                    obj.Handoff(2) = obj.Handoff(2) + 1;
                elseif numel(BestSigBaseIdx) == 1 && obj.Base(2) ~= BestSigBaseIdx
                    obj.Base(2) = BestSigBaseIdx;
                    obj.Handoff(2) = obj.Handoff(2) + 1;
                end
                % assign updated signal power to car
                obj.Signal_power(2) = best_signal;
            % Pold > Threshold
            else
                obj.Signal_power(2) = SignalPower(obj.Base(2));
            end
        end
        
        % (3) Entropy Method
        function entropyMethod(obj)
            SignalPower = sigPower(obj);
            best_signal = max(SignalPower);
            % Pnew > Pold + E
            if best_signal > obj.Signal_power(3) + obj.E
                % idx of base stations that have best signal
                BestSigBaseIdx = find(SignalPower == best_signal);
                % change base station
                if numel(BestSigBaseIdx) == 2 && ~ismember(obj.Base(3), BestSigBaseIdx)
                    obj.Base(3) = randi(BestSigBaseIdx);
                    obj.Handoff(3) = obj.Handoff(3) + 1;
                elseif numel(BestSigBaseIdx) == 1 && obj.Base(3) ~= BestSigBaseIdx
                    obj.Base(3) = BestSigBaseIdx;
                    obj.Handoff(3) = obj.Handoff(3) + 1;
                end
                % assign updated signal power to car
                obj.Signal_power(3) = best_signal;
            % Pnew <= Pold + E
            else
                obj.Signal_power(3) = SignalPower(obj.Base(3));
            end
        end
        
        % (4) My (Threshold Distance) Method
        function myMethod(obj)
            SignalPower = sigPower(obj);
            best_signal = max(SignalPower);
            % handoff when dist to BSold > 1500m
            if norm([obj.x, obj.y] - obj.BS_Coor_Array(obj.Base(4),:)) > 1500
                % idx of base stations that have best signal
                BestSigBaseIdx = find(SignalPower == best_signal);
                % change base station
                if numel(BestSigBaseIdx) == 2 && ~ismember(obj.Base(4), BestSigBaseIdx)
                    obj.Base(4) = randi(BestSigBaseIdx);
                    obj.Handoff(4) = obj.Handoff(4) + 1;
                elseif numel(BestSigBaseIdx) == 1 && obj.Base(4) ~= BestSigBaseIdx
                    obj.Base(4) = BestSigBaseIdx;
                    obj.Handoff(4) = obj.Handoff(4) + 1;
                end
                % assign updated signal power to car
                obj.Signal_power(4) = best_signal;
            % dist to BSold < 1500
            else
                obj.Signal_power(4) = SignalPower(obj.Base(4));
            end
        end
    end
end