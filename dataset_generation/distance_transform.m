function dist = distance_transform(model)

[p,e,t] = meshToPet(model.Mesh);

boundary_points = union(unique(e(1,:)),unique(e(2,:)));
num_points = size(p,2);
num_elem = size(t,2);
dist = -ones(num_points,1);
dist(boundary_points) = 0;
neighbors = cell(num_points,1);
for i = 1:num_elem
    for j = 1:3
        this = t(j,i);
        those = t(setdiff(1:3,j),i);
        neighbors{this} = union(neighbors{this},those);
    end
end

num_updates = 1e9;
while num_updates > 0
    dprev = dist;
    num_updates = 0;
    for i = 1:num_points
        if dist(i) == -1
            nbr = dprev(neighbors{i});
            nbr = nbr(nbr~=-1);
            if ~isempty(nbr)
                dist(i) = min(nbr)+1;
                num_updates = num_updates + 1;
            end
        end
    end
end
