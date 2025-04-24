function rotmat = reorient90(out)

% % Define the local coordinate system vectors of the bone
ML = out.Talus(6,:) - out.Talus(5,:); % Medial-Lateral vector
AP = out.Talus(2,:) - out.Talus(1,:); % Anterior-Posterior vector
SI = out.Talus(4,:) - out.Talus(3,:); % Superior-Inferior vector

% av_origin = (out.Talus(1,:) + out.Calcaneus(1,:) + out.Metatarsal1(1,:))/3;
% AP = (out.Talus(2,:) + out.Calcaneus(2,:) + out.Metatarsal1(2,:))/3 - av_origin;
% SI = (out.Talus(4,:) + out.Calcaneus(4,:) + out.Metatarsal1(4,:))/3 - av_origin;
% ML = (out.Talus(6,:) + out.Calcaneus(6,:) + out.Metatarsal1(6,:))/3 - av_origin;

% Normalize vectors
ML = ML / norm(ML);
AP = AP / norm(AP);
SI = SI / norm(SI);

% Define global axes
global_X = [1, 0, 0];
global_Y = [0, -1, 0]; % Adjusted if Y direction is flipped
global_Z = [0, 0, 1];

% Compute angles between local and global axes
theta_AP = acosd(dot(AP, global_Y) / (norm(AP) * norm(global_Y)));
theta_SI = acosd(dot(SI, global_Z) / (norm(SI) * norm(global_Z)));

% Define a tolerance for alignment
tolerance = 45; % Degrees

% If within tolerance, return identity matrix
if theta_AP < tolerance && theta_SI < tolerance
    rotmat = eye(3);
    return;
end

% Initialize best rotation matrix
best_rotmat = eye(3);
min_misalignment = inf;

% Define all 90-degree permutations
rotation_angles = [90, 180, 270];
rotation_matrices = [];

% Generate all rotation matrices for X, Y, and Z
for angle = rotation_angles
    rotation_matrices = [rotation_matrices, {rotx(angle)}, {roty(angle)}, {rotz(angle)}];
end

% Try all rotations and find the best one
for i = 1:length(rotation_matrices)
    R = rotation_matrices{i}; % Get rotation matrix

    % Rotate each vector
    AP_rot = (R * AP')';
    SI_rot = (R * SI')';

    % Compute new angles
    new_theta_AP = acosd(dot(AP_rot, global_Y) / (norm(AP_rot) * norm(global_Y)));
    new_theta_SI = acosd(dot(SI_rot, global_Z) / (norm(SI_rot) * norm(global_Z)));

    % Check if this rotation improves alignment
    total_misalignment = new_theta_AP + new_theta_SI;
    if total_misalignment < min_misalignment
        min_misalignment = total_misalignment;
        best_rotmat = R;
    end
end

% Return the best rotation matrix found
rotmat = best_rotmat;

end