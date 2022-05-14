function X = smooth_boundary(X, pts, delta, degree)
% smooth_boundary - Apply Laplacian smoothing to a boundary
% First interpolates the boundary for uniformity using
% interpolate_boundary
% 
% INPUTS:
% X      - x-y coordinates (in matrix rows) of boundary to smooth
% pts    - number of points for interpolation before smoothing
% delta  - strength of Laplacian smoothing
% degree - degree of Laplacian smoothing
%
% OUTPUTS:
% X - new boundary, now smoothed
% 
% See also interpolate_boundary

if degree == 0
    return
end

X = interpolate_boundary(X, pts);

[n,~] = size(X);

L = spdiags(ones(n,1),0,n,n) - spdiags(ones(n,1),1,n,n);
L = L+L';
L(1,n)= -1;
L(n,1) = -1;
L = L./2;

for i = 1:degree
    d = L*X*delta;
    X = X-d;
end
