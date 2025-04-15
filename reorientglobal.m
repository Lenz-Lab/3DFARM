function rotmat = reorientglobal(out)

% % Define the local coordinate system vectors of the bone
% ML = out.Talus(6,:) - out.Talus(5,:); % Medial-Lateral vector
% AP = out.Talus(2,:) - out.Talus(1,:); % Anterior-Posterior vector
% SI = out.Talus(4,:) - out.Talus(3,:); % Superior-Inferior vector

av_origin = (out.Talus(1,:) + out.Calcaneus(1,:) + out.Metatarsal1(1,:))/3;
AP = (out.Talus(2,:) + out.Calcaneus(2,:) + out.Metatarsal1(2,:))/3 - av_origin;
SI = (out.Talus(4,:) + out.Calcaneus(4,:) + out.Metatarsal1(4,:))/3 - av_origin;
ML = (out.Talus(6,:) + out.Calcaneus(6,:) + out.Metatarsal1(6,:))/3 - av_origin;

% Normalize vectors
ML = ML / norm(ML);
AP = AP / norm(AP);
SI = SI / norm(SI);

L = [ML', AP', SI'];

% Define global axes
global_X = [1, 0, 0];
global_Y = [0, -1, 0]; % Adjusted if Y direction is flipped
global_Z = [0, 0, 1];

G = [global_X', global_Y', global_Z'];

rotmat = G * L';

end