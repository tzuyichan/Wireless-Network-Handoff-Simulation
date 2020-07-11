function [new_x_car, new_y_car, new_direction] = stepDrive(x_car, y_car, direction)
    square_length = 750;  %... distance between two intersections
    % straight 1/2, right 1/3, left 1/6
    P_straight = 1/2;  P_rightTurn = 1/3;  P_leftTurn = 1/6;
    speed = 10;  %... m/s

    % if reached intersection, turn?
    if rem(x_car, square_length) == 0 && rem(y_car, square_length) == 0
        % turn but not at 4 corners
        new_direction = turn(direction);
        % turn and at 4 corners
        if x_car == 0 && y_car == 0
            if direction == 3
                new_direction = 2;
            elseif direction == 4
                new_direction = 1;
            end
        elseif x_car == 0 && y_car == square_length * 4
            if direction == 1
                new_direction = 2;
            elseif direction == 4
                new_direction = 3;
            end
        elseif x_car == square_length * 4 && y_car == 0
            if direction == 2
                new_direction = 1;
            elseif direction == 3
                new_direction = 4;
            end
        elseif x_car == square_length * 4 && y_car == square_length * 4
            if direction == 1
                new_direction = 4;
            elseif direction == 2
                new_direction = 3;
            end
        end
    % don't turn    
    else
        new_direction = direction;
    end
    
    % finally, move car forward one step
    [new_x_car, new_y_car] = moveForward(x_car, y_car, new_direction, speed);
    
    
    function [new_x_car, new_y_car] = moveForward(x_car, y_car, direction, speed)
        if direction == 1
            new_y_car = y_car + speed;
            new_x_car = x_car;
        elseif direction == 2
            new_x_car = x_car + speed;
            new_y_car = y_car;
        elseif direction == 3
            new_y_car = y_car - speed;
            new_x_car = x_car;
        elseif direction == 4
            new_x_car = x_car - speed;
            new_y_car = y_car;
        end
    end

    function new_direction = turn(direction)
        % generate random number
        P_random = rand();
        % compare with turning probability & change direction
        % left turn
        if P_random < P_leftTurn  
            if direction ~= 1
                new_direction = direction - 1;
            elseif direction == 1
                new_direction = 4;
            end
        % right turn
        elseif P_random >= P_leftTurn && P_random < P_leftTurn + P_rightTurn  
            if direction ~= 4
                new_direction = direction + 1;
            elseif direction == 4
                new_direction = 1;
            end
        % straight
        elseif P_random >= P_straight  
            new_direction = direction;
        end
    end
end