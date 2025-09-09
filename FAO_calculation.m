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
        % viewv = [0 90];
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
    % view(viewv);
    % Set camera properties:
    camtarget(targetPoint);   % The point the camera looks at
    campos(camPos);           % Position the camera along the cross product direction
    camlight HEADLIGHT;
    material dull;
    axis equal;
    xlabel('x');
    ylabel('y');
    zlabel('z');
    % Plot the original talus point
    plot3(talus_point(:, 1), talus_point(:, 2), talus_point(:, 3), '.', 'MarkerSize', 30);
    % compute vectors lying on triangluar foot plane
    v1 = endA - startB;
    v2 = endB - startB;
    % compute normal vector to plane
    normal_vector = cross(v1,v2);
    % Normalize the vector
    normal_vector = normal_vector / norm(normal_vector);
    % Compute the equation of the plane
    D = dot(normal_vector, startB);
    % Calculate new z-coordinate for the plane at the same x and y as the talus point
    % Uses plane equation Ax + By + Cz = D and solves for z
    new_z = (D - normal_vector(1) * talus_point(1) - normal_vector(2) * talus_point(2)) / normal_vector(3);
    % Define the new point on the plane with the same x and y coordinates as talus point
    intersection_point = [talus_point(1), talus_point(2), new_z];
    % plot intersection point
    plot3(intersection_point(1), intersection_point(2), intersection_point(3), '.', 'MarkerSize', 30);
    % define bisecting line and direction
    end_C = (endA + endB) / 2;
    bisecting_direction = end_C - startB;
    % Normalize
    bisecting_direction = bisecting_direction / norm(bisecting_direction);
    % Compute a vector perpendicular to bisecting_line in the plane
    perpendicular_direction = cross(normal_vector, bisecting_direction);
    % Define the perpendicular line passing through intersection_point
    % Find the intersection of the perpendicular line with bisecting_line
    % Solve for t and u where the two lines intersect
    A = [perpendicular_direction', -bisecting_direction'];
    b = (startB - intersection_point)';
    % Solve for t and u
    params = A \ b;
    % Parameter for perpendicular line
    T = params(1);
    % Parameter for bisecting line
    u = params(2);
    % Calculate the intersection point
    intersection_on_bisecting_line = startB + u * bisecting_direction;
    % Plot point
    plot3(intersection_on_bisecting_line(1), intersection_on_bisecting_line(2), intersection_on_bisecting_line(3),'.', 'MarkerSize', 30);
    % Calculate angle between the vectors
    angle = calculate_angle_between(startA, endA, startB, endB);
    % Plot vector arrows
    plot_vector_arrow(startA, endA, [0 0 1]);
    plot_vector_arrow(startB, endB, [1 0 0]);
    plot_vector_arrow(startA, end_C, [0 1 0]);
    plot3(end_C(1), end_C(2), end_C(3),'.', 'MarkerSize', 30);
    % Calculate distances
    talus_distance = sqrt((intersection_point(1) - intersection_on_bisecting_line(1))^2 + ...
                          (intersection_point(2) - intersection_on_bisecting_line(2))^2 + ...
                          (intersection_point(3) - intersection_on_bisecting_line(3))^2);
    % flip sign based on foot laterality
    if intersection_point(1) < intersection_on_bisecting_line(1) && side_indx == 1
        talus_distance = talus_distance * -1;
    end
    foot_distance = sqrt((end_C(1) - startA(1))^2 + (end_C(2) - startA(2))^2 + (end_C(3) - startA(3))^2);
    % Compute FAO
    FAO = (talus_distance / foot_distance)*100;
end
