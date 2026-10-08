function [DMAA, info] = dmaa_calculator(M1, M1_coords, side_indx, vis, varargin)
% DMAA_CALCULATOR
% [DMAA, info] = dmaa_calculator(M1, M1_coords, side_indx, vis, [name, value])
%
% Distal Metatarsal Articular Angle from a 3D first metatarsal. The head is
% projected onto a plane (like an AP radiograph) and its outline is traced.
% The medial and lateral edges of the articular surface are the sharpest
% convex corners of the outline on either side of the distal tip, searched
% only up to the first concavity (e.g. the sagittal groove before a medial
% eminence). DMAA is the angle between the perpendicular to the line through
% those edges and the M1 long axis, measured in the foot axial (XY) plane so
% it is comparable to an AP radiograph.
%
% M1        : triangulation of the first metatarsal (foot frame: X = ML, Y = AP, Z = SI)
% M1_coords : out_rotated.Metatarsal1, rows 1-6 = [origin; AP end; origin; SI end; origin; ML end]
% side_indx : 1 = right, 2 = left
% vis       : 1 to plot the articular edges, 0 otherwise
% Options   : 'HeadFraction'     (0.30) distal fraction of M1 length used as the head
%             'BinWidth'         (2)    degrees per outline sample
%             'SmoothLength'     (1.5)  mm of outline smoothing before curvature
%             'ConcaveCurvature' (0.05) 1/mm, concavity that ends the articular search
%             'MinEdgeOffset'    (0.25) min mediolateral distance of an edge from the tip, x head width
%             'MaxDepth'         (0.5)  max distance of an edge behind the tip, x head width
%
% DMAA : degrees, positive = lateral (valgus) deviation of the articular surface
% info : outline, articular edges, and axes in plane coordinates (u = lateral, v = distal)

% ---------- Options ----------
opts = struct('HeadFraction', 0.30, 'BinWidth', 2, 'SmoothLength', 1.5, 'ConcaveCurvature', 0.05, ...
    'MinEdgeOffset', 0.25, 'MaxDepth', 0.5);
for k = 1:2:numel(varargin)
    opts.(varargin{k}) = varargin{k+1};
end

P = M1.Points;

% ---------- M1 axis ----------
ap = unit(M1_coords(2,:) - M1_coords(1,:));

% Lateral direction in the foot frame: right lateral is +X, left lateral is -X
if side_indx == 1
    lat_sign = 1;
else
    lat_sign = -1;
end

% ---------- Distal head ----------
s = (P - M1_coords(1,:)) * ap';
L = max(s) - min(s);
H = P(s > max(s) - opts.HeadFraction*L, :);

% ---------- DMAA in the foot axial plane ----------
[DMAA, info] = outline_dmaa(H, ap, [0 0 1], lat_sign, opts);

% ---------- Visualization (optional) ----------
if vis == 1
    o = info;
    figure('Color','w'); hold on
    p1 = patch('Faces',M1.ConnectivityList,'Vertices',P,'FaceColor',[0.85 0.85 0.85],'EdgeColor','none', ...
        'FaceLighting','gouraud','AmbientStrength',0.15);
    alpha(p1,0.5)

    % Outline (black), articular edges and line (red), M1 axis (blue) and line perpendicular (red)
    z = max(H(:,3)) + 1; % draw above the bone in the top view
    to3d = @(uv) uv(:,1)*o.lat + uv(:,2)*o.axis + z*[0 0 1];
    plot3_pts(to3d(o.outline), 'k-', 1);
    plot3_pts(to3d(o.edges), 'r-o', 2);
    origin = M1_coords(1,:);
    len = max(H*o.axis') - origin*o.axis';
    quiver3(origin(1),origin(2),z, len*o.axis(1),len*o.axis(2),0, 0, 'LineWidth',2,'Color',[0 0 1]);
    mid = mean(to3d(o.edges), 1);
    perp = unit(o.perp(1)*o.lat + o.perp(2)*o.axis);
    quiver3(mid(1),mid(2),z, 15*perp(1),15*perp(2),0, 0, 'LineWidth',2,'Color',[1 0 0]);

    view([0 90]);
    camlight HEADLIGHT; material dull
    axis equal off
    title("Angle = " + sprintf('%.2f', DMAA) + char(176), 'Interpreter','none')
end
end

% ------- Helpers -------
function [ang, o] = outline_dmaa(H, ap, n, lat_sign, opts)
% DMAA in the plane with normal n (positive = lateral)
n = unit(n);
a = unit(ap - dot(ap,n)*n);        % M1 axis in the plane
lat = lat_sign*unit(cross(a, n));  % lateral direction in the plane
uv = [H*lat', H*a'];               % 2D: u = lateral, v = distal

% Outline: farthest projected point per angular bin around a center behind the tip
width = max(uv(:,1)) - min(uv(:,1));
c = [mean(uv(:,1)), max(uv(:,2)) - width/2];
d = uv - c;
th = atan2d(d(:,1), d(:,2));       % 0 = distal, + = lateral
rho = vecnorm(d, 2, 2);
bin_edges = -120:opts.BinWidth:120;
k = discretize(th, bin_edges);
theta = bin_edges(1:end-1)' + opts.BinWidth/2;
outline = nan(numel(theta), 2);
for b = 1:numel(theta)
    m = find(k == b);
    if ~isempty(m)
        [~, j] = max(rho(m));
        outline(b,:) = uv(m(j),:);
    end
end
keep = all(isfinite(outline), 2);
outline = outline(keep,:);
theta = theta(keep);

% Smooth over a fixed arc length, then signed curvature (convex is negative)
spacing = median(vecnorm(diff(outline), 2, 2));
win = max(1, round(opts.SmoothLength/spacing));
outline = [movmean(outline(:,1), win), movmean(outline(:,2), win)];
t = gradient(outline')';
phi = unwrap(atan2(t(:,2), t(:,1)));
kappa = gradient(phi)./vecnorm(t, 2, 2);

% Walk out from the distal tip on each side until the first concavity,
% ignoring the region right at the tip and anything beyond the head depth
near_tip = find(abs(theta) < 45);
[~, j] = max(outline(near_tip, 2));
tip = near_tip(j);
du = abs(outline(:,1) - outline(tip,1));         % mediolateral distance from the tip
depth = outline(tip,2) - outline(:,2);           % distance behind the tip
in_head = depth < opts.MaxDepth*width;
past_tip = du > opts.MinEdgeOffset*width;
lo = tip;
while lo > 1 && in_head(lo-1) && theta(lo-1) > -100 && (kappa(lo-1) < opts.ConcaveCurvature || ~past_tip(lo-1))
    lo = lo - 1;
end
hi = tip;
while hi < numel(theta) && in_head(hi+1) && theta(hi+1) < 100 && (kappa(hi+1) < opts.ConcaveCurvature || ~past_tip(hi+1))
    hi = hi + 1;
end

% Articular edges: sharpest convex corner on the medial and lateral side,
% at least MinEdgeOffset of the head width away from the tip
med_idx = (lo:tip)'; med_idx = med_idx(past_tip(med_idx));
lat_idx = (tip:hi)'; lat_idx = lat_idx(past_tip(lat_idx));
if isempty(med_idx), med_idx = lo; end
if isempty(lat_idx), lat_idx = hi; end
[~, im] = min(kappa(med_idx));
[~, il] = min(kappa(lat_idx));
edges = outline([med_idx(im); lat_idx(il)], :);

chord = edges(2,:) - edges(1,:);
perp = [-chord(2), chord(1)];
if perp(2) < 0
    perp = -perp;
end
ang = atan2d(perp(1), perp(2));

o = struct('outline', outline, 'kappa', kappa, 'edges', edges, 'perp', perp, ...
    'axis', a, 'lat', lat, 'normal', n);
end

function plot3_pts(X, style, lw)
plot3(X(:,1), X(:,2), X(:,3), style, 'LineWidth', lw, 'MarkerFaceColor', style(1));
end

function u = unit(v)
u = v/norm(v);
end
