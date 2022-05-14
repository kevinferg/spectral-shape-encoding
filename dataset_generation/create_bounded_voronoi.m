function [p,X] = create_bounded_voronoi(np,xb,yb,minwall)
% create_bounded_voronoi - Generate a porous geometry using a Voronoi
% diagram on a rectangular region
% 
% INPUTS:
% np      - Number of Voronoi points
% xb      - x bounds, e.g. [0 1]
% yb      - y bounds, e.g. [0 1]
% minwall - Minimum thickness of walls between holes
%
% OUTPUTS:
% p - MATLAB polyshape with generated structure
% X - Voronoi points used to generate p

warning('off','all')

xmin = xb(1)+minwall/2; xmax = xb(2)-minwall/2;
ymin = yb(1)+minwall/2; ymax = yb(2)-minwall/2;

rands = rand(2,np)';
x = xmin+rands(:,1)*(xmax-xmin);
y = ymin+rands(:,2)*(ymax-ymin);

X = [x,y];
pts = X;
middle = [x,y];
top = [x,y+2*(ymax-y)];
bottom = [x,ymin-y+ymin];
left = [xmin-x+xmin,y];
right = [x+2*(xmax-x),y];
all = [middle;top;bottom;left;right];

dt = delaunayTriangulation(all);
[V,R] = voronoiDiagram(dt);

[N,~] = size(middle);
R = R(1:N);

indices = unique([R{:}]);
[num_verts,~] = size(V);
old_verts = zeros(1,num_verts);
old_verts(indices) = 1:length(indices);


verts = V(indices,:);
regions = cellfun(@(a) old_verts(a), R, 'UniformOutput', 0);

p = polyshape([xb, fliplr(xb)], repelem(yb,1,2));

for i = 1:N
    X = verts(regions{i},:);
    X = [X; X(1,:)];
    R = polybuffer(X, 'lines', minwall/2);
    R = holes(R);
    if ~isempty(R)
        p = subtract(p,R);
    end
end

X = pts;
