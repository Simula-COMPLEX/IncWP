function v=hypervolume(P,r,N)
% HYPERVOUME    Hypervolume indicator as a measure of Pareto front estimate.
%   V = HYPERVOLUME(P,R,N) returns an estimation of the hypervoulme (in
%   percentage) dominated by the approximated Pareto front set P (n by d)
%   and bounded by the reference point R (1 by d). The estimation is doen
%   through N (default is 1000) uniformly distributed random points within
%   the bounded hyper-cuboid.  
%
%   V = HYPERVOLUMN(P,R,C) uses the test points specified in C (N by d).
%
% See also: paretofront, paretoGroup

% Version 1.0 by Yi Cao at Cranfield University on 20 April 2008

% Example
%{
% an random exmaple
F=(randn(100,3)+5).^2;
% upper bound of the data set
r=max(F);
% Approximation of Pareto set
P=paretofront(F);
% Hypervolume
v=hypervolume(F(P,:),r,100000);
%}

% Check input and output
% error(nargchk(2,3,nargin));
% error(nargoutchk(0,1,nargout));
% 
% F=(randn(100,3)+5).^2;
% r=max(F);
% % %r=min(F);
% % 
% % %P=paretofront(F);
% % %v=hypervolume(F(P,:),r,100000);
% % 
% experimentPopulation = SOLUTION(zeros(length(F),1),F, zeros(length(F),1));
% P = experimentPopulation.best.objs;
% % diagP=max([P; r])-min([P; r]);
% % 
% N = 10000;
% lB=min(P);
% P=P-lB;
% r=r-lB;



P=P*diag(1./r);
%P = ones(size(P)) - P
[n,d]=size(P);
if nargin<3
    N=1000;
end
if ~isscalar(N)
    C=N;
    N=size(C,1);
else
    C=rand(N,d);
end

fDominated=false(N,1);
lB=min(P);
fcheck=all(bsxfun(@gt, C, lB),2);



for k=1:n
    if any(fcheck)
        f=all(bsxfun(@gt, C(fcheck,:), P(k,:)),2);
        fDominated(fcheck)=f;
        fcheck(fcheck)=~f;
    end
end


v=sum(fDominated)/N;

% diagP=max([P; r])-min([P; r]);
% v=v*prod(diagP);
% 
% 
% figure
% hold on
% ndom=0;
% nnondom=0;
% for k=1:N
%     if(fDominated(k))
%         ndom=ndom+1;
%         Cdom(ndom,:)=C(k,:);
%     else
%         nnondom=nnondom+1;
%         Cnondom(nnondom,:)=C(k,:);
%     end
% end
% if(nnondom < N)
%     Cdom
%     plot(Cdom(:,1),Cdom(:,2),'r.')
%     hold on
% end
% 
% plot(Cnondom(:,1),Cnondom(:,2),'b.')
% hold on
% % add the scaled Pareto front points
% plot(P(:,1),P(:,2),'k*','MarkerSize',10)
% legend("dominated random points", "not dominated random points", "pareto front")
% ylabel(" [Minmimize] objective 2 distance between points")
% xlabel(" [Minimize] objecitve 1 sum of path lenths from a thesohld")
% title(["Categorization of the random poinsts with HV score of", num2str(v)])
% fDominated;