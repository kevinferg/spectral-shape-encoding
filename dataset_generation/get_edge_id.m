% This function gets the edge from the mesh that contains the requested point 
function [edge] = get_edge_id(model,x,y)
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
end