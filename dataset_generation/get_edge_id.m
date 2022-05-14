function [edge] = get_edge_id(model, x, y)
% get_edge_id - Search edges in PDE model for one that contains a point
% 
% INPUTS:
% model - PDE model
% x     - x-coordinate of query point
% y     - y-coordinate of query point
% 
% OUTPUTS:
% edge - Edge ID with a mesh node closest to point (x, y)
%

edges = model.Geometry.NumEdges;
closest = findNodes(model.Mesh,'nearest',[x;y]);
edge = 1;
for i = 1:edges
    my_nodes = findNodes(model.Mesh,'region','Edge',i);
    if (find(my_nodes == closest))
        edge = i;
        break;
    end
end
