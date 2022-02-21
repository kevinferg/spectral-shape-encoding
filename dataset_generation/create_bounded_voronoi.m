function [p,X] = create_bounded_voronoi(np,xb,yb,minwall)
warning('off','all')

xmin = xb(1)+minwall/2; xmax = xb(2)-minwall/2;
ymin = yb(1)+minwall/2; ymax = yb(2)-minwall/2;

rands = rand(2,np)';
x = xmin+rands(:,1)*(xmax-xmin);
y = ymin+rands(:,2)*(ymax-ymin);
% pvals = [.25,.75,.5;.2,.4,.8]';
% x = xmin+pvals(:,1)*(xmax-xmin)+(rands(:,1)-.02)*0.04;
% y = ymin+pvals(:,2)*(ymax-ymin)+(rands(:,1)-.02)*0.04;

X = [x,y];
pts = X;
% dt = delaunayTriangulation(X);
% [V,R] = voronoiDiagram(dt);
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
regions = cellfun(@(a) old_verts(a),R,'UniformOutput',0);

p = polyshape([xb,fliplr(xb)],repelem(yb,1,2));

%figure; hold on; axis equal
for i = 1:N
    X = verts(regions{i},:);
    X = [X;X(1,:)];
    %fill(X(:,1),X(:,2),'g')
    
    R = polybuffer(X,'lines',minwall/2);
    R = holes(R);
    
%     k = convhull(X,'Simplify',true);
%     R = polyshape(X(k,1),X(k,2));
%     [c1,c2] = centroid(R);
%     C = [c1,c2];
%     [rows,~] = size(X);
%     d = db(1)+rand(rows,1)*(db(2)-db(1));
%     
%     X = X+d.*(C-X);
%     k = convhull(X,'Simplify',true);
%     R = polyshape(X(k,1),X(k,2));
    
    if ~isempty(R)
        p = subtract(p,R);
        %plot(R,'facecolor','k','facealpha',.9)
    end
end

%figure; hold on; axis equal
%plot(p)
X = pts;

