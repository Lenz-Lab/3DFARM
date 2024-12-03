function FAO = FAO_calculation(startA, endA, startB, endB, bone1, bone2, bone3, bone4, plane, talus_point, z_min_coords) % add bone4, talus point: out(21,:)
if plane == "xy"
    viewv = [0 90];
end

function angle_between = ang_bet(startA, endA, startB, endB, plane)

        % Calculate the direction vectors for plane = xy
        vector1 = endA - startA;
        vector2 = endB - startB;

        vector1_new = [vector1(1), vector1(2), 0];
        vector2_new = [vector2(1), vector2(2), 0];

        % Calculate the cross product and dot product of the projected vectors
        cross_product = cross(vector1_new, vector2_new);
        dot_product = dot(vector1_new, vector2_new);

        % Calculate the angle using atan2d
        angle_between = atan2d(norm(cross_product), dot_product);
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
patch('Faces',bone3.ConnectivityList,'Vertices',bone3.Points,...
    'FaceColor', [0.85 0.85 0.85], ...
    'EdgeColor','none',...
    'FaceLighting','gouraud',...
    'AmbientStrength', 0.15);
alpha(0.5)
patch('Faces',bone4.ConnectivityList,'Vertices',bone4.Points,...
    'FaceColor', [0.85 0.85 0.85], ...
    'EdgeColor','none',...
    'FaceLighting','gouraud',...
    'AmbientStrength', 0.15);
alpha(0.5)
view(viewv)
camlight HEADLIGHT
material('dull');
axis equal
xlabel('x')
ylabel('y')
zlabel('z')
plot3(talus_point(:,1), talus_point(:,2), talus_point(:,3), '.', 'MarkerSize', 30)
patch('Vertices', z_min_coords, 'Faces', [1 2 3], 'FaceColor', 'cyan', 'FaceAlpha', 0.5);

% moving point on talus to be on triangle
normal_vector = cross(z_min_coords(2,:) - z_min_coords(1,:), z_min_coords(3,:) - z_min_coords(1,:));
d = -dot(normal_vector, z_min_coords(1,:)); % Distance from origin
new_z = -(normal_vector(1) * talus_point(:,1) + normal_vector(2) * talus_point(:,2) + d) / normal_vector(3);
new_talus_point = [talus_point(:,1), talus_point(:,2), new_z];

% plot talus point on triangle
hold on
plot3(new_talus_point(1), new_talus_point(2), new_talus_point(3), '.', 'MarkerSize', 30);

% find arrows and bisecting arrow
angle = ang_bet(startA, endA, startB, endB, plane);
endC = (endA + endB)/2;

plot_arrow(startA, endA, [0 0 1]);
plot_arrow(startB, endB, [1 0 0]);
plot_arrow(startA, endC, [0 1 0]);

function plot_arrow(origin, direction, color)
        dir_normalized = 50 * (direction - origin) / norm(direction - origin);
        arrow(origin, origin + dir_normalized, 'FaceColor', color, 'EdgeColor', color, 'LineWidth', 2, 'Length', 7);
    end

% calculate slope of bisecting line
m = (endC(:,2) - startA(:,2))/(endC(:,1) - startA(:,1));
% y-intercept
b = startA(:,2) - m*startA(:,1);

% slope of perpendicular line
m_perp = -1/m;
% equation of perpendicular line passing through talus point
% calculating y intercept based on point slope form
b_perp = new_talus_point(:,2) - m_perp*new_talus_point(:,1);

% solve for intersection of the two lines by setting equations equal
x_intersect = (b_perp - b)/ (m-m_perp);
y_intersect = m*x_intersect + b;
plot3(x_intersect,y_intersect, new_talus_point(3), '.', 'MarkerSize', 30);

% use distance formula to calculate distance between points
talus_distance = sqrt((new_talus_point(1)-x_intersect)^2 + (new_talus_point(2)-y_intersect)^2 + (new_talus_point(3)-new_talus_point(3))^2);
foot_distance = sqrt((endC(1)-startA(1))^2 + (endC(2)-startA(2))^2 + (endC(3)-startA(3))^2);
FAO = talus_distance/foot_distance;

end


% plot(z_min_coords(1,1), z_min_coords(1,2), 'bo', 'MarkerSize', 10)
% plot(z_min_coords(2,1), z_min_coords(2,2), 'bo', 'MarkerSize', 10)
% plot(z_min_coords(3,1), z_min_coords(3,2), 'bo', 'MarkerSize', 10)