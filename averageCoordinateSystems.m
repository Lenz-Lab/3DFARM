function T_transform = averageCoordinateSystems(coordSys1, coordSys2, coordSys3, side_indx)
% AVERAGECOORDINATESYSTEMS Computes the average coordinate system from three 4x3 coordinate systems
% and returns a transformation matrix that maps points from the average coordinate system
% to a new coordinate system where the origin is at (0,0,0) and the axes are aligned as:
%   x-axis = ML, y-axis = AP, and z-axis = SI.
%
%   Each input coordinate system (coordSys) is a 4x3 matrix with rows:
%       Row 1: Origin (O)
%       Row 2: AP endpoint (defines AP vector)
%       Row 3: SI endpoint (defines SI vector)
%       Row 4: ML endpoint (used for verification; the ML axis is computed via cross product)
%
%   The function performs the following steps:
%       1. Average the origins.
%       2. Compute the directional vectors (AP and SI) from each coordinate system.
%       3. Average these directional vectors.
%       4. Orthonormalize to get a clean frame.
%       5. Reassign the axes so that:
%            x-axis = ML (computed as cross(AP, SI))
%            y-axis = AP
%            z-axis = SI
%       6. Compute the transformation matrix that re-centers the averaged coordinate system
%          to the origin (0,0,0) with the desired global axis alignment.
%
%   The output T_transform is a 4x4 homogeneous transformation matrix such that
%   for a point p (in global coordinates), the coordinates in the new centered system are:
%
%       p_new = T_transform * [p; 1]
%

    %% 1. Average the Origins
    % Extract origins as column vectors.
    O1 = coordSys1(1, :)';
    O2 = coordSys2(1, :)';
    O3 = coordSys3(1, :)';
    
    % Compute the average origin.
    O_avg = (O1 + O2 + O3) / 3;
    
    %% 2. Compute Directional Vectors (relative to each origin)
    % For each coordinate system, subtract the origin from the endpoint positions.
    % AP vector: row 2, SI vector: row 3, ML vector (given, but not used here) is row 4.
    AP1 = (coordSys1(2, :)' - O1);
    SI1 = (coordSys1(3, :)' - O1);

    AP2 = (coordSys2(2, :)' - O2);
    SI2 = (coordSys2(3, :)' - O2);

    AP3 = (coordSys3(2, :)' - O3);
    SI3 = (coordSys3(3, :)' - O3);
    
    %% 3. Average the Directional Vectors
    AP_avg = (AP1 + AP2 + AP3) / 3;
    SI_avg = (SI1 + SI2 + SI3) / 3;
    
    %% 4. Orthonormalize the Frame Based on AP and SI
    % a. Normalize the averaged AP vector.
    AP_n = AP_avg / norm(AP_avg);
    
    % b. Remove the AP component from SI_avg to orthogonalize and then normalize.
    SI_proj = dot(SI_avg, AP_n);  % projection of SI_avg along AP_n
    SI_orth = SI_avg - SI_proj * AP_n;
    SI_n = SI_orth / norm(SI_orth);
    
    % c. Compute the ML axis via cross product, so that the frame is right-handed.
    % Even if an ML endpoint was provided, here we enforce consistency via cross product.
    ML_n = cross(AP_n, SI_n);
    ML_n = ML_n / norm(ML_n);  % ensure unit length

    % if side_indx == 1
    %     ML_n = -ML_n;
    % end
    
    %% 5. Reassign the Axes to Match the Desired Global Alignment
    % We want the following mapping:
    %     Global x-axis = ML
    %     Global y-axis = AP
    %     Global z-axis = SI
    %
    % Build a rotation matrix R_new where the columns represent the
    % average coordinate system’s axes in global space ordered as:
    %   [ ML_n  AP_n  SI_n ]
    R_new = [ML_n, AP_n, SI_n];
    
    %% 6. Compute the Transformation Matrix
    % We now want a transformation that takes a point in the original global
    % coordinates and expresses it in the new coordinate system that is centered at
    % (0,0,0) with axes aligned to global x = ML, y = AP, and z = SI.
    %
    % This is achieved by first translating by -O_avg and then applying the rotation:
    %      p_new = R_new'*(p - O_avg)
    %
    % The corresponding homogeneous transformation matrix T_transform is:
    T_transform = [R_new', -R_new'*O_avg; 0 0 0 1];
end
