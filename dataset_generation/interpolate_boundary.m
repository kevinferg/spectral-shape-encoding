function X = interpolate_boundary(X, n)
% interpolate_boundary - Given points on a 2D boundary, interpolate with a
% requested number of points
% 
% INPUTS:
% X - x-y coordinates (in matrix rows) of boundary to interpolate
% n - Number of points for interpolation
%
% OUTPUTS:
% X - New boundary, now with n evenly spaced points
% 

if 2 > sum(X(1,:) == X(end,:))
    X = [X; X(1,:)];
end

lens = sqrt(sum((X(2:end,:)-X(1:(end-1),:)).^2,2));
pct = [0;cumsum(lens)/sum(lens)]; pct(end) = 1.000001;
frac = linspace(0,1,n)';
idx = arrayfun(@(x) find(x>=pct,1,'last'),frac);
progress = (frac-pct(idx))./(pct(idx+1)-pct(idx));
X = X(idx,:)+progress.*(X(idx+1,:)-X(idx,:));
X = X(1:end-1,:);