function [p,seed] = create_lattice_pores(N,N_side,degree,seed)
warning('off','all')

if ~exist('seed','var')
    seed = randi(intmax);
end

if ~exist('degree','var')
    degree = 0;
end

rng(seed);


N_slots = N_side^2;
slots = randperm(N_slots);
slots = slots(1:N);

xb = [0,1];
xbox_size = (xb(2)-xb(1))/N_side;
yb = [0,1];
ybox_size = (yb(2)-yb(1))/N_side;

get_xpos = @(s) mod(s-1,N_side)*xbox_size+xbox_size/2;
get_ypos = @(s) floor((s-1)/N_side)*ybox_size+ybox_size/2;


p = polyshape([xb,fliplr(xb)],repelem(yb,1,2));

%figure; hold on; axis equal
for i = 1:N
    
    xc = get_xpos(slots(i));
    yc = get_ypos(slots(i));

    r = xbox_size/6+rand*xbox_size/3;
    start_angle = rand*2*pi;
    n_gon = randi([3,6]); % [2,6] to allow circles
    if n_gon == 2
        n_gon = 20;
    end

    xs = xc+r*cos(start_angle+2*pi/n_gon*(1:n_gon));
    ys = yc+r*sin(start_angle+2*pi/n_gon*(1:n_gon));

    R = polyshape([xs,xs(1)],[ys,ys(1)]);
    
    if ~isempty(R)
        p = subtract(p,R);
    end
end

delta = 1;
p = smooth_holes(p,delta,degree);
