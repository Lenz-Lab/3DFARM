function angle = angle_calculator(startA, endA, startB, endB, bone1, bone2, plane, side_indx, viewer, varargin)
% ANGLE_CALCULATOR
% angle = angle_calculator(startA,endA,startB,endB,bone1,bone2,plane,side_indx,viewer,[measurement])
%
% startA,endA,startB,endB : 1x3 vectors (points) defining two directed vectors
% bone1,bone2              : structs with .ConnectivityList and .Points (from stlread)
% plane                    : "yz","xz","xy","3D" (string or char)
% side_indx                : 1 = right, 2 = left
% viewer                   : optional 1x12 or 4x3 array of points [Astart Aend Bstart Bend] for camera framing (can be [])
% measurement              : optional string for plot title/label
%
% Conventions (right-handed):
%  - "yz" (about +X):    plantarflex (-) / dorsiflex (+); no mirroring by side
%  - "xz" (about +Y):    inversion (-) / eversion (+); mirror for LEFT
%  - "xy" (about +Z):    internal (-) / external (+); mirror for LEFT
%
% Returns signed angle in degrees.

% ---------- Optional label ----------
if nargin > 9 && ~isempty(varargin{1})
    measurement = string(varargin{1});
else
    measurement = "";
end

% ---------- Input hygiene ----------
startA = startA(:).'; endA = endA(:).';
startB = startB(:).'; endB = endB(:).';
assert(numel(startA)==3 && numel(endA)==3 && numel(startB)==3 && numel(endB)==3, 'Points must be 1x3.');

if ischar(plane), plane = string(plane); end
plane = lower(plane);
assert(ismember(plane, ["yz","xz","xy","3d"]), 'plane must be "yz","xz","xy","3D".');

assert(ismember(side_indx,[1,2]), 'side_indx must be 1 (right) or 2 (left).');

% ---------- Build direction vectors ----------
v1 = endA - startA;
v2 = endB - startB;

% Guard against zero-length vectors
nv1 = norm(v1);  nv2 = norm(v2);
if nv1 < eps || nv2 < eps
    angle = 0;
    warning('One or both vectors have ~zero length; returning 0.');
    return
end

% ---------- Plane setup via unit normal n ----------
switch plane
    case "xy", n = [0 0 1];  viewv = [0 90];
    case "xz", n = [0 1 0];  viewv = [0 0];
    case "yz", n = [1 0 0];  viewv = [-90 0]*(side_indx==1) + [90 0]*(side_indx==2);
    case "3d", n = [];       viewv = [90 90]; % free 3D
end

% ---------- Project to plane (or keep 3D) ----------
if plane ~= "3d"
    % Project by removing normal component
    v1 = v1 - dot(v1,n)*n;
    v2 = v2 - dot(v2,n)*n;
    % Re-guard after projection
    if norm(v1) < eps || norm(v2) < eps
        angle = 0;
        warning('One or both vectors vanish after projection; returning 0.');
        return
    end
end

% ---------- Signed angle (general, stable) ----------
% For 2D planes, sign is from n·(v1×v2); for 3D we fall back to unsigned
if plane == "3d"
    angle = acosd( max(-1,min(1, dot(v1,v2)/(norm(v1)*norm(v2)) )) );
else
    s = dot(n, cross(v1, v2));
    c = dot(v1, v2);
    angle = atan2d(s, c);
end

% ---------- Side mirroring (only for XY/XZ as described) ----------
if side_indx == 2 % left
    if plane == "xy" || plane == "xz"
        angle = -angle;
    end
end

% ---------- Visualization (optional) ----------
if ~isempty(bone1) && ~isempty(bone2)
    figure('Color','w'); hold on
    p1 = patch('Faces',bone1.ConnectivityList,'Vertices',bone1.Points,...
        'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
    alpha(p1,0.5)

    p2 = patch('Faces',bone2.ConnectivityList,'Vertices',bone2.Points,...
        'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
    alpha(p2,0.5)

    % Arrows without external dependencies (replace 3rd-party "arrow")
    plot_arrow_quiver(startA, endA, [0 0 1]); % blue
    plot_arrow_quiver(startB, endB, [1 0 0]); % red

    % Try to center camera sensibly if viewer provided
    if ~isempty(viewer)
        % Accept 1x12 or 4x3
        if numel(viewer)==12
            V = reshape(viewer, [3,4]).'; % rows = [Astart Aend Bstart Bend]
        elseif isequal(size(viewer),[4,3])
            V = viewer;
        else
            warning('viewer must be 1x12 or 4x3; ignoring.');
            V = [];
        end
        if ~isempty(V)
            targetPoint = mean(V,1);
            % Use cross of vector directions to pick a sensible camera offset
            vecA = V(2,:)-V(1,:); vecB = V(4,:)-V(3,:);
            cr = cross(vecA,vecB);  if norm(cr)<eps, cr = [0 0 1]; end
            cr = cr / norm(cr);
            camPos = targetPoint + 100 * cr;
            camtarget(targetPoint);
            campos(camPos);
        end
    end

    view(viewv);
    camlight HEADLIGHT; material dull
    axis equal off
    xlabel('x'); ylabel('y'); zlabel('z'); set(gca,'XTick',[],'YTick',[],'ZTick',[])
    ttl = "Angle = " + sprintf('%.2f°',angle);
    if measurement ~= "" , ttl = measurement + "  —  " + ttl; end
    title(ttl, 'Interpreter','none')
end
end

% ------- Helpers -------
function plot_arrow_quiver(p0, p1, col)
d  = p1 - p0;
L  = norm(d);
if L < eps, return; end
u  = (50/L) * d; % consistent display length
quiver3(p0(1),p0(2),p0(3), u(1),u(2),u(3), 0, ...
    'LineWidth',2,'MaxHeadSize',0.5,'Color',col);
end
