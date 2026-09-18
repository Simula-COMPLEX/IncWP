function Offspring = GArealPoints(Problem,Parent,Parameter)
    if nargin > 2
        [proC,disC,proM,disM] = deal(Parameter{:});
    else
        [proC,disC,proM,disM] = deal(1,20,1,20);
    end
    if isa(Parent(1),'SOLUTION')
        evaluated = true;
        Parent    = Parent.decs;
    else
        evaluated = false;
    end

    Parent1   = Parent(1:floor(end/2),:);
    Parent2   = Parent(floor(end/2)+1:floor(end/2)*2,:);
    lower = Problem.lower;
    upper = Problem.upper;

    [N,D] = size(Parent1);
    numPoints = D/Problem.pointDimension;
    %[N,numPoints] = size(Parent,1)/

    %% Simulated binary crossover
    %[N,D] = size(Parent1);
    beta  = zeros(N,numPoints);
    mu    = rand(N,numPoints);
    beta(mu<=0.5) = (2*mu(mu<=0.5)).^(1/(disC+1));
    beta(mu>0.5)  = (2-2*mu(mu>0.5)).^(-1/(disC+1));
    beta = beta.*(-1).^randi([0,1],N,numPoints);
    beta(rand(N,numPoints)<0.5) = 1;
    beta(repmat(rand(N,1)>proC,1,numPoints)) = 1;
    betaPoints =zeros(N,D);
    for point = 1:numPoints 
        startPoint = (point -1)*Problem.pointDimension + 1;
        endIndex = point*Problem.pointDimension;

        betaPoints(:,startPoint:endIndex) = beta(:,point).*ones(N,Problem.pointDimension);
    end
    Offspring = [(Parent1+Parent2)/2+betaPoints.*(Parent1-Parent2)/2
                 (Parent1+Parent2)/2-betaPoints.*(Parent1-Parent2)/2];
             
    %% Polynomial mutation
    Lower = repmat(lower,2*N,1);
    Upper = repmat(upper,2*N,1);
    Site  = rand(2*N,D) < proM/D;
    mu    = rand(2*N,D);
    temp  = Site & mu<=0.5;
    Offspring       = min(max(Offspring,Lower),Upper);
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*((2.*mu(temp)+(1-2.*mu(temp)).*...
                      (1-(Offspring(temp)-Lower(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1))-1);
    temp = Site & mu>0.5; 
    Offspring(temp) = Offspring(temp)+(Upper(temp)-Lower(temp)).*(1-(2.*(1-mu(temp))+2.*(mu(temp)-0.5).*...
                      (1-(Upper(temp)-Offspring(temp))./(Upper(temp)-Lower(temp))).^(disM+1)).^(1/(disM+1)));

    Offspring = Problem.Evaluation(Offspring);
end