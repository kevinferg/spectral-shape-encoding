function h = plotSDF(polyin, options)
% plotSDF - Plots the signed distance field (SDF) for a polyshape.
%
% Usage:
%   h = plotSDF(polyin)
%   h = plotSDF(polyin, Name, Value, ...)
%
% Inputs:
%   polyin - A polyshape object.
%
% Optional Name-Value Pair Arguments:
%   Resolution     - (scalar) Number of points along the x-axis.
%                    Defaults to 50.
%   XLim           - (1x2 vector) X-axis limits for the plot.
%   YLim           - (1x2 vector) Y-axis limits for the plot.
%   ContourSpacing - (scalar) If specified, creates a contour plot with
%                    contours spaced by this value. Otherwise, uses imagesc.
%   SaturateSDF    - (scalar) SDF magnitude for peak red/blue color saturation.
%                    Defaults to the maximum absolute value in the data.
%   Parent         - (axes handle) Axes to plot into. Defaults to gca.
%
% Output:
%   h    - The graphics object handle (image or contour).

arguments
    polyin              polyshape
    options.Resolution  (1,1) double {mustBeInteger, mustBePositive} = 50
    options.XLim        (1,2) double
    options.YLim        (1,2) double
    options.ContourSpacing  (1,1) double {mustBeNumeric}
    options.SaturateSDF (1,1) double {mustBePositive}
    options.Parent      matlab.graphics.axis.Axes = gca
end

%----------------------------------------------------------%
%                       Plot Limits                        %
%----------------------------------------------------------%
if isfield(options,'XLim') && isfield(options,'YLim')
    xlims = options.XLim; ylims = options.YLim;
else
    bb = boundingbox(polyin);
    if size(bb,2)<2, bb(1,2)=bb(1,1); end
    if size(bb,1)<2, bb(2,:)=bb(1,:); end
    x_range = bb(1,2)-bb(1,1); y_range = bb(2,2)-bb(2,1);
    if x_range==0, x_range=1; end
    if y_range==0, y_range=1; end
    xlims = bb(1,:)+[-0.1,0.1]*x_range;
    ylims = bb(2,:)+[-0.1,0.1]*y_range;
    if isfield(options,'XLim'), xlims=options.XLim; end
    if isfield(options,'YLim'), ylims=options.YLim; end
end

%------------------------------------------------------------------%
%                     Query SDF on grid points                     %
%------------------------------------------------------------------%
x_range_plot = xlims(2)-xlims(1);
y_range_plot = ylims(2)-ylims(1);
aspect = y_range_plot/x_range_plot;
v_x = linspace(xlims(1),xlims(2),options.Resolution);
v_y = linspace(ylims(1),ylims(2),round(options.Resolution*aspect));
[x,y] = meshgrid(v_x,v_y);

sdf_values = polySDF(polyin,x,y);    % Must have polySDF function

%----------------------------------------------------------------------%
%                   Plot with imagesc or contourf                      %
%----------------------------------------------------------------------%
ax = options.Parent; hold(ax,'on');
if isfield(options,'ContourSpacing')
    spacing = options.ContourSpacing;
    v_limit = max(abs(sdf_values(:)));
    levels = unique([-v_limit:spacing:v_limit,0]);
    h = contourf(ax,x,y,sdf_values,levels,'LineStyle','none');
    % contour(ax, x, y, sdf_values, [0 0], 'k', 'LineWidth', 1.5);
else
    h = imagesc(ax,v_x,v_y,sdf_values);
    set(ax,'YDir','normal');
    plot(ax,polyin,'FaceColor','none','EdgeColor','k','LineWidth',1.5);
end

%--------------------------------------------------------------------------%
%                     Custom blue-white-red colormap                       %
%--------------------------------------------------------------------------%
n = 128; t = linspace(0,1,n)';  
custom_map = [[t t ones(n,1)]; [ones(n-1,1) flip(t(2:end)) flip(t(2:end))]];
if isfield(options,'SaturateSDF')
    v_limit = options.SaturateSDF;
else
    v_limit = max(abs(sdf_values(:))); if v_limit==0, v_limit=1; end
end
colormap(ax,custom_map);
colorbar(ax);
clim(ax,[-v_limit,v_limit]);
axis(ax,'equal','tight');
xlim(ax,xlims); ylim(ax,ylims);
hold(ax,'off');
end