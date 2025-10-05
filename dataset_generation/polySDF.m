function sdf = polySDF(polyin, varargin)
% polySDF - calculates the signed distance function (SDF) for a polyshape
%           at a set of input query points
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


%%%-----------------------------------------------------%%%
%%%               Get overall edge info                 %%%
%%%-----------------------------------------------------%%%
V = polyin.Vertices(~any(isnan(polyin.Vertices), 2), :);
nP = size(P,1);
nV = size(V,1);
[edges, hole_sign, loop_sign, edge_sign] = ...
    get_polyshape_edge_info(polyin);
%%%-----------------------------------------------------%%%


%%%---------------------------------------------------%%%
%%%          Compute all pairwise distances           %%%
%%%---------------------------------------------------%%%
diffs = reshape(P, nP, 1, 2) - reshape(V, 1, nV, 2);
d_sq_vertex = dot(diffs, diffs, 3);  % Query-to-vertex

v1_to_v2 = V(edges(:,2),:) - V(edges(:,1),:);
edge_len_sq = dot(v1_to_v2, v1_to_v2, 2)';
edge_len_sq(edge_len_sq == 0) = 1e-9; % Along edges
%%%---------------------------------------------------%%%


%%%-----------------------------------------------------------%%%
%%%    Dist. b/w query pts and edge segments OR endpoints     %%%
%%%-----------------------------------------------------------%%%
v1_to_p = diffs(:,edges(:,1),:);
numerator = sum(v1_to_p .* reshape(v1_to_v2, 1, [], 2), 3);
frac = numerator ./ edge_len_sq;
use_v1  = (frac <= 0);
use_v2  = (frac >= 1);
between = (frac > 0) & (frac < 1);

d_sq_v1 = d_sq_vertex(:, edges(:,1));
d_sq_v2 = d_sq_vertex(:, edges(:,2));
d_sq_between = d_sq_v1 - (frac.^2 .* edge_len_sq);

d_sq_all = use_v1  .* d_sq_v1 + ...
           use_v2  .* d_sq_v2 + ...
           between .* d_sq_between;
%%%-----------------------------------------------------------%%%


%%%-----------------------------------------------%%%
%%%    Define SDF as distance to nearest edge     %%%
%%%-----------------------------------------------%%%
[sdf_sq, sdf_edge_idx] = min(d_sq_all, [], 2);
sdf = sqrt(sdf_sq);

[N, R, ~] = size(v1_to_p);
rows = (1:N)';
min_idx_1d = sub2ind([N, R], rows, sdf_edge_idx);
use_v1  = use_v1(min_idx_1d);
use_v2  = use_v2(min_idx_1d);
between = between(min_idx_1d);
%%%-----------------------------------------------%%%


%%%-------------------------------------------------------------%%%
%%%      Determine sign based on whether points are inside      %%%
%%%-------------------------------------------------------------%%%
sdf_sign = zeros(size(sdf)); 

vp1 = [v1_to_p(min_idx_1d), v1_to_p(min_idx_1d + R*N)];
v12 = v1_to_v2(sdf_edge_idx, :);
sdf_sign(between) = sign(vp1(between,1) .* v12(between,2) - ...
                         vp1(between,2) .* v12(between,1));
sdf_sign(use_v1)  = edge_sign(sdf_edge_idx(use_v1));
sdf_sign(use_v2)  = edge_sign(edges(sdf_edge_idx(use_v2), 2));

sdf_sign = sdf_sign .* loop_sign(sdf_edge_idx) ...
                    .* hole_sign(sdf_edge_idx);
sdf_sign(sdf_sign == 0) = 1; % Exactly along edge --> positive
sdf = sdf .* sdf_sign;
%%%-------------------------------------------------------------%%%


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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Polygon edge characterization function %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [edges, hole_sign, loop_sign, edge_sign] = ...
         get_polyshape_edge_info(polyin)
    %       ___________________________________________________       %
    %______/  Get region info and handle empty polyshape case  \______%
    [vc, is_hole_region, is_ccw_region] = get_region_properties(polyin);
    if isempty(vc)
        edges = uint32.empty(0,2);
        hole_sign = double.empty(0,1);
        loop_sign = double.empty(0,1);
        edge_sign = double.empty(0,1);
        return;
    end
    %       ___________________________________________________       %
    %______/ Get edge index information, handling region loops \______%
    V = polyin.Vertices(~any(isnan(polyin.Vertices), 2), :);
    num_verts = size(V, 1);
    
    ends = cumsum(vc);
    starts = [1; ends(1:end-1)+1];
    v_indices = (1:num_verts)';
    
    v_next_indices = circshift(v_indices, -1);
    v_next_indices(ends) = starts;
    
    v_prev_indices = circshift(v_indices, 1);
    v_prev_indices(starts) = ends;

    edges = uint32([v_indices, v_next_indices]);
    %        _______________________________        %
    %_______/ Expand per-region to per-edge \_______%
    repeater = zeros(num_verts, 1);
    repeater(starts) = 1;
    region_idx = cumsum(repeater);
    hole_sign = 1 - 2*is_hole_region(region_idx);
    loop_sign = 2*is_ccw_region(region_idx) - 1;
    %        ______________________________________________        %
    %_______/ Edge sign: turning direction of first vertex \_______%
    vec_in = V - V(v_prev_indices, :);
    vec_out = V(v_next_indices, :) - V;
    crossprod = vec_in(:,1) .* vec_out(:,2) - ...
                vec_in(:,2) .* vec_out(:,1);
    edge_sign = sign(crossprod);
    edge_sign(~any(vec_in, 2) | ~any(vec_out, 2)) = 0;
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
    signed_area = 0.5 * sum(V(:,1) .* circshift(V(:,2), -1) - ...
                            circshift(V(:,1), -1) .* V(:,2));
    isCCW = signed_area > 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%