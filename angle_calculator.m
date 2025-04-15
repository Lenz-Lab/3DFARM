function angle = angle_calculator(startA, endA, startB, endB, bone1, bone2, plane, side_indx, viewer, varargin)

    % Check if 'measurement' was provided (using varargin for optional input)
    if nargin > 9
        measurement = varargin{1};
    else
        measurement = '';  % Default to an empty string or any default value
    end

    if plane == "yz"
        % viewv = [90 0];
        ref_axis = [1, 0, 0]; % X-axis as the reference for YZ plane (Plantarflexion/Dorsiflexion)
    elseif plane == "xz"
        % viewv = [0 0];
        ref_axis = [0, 1, 0]; % Y-axis as the reference for XZ plane (Inversion/Eversion)
    elseif plane == "xy"
        % viewv = [90 90];
        ref_axis = [0, 0, 1]; % Z-axis as the reference for XY plane (Internal/External rotation)
    else
        % viewv = [90 90];
        ref_axis = [0, 0, 0]; % No reference for 3D case
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
    camPos = targetPoint + distance * crossVec_norm

    % If measurement is specified, adjust the ref_axis accordingly
    if strcmp(measurement, "SVA")
        ref_axis = [0, 0, 1];
    end

    figure()
    patch('Faces',bone1.ConnectivityList,'Vertices',bone1.Points,...
        'FaceColor', [0.85 0.85 0.85], ...
        'EdgeColor','none',...
        'FaceLighting','gouraud',...
        'AmbientStrength', 0.15);
    alpha(0.5)
    hold on
    patch('Faces',bone2.ConnectivityList,'Vertices',bone2.Points,...
        'FaceColor', [0.85 0.85 0.85], ...
        'EdgeColor','none',...
        'FaceLighting','gouraud',...
        'AmbientStrength', 0.15);
    alpha(0.5)
    % view(viewv)
    % Set camera properties:
    camtarget(targetPoint);   % The point the camera looks at
    campos(camPos);           % Position the camera along the cross product direction
    camlight HEADLIGHT
    material('dull');
    axis equal
    axis off
    set(gca, 'XTick', [], 'YTick', [], 'ZTick', [])

    plot_arrow(startA, endA, [0 0 1]);
    plot_arrow(startB, endB, [1 0 0]);

    angle = ang_bet(startA, endA, startB, endB, plane, ref_axis, side_indx);

    function plot_arrow(origin, direction, color)
        dir_normalized = 50 * (direction - origin) / norm(direction - origin);
        arrow(origin, origin + dir_normalized, 'FaceColor', color, 'EdgeColor', color, 'LineWidth', 2, 'Length', 7);
    end

    function angle_between = ang_bet(startA, endA, startB, endB, plane, ref_axis, side_indx)
        % Calculate the direction vectors
        vector1 = endA - startA;
        vector2 = endB - startB;

        if plane == "xy"
            vector1_new = [vector1(1), vector1(2), 0];
            vector2_new = [vector2(1), vector2(2), 0];
        elseif plane == "xz"
            vector1_new = [vector1(1), 0, vector1(3)];
            vector2_new = [vector2(1), 0, vector2(3)];
        elseif plane == "yz"
            vector1_new = [0, vector1(2), vector1(3)];
            vector2_new = [0, vector2(2), vector2(3)];
        elseif plane == "3D"
            vector1_new = vector1;
            vector2_new = vector2;
        end

        % Calculate the cross product and dot product of the projected vectors
        cross_product = cross(vector1_new, vector2_new);
        dot_product = dot(vector1_new, vector2_new);

        % Calculate the angle using atan2d
        angle_between = atan2d(norm(cross_product), dot_product);

        % Adjust for lateralities (mirroring behavior for left bones)
        if plane == "yz"
            % Plantarflexion (negative) vs. Dorsiflexion (positive) - no mirroring needed
            sign_of_angle = dot(cross_product, ref_axis);
            if sign_of_angle > 0
                angle_between = -angle_between;
            end
        elseif plane == "xy"
            % Internal (negative) vs. External (positive) rotation - mirrored for left side
            sign_of_angle = dot(cross_product, ref_axis);
            if sign_of_angle > 0
                angle_between = -angle_between;
            end
            if side_indx == 2  % Left bone
                angle_between = -angle_between;  % Mirror for left side
            end
        elseif plane == "xz"
            % Inversion (negative) vs. Eversion (positive) - mirrored for left side
            sign_of_angle = dot(cross_product, ref_axis);
            if sign_of_angle > 0
                angle_between = -angle_between;
            end
            if side_indx == 2  % Left bone
                angle_between = -angle_between;  % Mirror for left side
            end
        end
    end
end
