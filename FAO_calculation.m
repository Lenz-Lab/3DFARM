function FAO = FAO_calculation(startA, endA, startB, endB, bone1, bone2, bone3, bone4, plane, talus_point, z_min_coords, viewer, side_indx)
% FAO_calculation computes the foot and ankle offset based on given geometries.
% Inputs:
% - startA, endA: Vectors defining the first reference direction.
% - startB, endB: Vectors defining the second reference direction.
% - bone1, bone2, bone3, bone4: Structures containing bone geometries.
% - plane: String specifying the reference plane ('xy').
% - talus_point: Coordinates of the talus point.
% - z_min_coords: Coordinates of the minimum z-plane triangle.
% Output:
% - FAO: Calculated foot and ankle offset.
% Validate plane input and set the view

if plane == "xy"
    viewv = [0 90];
    ref_axis = [0, 0, 1]; % Z-axis as the reference for XY plane (Internal/External rotation)
else
    error('Currently, only the "xy" plane is supported.');
end

vector_A = viewer(:,4:6) - viewer(:,1:3);
vector_B = viewer(10:12) - viewer(:,7:9);

% Compute the cross product vector.
crossVec = cross(vector_A, vector_B);

% Normalize the cross product vector.
crossVec_norm = crossVec / norm(crossVec);

targetPoint = viewer(:,1:3);
distance = 100;

% Set the camera position along the cross product vector.
camPos = targetPoint + distance * crossVec_norm;

% Nested function to calculate the angle between two vectors
    function angle_between = calculate_angle_between(startA, endA, startB, endB)
        vector1 = endA - startA;
        vector2 = endB - startB;
        vector1_proj = [vector1(1), vector1(2), 0];
        vector2_proj = [vector2(1), vector2(2), 0];
        cross_product = cross(vector1_proj, vector2_proj);
        dot_product = dot(vector1_proj, vector2_proj);
        angle_between = atan2d(norm(cross_product), dot_product);
    end

% Helper function to visualize a bone
    function plot_bone(bone)
        patch('Faces', bone.ConnectivityList, 'Vertices', bone.Points, ...
            'FaceColor', [0.85 0.85 0.85], ...
            'EdgeColor', 'none', ...
            'FaceLighting', 'gouraud', ...
            'AmbientStrength', 0.15, ...
            'FaceAlpha', 0.5);
    end

% Helper function to plot arrows
    function plot_vector_arrow(origin, direction, color, scale)
        if nargin < 4, scale = 50; end
        dir_normalized = scale * (direction - origin) / norm(direction - origin);
        arrow(origin, origin + dir_normalized, 'FaceColor', color, 'EdgeColor', color, ...
            'LineWidth', 2, 'Length', 7);
    end

% Plot the bones
figure();
hold on;
plot_bone(bone1);
plot_bone(bone2);
plot_bone(bone3);
plot_bone(bone4);
view(viewv);
% Set camera properties:
% camtarget(targetPoint);   % The point the camera looks at
% campos(camPos);           % Position the camera along the cross product direction
camlight HEADLIGHT;
material dull;
axis equal;
xlabel('x');
ylabel('y');
zlabel('z');
axis off
set(gca, 'XTick', [], 'YTick', [], 'ZTick', [])

% Plot the original talus point
plot3(talus_point(:, 1), talus_point(:, 2), talus_point(:, 3), '.', 'MarkerSize', 30);

% Project the talus point onto the z-plane triangle
normal_vector = cross(z_min_coords(2, :) - z_min_coords(1, :), z_min_coords(3, :) - z_min_coords(1, :));
d = -dot(normal_vector, z_min_coords(1, :));
new_z = -(normal_vector(1) * talus_point(:, 1) + normal_vector(2) * talus_point(:, 2) + d) / normal_vector(3);
new_talus_point = [talus_point(:, 1), talus_point(:, 2), new_z];
plot3(new_talus_point(1), new_talus_point(2), new_talus_point(3), '.', 'MarkerSize', 30);

% Calculate angle between the vectors
angle = calculate_angle_between(startA, endA, startB, endB);

% Calculate the bisecting line and plot arrows
endC = (endA + endB) / 2;
plot_vector_arrow(startA, endA, [0 0 1]);
plot_vector_arrow(startB, endB, [1 0 0]);
plot_vector_arrow(startA, endC, [0 1 0]);

% Compute slope and intercept for bisecting and perpendicular lines
m = (endC(:, 2) - startA(:, 2)) / (endC(:, 1) - startA(:, 1));
b = startA(:, 2) - m * startA(:, 1);
m_perp = -1 / m;
b_perp = new_talus_point(:, 2) - m_perp * new_talus_point(:, 1);

% Find the intersection point
x_intersect = (b_perp - b) / (m - m_perp);
y_intersect = m * x_intersect + b;
plot3(x_intersect, y_intersect, new_talus_point(3), '.', 'MarkerSize', 30);

% Calculate distances
talus_distance = sqrt((new_talus_point(1) - x_intersect)^2 + ...
    (new_talus_point(2) - y_intersect)^2 + ...
    (new_talus_point(3) - new_talus_point(3))^2);

if new_talus_point(1) < x_intersect
    talus_distance = talus_distance * -1;
end

foot_distance = sqrt((endC(1) - startA(1))^2 + (endC(2) - startA(2))^2 + (endC(3) - startA(3))^2);

% Compute FAO
FAO = (talus_distance / foot_distance)*100;

% Account for side
if side_indx == 1
    FAO = -FAO;
end
end
