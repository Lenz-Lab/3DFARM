function nodes_aligned = manual_align_points(points, side_indx)
%MANUAL_ALIGN_POINTS Minimal menus with colored hemispheres (no PCA).
%   nodes_aligned = manual_align_points(points, side_indx)
%   side_indx: 1=Right, 2=Left (default=2)
%
% Flow:
%   1) Show +Y hemisphere (yellow) -> ask which anatomical direction it is.
%   2) Show +Z hemisphere (red)    -> ask which anatomical direction it is.
%   3) Map world axes to target: X=ML, Y=AP, Z=SI (pre-laterality).
%   4) Enforce laterality (Right => +X is lateral), ensure det(R)=+1.
%   5) Rotate about origin, return aligned points.

if nargin < 2 || isempty(side_indx), side_indx = 2; end
validateattributes(points, {'double','single'}, {'2d','ncols',3}, mfilename, 'points', 1);
P = double(points);
if size(P,1) < 3, error('Need at least 3 points.'); end

% ---------- Step 1: +Y hemisphere (yellow) ----------
scr = get(0,'ScreenSize'); w=900; h=700;
fig1 = figure('Position',[ (scr(3)-w)/2, (scr(4)-h)/2, w, h ], ...
              'Color','w', 'Name','Step 1: +Y Hemisphere (Yellow)');
ax1  = axes('Parent',fig1);

maskY = P(:,2) > 0;
if ~any(maskY)
    maskY = P(:,2) >= 0;      % fallback if all Y<=0
end
plot3(ax1, P(~maskY,1), P(~maskY,2), P(~maskY,3), '.', 'Color',[0.4 0.4 0.4], 'MarkerSize', 6); hold(ax1,'on');
plot3(ax1, P(maskY,1),  P(maskY,2),  P(maskY,3),  'o', 'MarkerEdgeColor','none','MarkerFaceColor',[1 1 0], 'MarkerSize', 5);
axis(ax1,'equal'); grid(ax1,'on'); rotate3d(ax1,'on');
xlabel(ax1,'X'); ylabel(ax1,'Y'); zlabel(ax1,'Z');
title(ax1,'Rotate freely. Highlighted points are +Y (YELLOW). Which direction is that?');
legend(ax1,{'Other points','+Y hemisphere'},'Location','northeastoutside');

choices = {'Anterior','Posterior','Medial','Lateral','Superior','Inferior'};
dirY = ask_dir_menu('Which anatomical direction does the YELLOW hemisphere point toward?', choices);
% dirY = 'Posterior'; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[axY, sY] = dir_to_target(dirY);

if ishghandle(fig1), close(fig1); end

% ---------- Step 2: +Z hemisphere (red) ----------
fig2 = figure('Position',[ (scr(3)-w)/2, (scr(4)-h)/2, w, h ], ...
              'Color','w', 'Name','Step 2: +Z Hemisphere (Red)');
ax2  = axes('Parent',fig2);

maskZ = P(:,3) > 0;
if ~any(maskZ)
    maskZ = P(:,3) >= 0;      % fallback if all Z<=0
end
plot3(ax2, P(~maskZ,1), P(~maskZ,2), P(~maskZ,3), '.', 'Color',[0.4 0.4 0.4], 'MarkerSize', 6); hold(ax2,'on');
plot3(ax2, P(maskZ,1),  P(maskZ,2),  P(maskZ,3),  'o', 'MarkerEdgeColor','none','MarkerFaceColor',[1 0 0], 'MarkerSize', 5);
axis(ax2,'equal'); grid(ax2,'on'); rotate3d(ax2,'on');
xlabel(ax2,'X'); ylabel(ax2,'Y'); zlabel(ax2,'Z');
title(ax2,'Rotate freely. Highlighted points are +Z (RED). Which direction is that?');
legend(ax2,{'Other points','+Z hemisphere'},'Location','northeastoutside');

dirZ = ask_dir_menu('Which anatomical direction does the RED hemisphere point toward?', choices);
% dirZ = 'Superior'; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[axZ, sZ] = dir_to_target(dirZ);

if ishghandle(fig2), close(fig2); end

% ---------- Build mapping from WORLD axes -> TARGET axes ----------
% Columns = world axes [X Y Z]; rows = target axes [X(ML) Y(AP) Z(SI)]
% Fill Y and Z from answers; infer X to the remaining target axis.
M = zeros(3,3);
M(axY,2) = sY;        % world +Y -> chosen target axis/sign
M(axZ,3) = sZ;        % world +Z -> chosen target axis/sign

axes_used = unique([axY, axZ]);
remaining = setdiff(1:3, axes_used);
if isempty(remaining), remaining = 1; end
axX = remaining(1);
M(axX,1) = +1;        % provisional sign for world +X

% Laterality: Right => +X is lateral (flip X after mapping)
if side_indx == 1
    Lflip = diag([-1 1 1]);   % flip X
else
    Lflip = eye(3);
end

R = Lflip * M;

% Ensure proper rotation (no reflection)
if det(R) < 0
    M(axX,1) = -M(axX,1);
    R = Lflip * M;
end

% ---------- Apply rotation about origin ----------
nodes_aligned = (R * P')';

end

% ================= helpers =================
function dir = ask_dir_menu(prompt, choices)
idx = menu(prompt, choices{:});
if idx == 0
    error('Selection cancelled.');
end
dir = choices{idx};
end

function [ax_idx, sgn] = dir_to_target(dirstr)
% Target basis: X=ML, Y=AP, Z=SI (pre-laterality; Right will flip X)
switch lower(strtrim(dirstr))
    case 'anterior', ax_idx = 2; sgn = +1;  % +Y
    case 'posterior',ax_idx = 2; sgn = -1;  % -Y
    case 'medial',   ax_idx = 1; sgn = +1;  % +X
    case 'lateral',  ax_idx = 1; sgn = -1;  % -X
    case 'superior', ax_idx = 3; sgn = +1;  % +Z
    case 'inferior', ax_idx = 3; sgn = -1;  % -Z
    otherwise, error('Unknown selection: %s', dirstr);
end
end
