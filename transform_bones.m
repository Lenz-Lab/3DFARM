function [out_rotated, bonestl_transformed, bonestl_saltztransformed, out_saltzrotated] = ...
    transform_bones(T_transform, boneNames, bonestl, out)
%TRANSFORM_BONES  Apply a transform to bones & landmarks, plus Saltzman view.
%
% Inputs
%   T_transform : 4x4 homogeneous transform (preferred) or 3x3 rotation.
%   boneNames   : cellstr of bone field names to process (e.g., {'Talus','Calcaneus','Tibia'}).
%                 If empty or missing, defaults to fieldnames(bonestl).
%   bonestl     : struct of triangulation objects, e.g. bonestl.Talus, each with .Points and .ConnectivityList
%   out         : struct of Nx3 landmark arrays per bone (e.g., out.Talus, out.Calcaneus, ...)
%
% Outputs
%   out_rotated             : struct like 'out', transformed by T_transform
%   bonestl_transformed     : struct like 'bonestl', transformed by T_transform
%   bonestl_saltztransformed: struct like 'bonestl_transformed' but with Saltzman X-rotation (+20°)
%   out_saltzrotated        : struct like 'out_rotated' but with Saltzman X-rotation (+20°)
%
% Notes
% - Saltzman rotation is +20° about the X-axis (right-hand rule).
% - Safe for missing fields in 'out' (skips gracefully).
% - No toolbox dependencies (uses basic trig for rotation).

% ----- Inputs & defaults -----
if nargin < 2 || isempty(boneNames)
    boneNames = fieldnames(bonestl);
end
if isstring(boneNames); boneNames = cellstr(boneNames); end

% Validate transform
if ~ismatrix(T_transform) || ~(all(size(T_transform)==[4,4]) || all(size(T_transform)==[3,3]))
    error('T_transform must be 4x4 (homogeneous) or 3x3 (rotation-only).');
end

% Initialize outputs
bonestl_transformed      = struct();
out_rotated              = struct();
bonestl_saltztransformed = struct();
out_saltzrotated         = struct();

% Saltzman (+20° about X) as a 3x3 rotation
c = cosd(20); s = sind(20);
Saltz_Rx = [1 0 0; 0 c -s; 0 s c];

% ----- Main transform for each requested bone -----
for i = 1:numel(boneNames)
    boneName = boneNames{i};

    % Skip if the bone is not present in bonestl
    if ~isfield(bonestl, boneName)
        warning('Bonestl is missing field "%s"; skipping.', boneName);
        continue;
    end

    % Transform bone surface
    triIn = bonestl.(boneName);
    if ~isa(triIn, 'triangulation')
        error('bonestl.%s must be a triangulation object.', boneName);
    end
    P = triIn.Points;             % Nx3
    P_T = apply_T(P, T_transform);
    bonestl_transformed.(boneName) = triangulation(triIn.ConnectivityList, P_T);

    % Transform bone-specific landmarks if present
    if isfield(out, boneName)
        outP = out.(boneName);
        if size(outP,2) ~= 3
            error('out.%s must be an Nx3 array.', boneName);
        end
        out_rotated.(boneName) = apply_T(outP, T_transform);
    end
end

% ----- Saltzman view for specific bones -----
saltzTargets = {'Talus','Calcaneus','Tibia'};
for i = 1:numel(boneNames)
    boneName = boneNames{i};

    if ~ismember(boneName, saltzTargets)
        % Only produce Saltzman outputs for these targets
        continue;
    end

    % Need the transformed bone to exist
    if ~isfield(bonestl_transformed, boneName)
        continue;
    end

    % Apply 20° X-rotation to transformed bone
    triIn2 = bonestl_transformed.(boneName);
    P2 = triIn2.Points;                 % already transformed by T_transform
    P2_saltz = (Saltz_Rx * P2.').';     % pure rotation
    bonestl_saltztransformed.(boneName) = triangulation(triIn2.ConnectivityList, P2_saltz);

    % Apply to transformed landmarks if present
    if isfield(out_rotated, boneName)
        outP2 = out_rotated.(boneName);
        out_saltzrotated.(boneName) = (Saltz_Rx * outP2.').';
    end
end

% Helper: apply T (4x4 or 3x3) to Nx3 points
    function P2 = apply_T(P, T)
        if isempty(P); P2 = P; return; end
        if all(size(T)==[4,4])
            P2 = (T * [P, ones(size(P,1),1)]').';
            P2 = P2(:,1:3);
        else
            % 3x3 rotation only
            P2 = (T * P.').';
        end
    end

end
