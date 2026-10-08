function [aligned_nodes, R_total, T_total] = icp_complete(q,p,template_conlist,iterations,trouble)

nodes_template = q;
nodes = p;

%% Performing ICP alignment
% This is the initial alignment with no rotation.
% Two different icp approaches are used, the first includeds the faces and
% the second is just the points.
format long g

% Rotations
if trouble == 1
    r.r0 = eye(3);
else
    r.r0 = eye(3);
    r.rx = rot_x(90);
    r.rxx = rot_x(180);
    r.rxxx = rot_x(270);
    r.ry = rot_y(90);
    r.ryyy = rot_y(270);
    r.rz = rot_z(90);
    r.rzz = rot_z(180);
    r.rzzz = rot_z(270);
    r.rxxxy = rot_x(270) * rot_y(90);
    r.rxxxyyy = rot_x(270) * rot_y(270);
    r.rxxxz = rot_x(270) * rot_z(90);
    r.rxxxzzz = rot_x(270) * rot_z(270);
    r.rxy = rot_x(90) * rot_y(90);
    r.rxyyy = rot_x(90) * rot_y(270);
    r.rxz = rot_x(90) * rot_z(90);
    r.rxxxyy = rot_x(270) * rot_y(180);
    r.rxxy = rot_x(180) * rot_y(90);
    r.rxxyyy = rot_x(180) * rot_y(270);
    r.rxxz = rot_x(180) * rot_z(90);
    r.rxxzzz = rot_x(180) * rot_z(270);
    r.rxxxzzz = rot_x(270) * rot_z(270);
end

% r.r0 = eye(3);
% r.rx = rot_x(90);
% r.rxx = rot_x(180);
% r.rxxx = rot_x(270);
% r.ry = rot_y(90);
% r.ryy = rot_y(180);
% r.ryyy = rot_y(270);
% r.rz = rot_z(90);
% r.rzz = rot_z(180);
% r.rzzz = rot_z(270);
% r.rxy = rot_x(90) * rot_y(90);
% r.rxyy = rot_x(90) * rot_y(180);
% r.rxyyy = rot_x(90) * rot_y(270);
% r.rxxy = rot_x(180) * rot_y(90);
% r.rxxyy = rot_x(180) * rot_y(180);
% r.rxxyyy = rot_x(180) * rot_y(270);
% r.rxxxy = rot_x(270) * rot_y(90);
% r.rxxxyy = rot_x(270) * rot_y(180);
% r.rxxxyyy = rot_x(270) * rot_y(270);
% r.rxz = rot_x(90) * rot_z(90);
% r.rxzz = rot_x(90) * rot_z(180);
% r.rxzzz = rot_x(90) * rot_z(270);
% r.rxxz = rot_x(180) * rot_z(90);
% r.rxxzz = rot_x(180) * rot_z(180);
% r.rxxzzz = rot_x(180) * rot_z(270);
% r.rxxxz = rot_x(270) * rot_z(90);
% r.rxxxzz = rot_x(270) * rot_z(180);
% r.rxxxzzz = rot_x(270) * rot_z(270);
% r.ryx = rot_y(90) * rot_x(90);
% r.ryxx = rot_y(90) * rot_x(180);
% r.ryxxx = rot_y(90) * rot_x(270);
% r.ryyx = rot_y(180) * rot_x(90);
% r.ryyxx = rot_y(180) * rot_x(180);
% r.ryyxxx = rot_y(180) * rot_x(270);
% r.ryyyx = rot_y(270) * rot_x(90);
% r.ryyyxx = rot_y(270) * rot_x(180);
% r.ryyyxxx = rot_y(270) * rot_x(270);
% r.ryz = rot_y(90) * rot_z(90);
% r.ryzz = rot_y(90) * rot_z(180);
% r.ryzzz = rot_y(90) * rot_z(270);
% r.ryyz = rot_y(180) * rot_z(90);
% r.ryyzz = rot_y(180) * rot_z(180);
% r.ryyzzz = rot_y(180) * rot_z(270);
% r.ryyyz = rot_y(270) * rot_z(90);
% r.ryyyzz = rot_y(270) * rot_z(180);
% r.ryyyzzz = rot_y(270) * rot_z(270);
% r.rzx = rot_z(90) * rot_x(90);
% r.rzxx = rot_z(90) * rot_x(180);
% r.rzxxx = rot_z(90) * rot_x(270);
% r.rzzx = rot_z(180) * rot_x(90);
% r.rzzxx = rot_z(180) * rot_x(180);
% r.rzzxxx = rot_z(180) * rot_x(270);
% r.rzzzx = rot_z(270) * rot_x(90);
% r.rzzzxx = rot_z(270) * rot_x(180);
% r.rzzzxxx = rot_z(270) * rot_x(270);
% r.rzy = rot_z(90) * rot_y(90);
% r.rzyy = rot_z(90) * rot_y(180);
% r.rzyyy = rot_z(90) * rot_y(270);
% r.rzzy = rot_z(180) * rot_y(90);
% r.rzzyy = rot_z(180) * rot_y(180);
% r.rzzyyy = rot_z(180) * rot_y(270);
% r.rzzzy = rot_z(270) * rot_y(90);
% r.rzzzyy = rot_z(270) * rot_y(180);
% r.rzzzyyy = rot_z(270) * rot_y(270);

fields = fieldnames(r);
% iterations_temp = 1;
% for n = 1:numel(fields)
%     rot = r.(fields{n}); % Access each rotation matrix using the field name
%     rotnodes = nodes*rot; % Multiple nodes by rotation matrix
%     [~,~,error_temp] = icp(nodes_template',rotnodes', iterations_temp,'Matching','kDtree','EdgeRejection',logical(1)); % Perform small ICP
%     E_short.(fields{n}) = error_temp(end); % Save the lowest error
% end
% % Convert the structure 'E' to a cell array for easier sorting
% E_short_fields = fieldnames(E_short);
% E_short_values = struct2array(E_short);
% % Find the indices of the 5 smallest error values
% [~, idx_smallest] = mink(E_short_values, 5);
% % Get the 5 corresponding field names (rotation matrices)
% smallest_fields = E_short_fields(idx_smallest);
% % Rerun the loop with iterations on the 5 smallest error rotations
for i = 1:numel(fields)
    field_name = fields{i};  % Get the field name of the current rotation
    rot = r.(field_name);  % Access the corresponding rotation matrix
    rotnodes = nodes * rot;  % Multiply nodes by the rotation matrix
    % [R_temp,T_temp,E_temp] = icp(nodes_template',rotnodes', iterations,'Matching','kDtree','EdgeRejection',logical(1));
    % [Rwr_temp,Twr_temp,Ewr_temp] = icp(nodes_template',rotnodes', iterations,'Matching','kDtree','WorstRejection',0.1);
    [R_temp,T_temp,E_temp] = icp(nodes_template',rotnodes', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',template_conlist);
    % [Rwr_temp,Twr_temp,Ewr_temp] = icp(nodes_template',rotnodes', iterations,'Matching','kDtree','WorstRejection',0.1);
    Ewr_temp = 1000;
    if E_temp(end) < Ewr_temp(end)
        R.(field_name) = R_temp;
        T.(field_name) = T_temp;
        E.(field_name) = E_temp(end);
    else
        R.(field_name) = Rwr_temp;
        T.(field_name) = Twr_temp;
        E.(field_name) = Ewr_temp(end);
    end
end

% Find the smallest error value and corresponding field name
E_values = struct2array(E);  % Convert the structure 'E' to a regular array of error values
E_fields = fieldnames(E);    % Get the list of field names from 'E'
[~, idx_smallest] = min(E_values);  % Find the index of the smallest error value
smallest_field = E_fields{idx_smallest};  % Get the corresponding field name

% Retrieve the corresponding R, T, and rotation matrix
best_R = R.(smallest_field);  % The best R matrix
best_T = T.(smallest_field);  % The best T vector
best_rotation_matrix = r.(smallest_field);  % The rotation matrix from the original structure
% Perform the final alignment calculation
aligned_nodes = (best_R * ((nodes*best_rotation_matrix)') + repmat(best_T, 1, length(nodes')))';  % Align the nodes

% Combined rigid transform so other points can be aligned: aligned = (R_total*p' + T_total)'
R_total = best_R * best_rotation_matrix';
T_total = best_T;
% % Store the results for the final transformation
% iflip = best_rotation_matrix;  % The rotation matrix used for alignment
% iR = best_R;  % The best R matrix
% iT = best_T;  % The best T vector

%% Visualize proper alignment
% figure()
% plot3(nodes_template(:,1),nodes_template(:,2),nodes_template(:,3),'.k')
% hold on
% plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'.b')
% xlabel('X')
% ylabel('Y')
% zlabel('Z')
% axis equal

%% Helper Functions
% Rotation matrices about the x, y, and z axes (angle in degrees)
function R = rot_x(deg)
R = [1 0 0; 0 cosd(deg) -sind(deg); 0 sind(deg) cosd(deg)];

function R = rot_y(deg)
R = [cosd(deg) 0 sind(deg); 0 1 0; -sind(deg) 0 cosd(deg)];

function R = rot_z(deg)
R = [cosd(deg) -sind(deg) 0; sind(deg) cosd(deg) 0; 0 0 1];
