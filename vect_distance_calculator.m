function [distXZ, Q, segPts] = vect_distance_calculator(startA, endA, P, bone1, bone2, plane, side_indx, viewer, varargin)

if nargin > 9 && ~isempty(varargin{1})
    measurement = string(varargin{1});
else
    measurement = "";
end

% ------ Math ------
startA = startA(:).'; endA = endA(:).'; P = P(:).';
v  = endA - startA;
Ox = startA(1); Oy = startA(2); Oz = startA(3);
vx = v(1);     vy = v(2);     vz = v(3);
Px = P(1);     Py = P(2);     Pz = P(3);

% Sign factor: + if medial, − if lateral  // NEW
% Right (1): medial is -X => -1;  Left (2): medial is +X => +1
if side_indx == 1
    signFactor = -1;
else
    signFactor = +1;
end

if abs(vz) < eps
    if abs(Pz - Oz) > eps
        Q = [NaN NaN NaN];
        distXZ = NaN;                 % signed distance (NaN if unreachable)
        segPts = [NaN NaN NaN; NaN NaN NaN];
        warning('Direction has zero Z component and Z does not match P. Cannot reach Z = Pz.');
    else
        if abs(vx) < eps
            Q = startA;
        else
            t = (Px - Ox)/vx;
            Q = startA + t.*v;
        end
        dx = Q(1) - Px;               % delta in X at constant Z          // NEW
        distXZ = signFactor * dx;     % signed by medial/lateral          // NEW
        segPts = [Px Py Pz; Q(1) Py Pz];
    end
else
    t = (Pz - Oz)/vz;
    Q = startA + t.*v;
    dx = Q(1) - Px;                   % delta in X at constant Z          // NEW
    distXZ = signFactor * dx;         % signed by medial/lateral          // NEW
    segPts = [Px Py Pz; Q(1) Py Pz];
end

% ------ Plotting ------
if nargin >= 5 && ~isempty(bone1) && ~isempty(bone2)
    figure('Color','w'); hold on

    p1 = patch('Faces',bone1.ConnectivityList,'Vertices',bone1.Points,...
        'FaceColor',[0.85 0.85 0.85],'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
    alpha(p1,0.5)
    p2 = patch('Faces',bone2.ConnectivityList,'Vertices',bone2.Points,...
        'FaceColor',[0.85 0.85 0.85],'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
    alpha(p2,0.5)

    % Vector from startA to Q
    if all(isfinite(Q))
        plot3([startA(1) Q(1)], [startA(2) Q(2)], [startA(3) Q(3)], '-', 'LineWidth', 2);
    else
        plot3([startA(1) endA(1)], [startA(2) endA(2)], [startA(3) endA(3)], '-', 'LineWidth', 2);
    end

    % Point P
    plot3(Px, Py, Pz, 'o', 'MarkerSize', 8, 'LineWidth', 1.5, 'Color', [0 0 0]);

    % Black connector at constant Z
    if all(isfinite(Q))
        plot3(segPts(:,1), segPts(:,2), segPts(:,3), '-', 'LineWidth', 2, 'Color', [0 0 0]);
    end

    % View by plane (your convention)
    if ischar(plane), plane = string(plane); end
    plane = lower(plane);
    switch plane
        case "xy", viewv = [0 90];
        case "xz", viewv = [0 0];
        case "yz"
            viewv = [-90 0]; if side_indx == 2, viewv = [90 0]; end
        otherwise, viewv = [90 90];
    end
    view(viewv);

    camlight HEADLIGHT; material dull
    axis equal off; box off

    % Title shows signed distance  // CHANGED
    title_str = sprintf('Signed XZ distance = %.4f', distXZ);
    if measurement ~= "" , title_str = measurement + "  —  " + title_str; end
    title(title_str, 'Interpreter','none')
end
end
