function angle = angle_calculator(startA, endA, startB, endB, bone1, bone2, plane)
if plane == "yz"
    viewv = [90 0];
elseif plane == "xz"
    viewv = [0 0];
else
    viewv = [90 90];
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
view(viewv)
camlight HEADLIGHT
material('dull');
axis equal
axis off
set(gca, 'XTick', [], 'YTick', [], 'ZTick', [])
% xlabel('x')
% ylabel('y')
% zlabel('z')

plot_arrow(startA, endA, [0 0 1]);
plot_arrow(startB, endB, [1 0 0]);


angle = ang_bet(startA, endA, startB, endB, plane);


    function plot_arrow(origin, direction, color)
        dir_normalized = 50 * (direction - origin) / norm(direction - origin);
        arrow(origin, origin + dir_normalized, 'FaceColor', color, 'EdgeColor', color, 'LineWidth', 2, 'Length', 7);
    end

    function angle_between = ang_bet(startA, endA, startB, endB, plane)

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
    end
end