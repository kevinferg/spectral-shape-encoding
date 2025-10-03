function sdf = polySDF(polyin, varargin)
% polySDF - calculates the signed distance function (SDF) for a polyshape.
%
% Usage:
%   sdf = polySDF(polyin, P)
%   sdf = polySDF(polyin, X, Y)
%
% Inputs:
%   polyin - A polyshape object.
%   P      - An N-by-2 matrix of [x, y] coordinates.
%   X, Y   - Matrices of x and y coordinates, must be the same size.
%
% Output:
%   sdf    - Signed distance function values. Positive outside, negative
%            inside, zero on the boundary; size matches P (rows) or X/Y.
%
% See also polyshape, isinterior


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Check the input arguments %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
narginchk(2, 3);
if ~isa(polyin, 'polyshape')
    error('The first input must be a polyshape object.');
end

% A flag to track if X,Y were passed instead of P
isXY_input = false;
original_size = [];

switch numel(varargin)
    case 1   % Case: polySDF(polyin, P)
        P = varargin{1};
        if ~isnumeric(P) || ~ismatrix(P) || size(P, 2) ~= 2
            error('Input P must be a numeric matrix with 2 columns.');
        end
    case 2   % Case: polySDF(polyin, X, Y)
        isXY_input = true;
        X = varargin{1};
        Y = varargin{2};
        if ~isnumeric(X) || ~isnumeric(Y)
             error('Inputs X and Y must be numeric.');
        end
        if ~isequal(size(X), size(Y))
            error('Inputs X and Y must be the same size.');
        end
        
        original_size = size(X);
        P = [X(:), Y(:)];
    otherwise
        error(['Invalid number of input arguments. "' ...
               'Use P or X,Y for query points.']);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%
%%% Compute the SDF %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%-------------------------------------------------------------%%%
%%%                   Get overall edge info                     %%%
%%%-------------------------------------------------------------%%%
V = polyin.Vertices(~any(isnan(polyin.Vertices), 2), :);
nP = size(P,1);
nV = size(V,1);
[edges, is_hole_edge, is_ccw] = get_polyshape_edge_info(polyin);
%%%-------------------------------------------------------------%%%


%%%---------------------------------------------------%%%
%%%          Compute all pairwise distances           %%%
%%%---------------------------------------------------%%%
diffs = reshape(P, nP, 1, 2) - reshape(V, 1, nV, 2);
v1_to_p = diffs(:,edges(:,1),:);
v1_to_v2 = V(edges(:,2),:) - V(edges(:,1),:);

edge_len_sq = dot(v1_to_v2, v1_to_v2, 2)';
edge_len_sq(edge_len_sq == 0) = 1e-9;
%%%---------------------------------------------------%%%


%%%-----------------------------------------------------------%%%
%%%    Dist. b/w query pts and edge segments OR endpoints     %%%
%%%-----------------------------------------------------------%%%
numerator = sum(v1_to_p .* reshape(v1_to_v2, 1, [], 2), 3);
frac = numerator ./ edge_len_sq;

use_v1 = (frac <= 0);
use_v2 = (frac >= 1);
between = (frac > 0) & (frac < 1);

d_sq_v1 = dot(v1_to_p, v1_to_p, 3);
v2_to_p = v1_to_p - reshape(v1_to_v2, 1, [], 2);
d_sq_v2 = dot(v2_to_p, v2_to_p, 3);
d_sq_between = d_sq_v1 - (frac.^2 .* edge_len_sq);

d_sq_all = zeros(size(frac));
d_sq_all(use_v1) = d_sq_v1(use_v1);
d_sq_all(use_v2) = d_sq_v2(use_v2);
d_sq_all(between) = d_sq_between(between);
%%%-----------------------------------------------------------%%%


%%%-----------------------------------------------%%%
%%%    Define SDF as distance to nearest edge     %%%
%%%-----------------------------------------------%%%
[sdf_sq, sdf_edge_idx] = min(d_sq_all, [], 2);
sdf = sqrt(sdf_sq);
%%%-----------------------------------------------%%%


%%%------------------------------------------------------------%%%
%%%    Determine sign based on whether points are interior     %%%
%%%------------------------------------------------------------%%%
[N, R, ~] = size(v1_to_p);
rows = (1:N)';
idx_page1 = sub2ind([N, R], rows, sdf_edge_idx);
idx_page2 = idx_page1 + N * R;
vp1 = [v1_to_p(idx_page1), v1_to_p(idx_page2)];
v12 = v1_to_v2(sdf_edge_idx, :);
sdf_sign = sign(vp1(:,1) .* v12(:,2) - vp1(:,2) .* v12(:,1));
hole_edge_sign = is_hole_edge(sdf_edge_idx)*-2 + 1;
ccw_sign = is_ccw(sdf_edge_idx)*2 - 1;
sdf_sign = sdf_sign .* hole_edge_sign .* ccw_sign;
sdf_sign(sdf_sign == 0) = 1; % Exactly along edge --> positive
sdf = sdf .* sdf_sign;
%%%------------------------------------------------------------%%%


%%%-----------------------------------%%%
%%%     Reshape output if needed      %%%
%%%-----------------------------------%%%
if isXY_input
    sdf = reshape(sdf, original_size);
end
%%%-----------------------------------%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end



%   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   . %
% .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   %
%   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   . %
% .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   .   %



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Edge characterization function %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [edges, is_hole, is_ccw] = get_polyshape_edge_info(polyin)
    [vc, is_hole_region, is_ccw_region] = get_region_properties(polyin);
    if isempty(vc)
        edges = uint32.empty(0,2);
        is_hole = logical.empty(0,1);
        is_ccw = logical.empty(0,1);
        return;
    end
    
    ends = cumsum(vc);
    starts = [1; ends(1:end-1)+1];
    edge_cells = arrayfun(@(s, e) [(s:e)', circshift((s:e)',-1)], ...
        starts, ends, 'UniformOutput', false);
    
    is_hole_cells = arrayfun(@(count, is_h) repmat(is_h, count, 1), ...
        vc, is_hole_region, 'UniformOutput', false);
    
    is_ccw_cells = arrayfun(@(count, is_c) repmat(is_c, count, 1), ...
        vc, is_ccw_region, 'UniformOutput', false);
    
    edges = uint32(vertcat(edge_cells{:})); % Indices of edge vertices
    is_hole = vertcat(is_hole_cells{:});    % Whether edges border holes
    is_ccw = vertcat(is_ccw_cells{:});      % Whether edges loop CCW
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Polygon region characterization function %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [vc, is_hole, is_ccw] = get_region_properties(polyin)
    regions_list = regions(polyin);
    if isempty(regions_list)
        vc = []; is_hole = []; is_ccw = [];
        return;
    end
    
    counts_cell = arrayfun(@(r) ...
        [size(rmholes(r).Vertices, 1); ...
        arrayfun(@(h) size(h.Vertices, 1), holes(r))], ...
        regions_list, 'UniformOutput', false);
    
    is_hole_cell = arrayfun(@(r) ...
        [false; true(numel(holes(r)), 1)], ...
        regions_list, 'UniformOutput', false);
    
    is_ccw_cell = arrayfun(@(r) ...
        [is_counter_clockwise(rmholes(r).Vertices); ...
        arrayfun(@(h) is_counter_clockwise(h.Vertices), holes(r))], ...
        regions_list, 'UniformOutput', false);
        
    vc = vertcat(counts_cell{:});       % Num. vertices per region
    is_hole = vertcat(is_hole_cell{:}); % Whether each region is a hole
    is_ccw = vertcat(is_ccw_cell{:});   % Whether each region is CCW
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Polygon region orientation function %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function isCCW = is_counter_clockwise(V)
    if size(V, 1) < 3
        isCCW = false;
        return;
    end
    signed_area = 0.5 * sum(V(:,1).*circshift(V(:,2), -1) - ...
                                    circshift(V(:,1), -1).*V(:,2));
    isCCW = signed_area > 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%