function boolean = poissonGenerateCar()
    lambda = 1/30;  %... cars / sec.
    P_random = rand();
    P_generateCar = lambda * exp(-lambda);
    if P_random < P_generateCar
        boolean = 1;
    else
        boolean = 0;
    end
end