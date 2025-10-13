function [TR, TT, ER, t] = icp(q,p,varargin)
% Perform the Iterative Closest Point algorithm on three dimensional point
% clouds.
%
% [TR, TT] = icp(q,p)   returns the rotation matrix TR and translation
% vector TT that minimizes the distances from (TR * p + TT) to q.
% p is a 3xm matrix and q is a 3xn matrix.
%
% [TR, TT] = icp(q,p,k)   forces the algorithm to make k iterations
% exactly. The default is 10 iterations.
%
% [TR, TT, ER] = icp(q,p,k)   also returns the RMS of errors for k
% iterations in a (k+1)x1 vector. ER(0) is the initial error.
%
% [TR, TT, ER, t] = icp(q,p,k)   also returns the calculation times per
% iteration in a (k+1)x1 vector. t(0) is the time consumed for preprocessing.
%
% Additional settings may be provided in a parameter list:
%
% Boundary
%       {[]} | 1x? vector
%       If EdgeRejection is set, a vector can be provided that indexes into
%       q and specifies which points of q are on the boundary.
%
% EdgeRejection
%       {false} | true
%       If EdgeRejection is true, point matches to edge vertices of q are
%       ignored. Requires that boundary points of q are specified using
%       Boundary or that a triangulation matrix for q is provided.
%
% Extrapolation
%       {false} | true
%       If Extrapolation is true, the iteration direction will be evaluated
%       and extrapolated if possible using the method outlined by
%       Besl and McKay 1992.
%
% Matching
%       {bruteForce} | Delaunay | kDtree
%       Specifies how point matching should be done.
%       bruteForce is usually the slowest and kDtree is the fastest.
%       Note that the kDtree option is depends on the Statistics Toolbox
%       v. 7.3 or higher.
%
% Minimize
%       {point} | plane | lmaPoint
%       Defines whether point to point or point to plane minimization
%       should be performed. point is based on the SVD approach and is
%       usually the fastest. plane will often yield higher accuracy. It
%       uses linearized angles and requires surface normals for all points
%       in q. Calculation of surface normals requires substantial pre
%       proccessing.
%       The option lmaPoint does point to point minimization using the non
%       linear least squares Levenberg Marquardt algorithm. Results are
%       generally the same as in points, but computation time may differ.
%
% Normals
%       {[]} | n x 3 matrix
%       A matrix of normals for the n points in q might be provided.
%       Normals of q are used for point to plane minimization.
%       Else normals will be found through a PCA of the 4 nearest
%       neighbors.
%
% ReturnAll
%       {false} | true
%       Determines whether R and T should be returned for all iterations
%       or only for the last one. If this option is set to true, R will be
%       a 3x3x(k+1) matrix and T will be a 3x1x(k+1) matrix.
%
% Triangulation
%       {[]} | ? x 3 matrix
%       A triangulation matrix for the points in q can be provided,
%       enabling EdgeRejection. The elements should index into q, defining
%       point triples that act together as triangles.
%
% Verbose
%       {false} | true
%       Enables extrapolation output in the Command Window.
%
% Weight
%       {@(match)ones(1,m)} | Function handle
%       For point or plane minimization, a function handle to a weighting
%       function can be provided. The weighting function will be called
%       with one argument, a 1xm vector that specifies point pairs by
%       indexing into q. The weighting function should return a 1xm vector
%       of weights for every point pair.
%
% WorstRejection
%       {0} | scalar in ]0; 1[
%       Reject a given percentage of the worst point pairs, based on their
%       Euclidean distance.
%
% MaxRotationDeg
%       {Inf} | positive scalar (degrees)
%       Caps the net rotation angle (principal angle) relative to the initial pose.
%
% Martin Kjer and Jakob Wilm, Technical University of Denmark, 2012

% Use the inputParser class to validate input arguments.
inp = inputParser;

inp.addRequired('q', @(x)isreal(x) && size(x,1) == 3);
inp.addRequired('p', @(x)isreal(x) && size(x,1) == 3);

inp.addOptional('iter', 200, @(x)x > 0 && x < 10^5);

inp.addParamValue('Boundary', [], @(x)size(x,1) == 1);

inp.addParamValue('EdgeRejection', false, @(x)islogical(x));

inp.addParamValue('Extrapolation', false, @(x)islogical(x));

validMatching = {'bruteForce','Delaunay','kDtree'};
inp.addParamValue('Matching', 'bruteForce', @(x)any(strcmpi(x,validMatching)));

validMinimize = {'point','plane','lmapoint'};
inp.addParamValue('Minimize', 'point', @(x)any(strcmpi(x,validMinimize)));

inp.addParamValue('Normals', [], @(x)isreal(x) && size(x,1) == 3);

inp.addParamValue('NormalsData', [], @(x)isreal(x) && size(x,1) == 3);

inp.addParamValue('ReturnAll', false, @(x)islogical(x));

inp.addParamValue('Triangulation', [], @(x)isreal(x) && size(x,2) == 3);

inp.addParamValue('Verbose', false, @(x)islogical(x));

inp.addParamValue('Weight', @(x)ones(1,length(x)), @(x)isa(x,'function_handle'));

inp.addParamValue('WorstRejection', 0, @(x)isscalar(x) && x > 0 && x < 1);

inp.addParamValue('MaxRotationDeg', Inf, @(x)isreal(x) && isscalar(x) && x>0);   %%% ADDED

inp.parse(q,p,varargin{:});
arg = inp.Results;
clear('inp');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Actual implementation

% Allocate vector for RMS of errors in every iteration.
t = zeros(arg.iter+1,1);

% Start timer
tic;

Np = size(p,2);

% Transformed data point cloud
pt = p;

% Allocate vector for RMS of errors in every iteration.
ER = zeros(arg.iter+1,1);

% Initialize temporary transform vector and matrix.
T = zeros(3,1);
R = eye(3,3);

% Initialize total transform vector(s) and rotation matric(es).
TT = zeros(3,1, arg.iter+1);
TR = repmat(eye(3,3), [1,1, arg.iter+1]);

% If Minimize == 'plane', normals are needed
if (strcmp(arg.Minimize, 'plane') && isempty(arg.Normals))
    arg.Normals = lsqnormest(q,4);
end

% If Matching == 'Delaunay', a triangulation is needed
if strcmp(arg.Matching, 'Delaunay')
    DT = DelaunayTri(transpose(q));
end

% If Matching == 'kDtree', a kD tree should be built (req. Stat. TB >= 7.3)
if strcmp(arg.Matching, 'kDtree')
    kdOBJ = KDTreeSearcher(transpose(q));
end

% If edge vertices should be rejected, find edge vertices
if arg.EdgeRejection
    if isempty(arg.Boundary)
        bdr = find_bound(q, arg.Triangulation);
    else
        bdr = arg.Boundary;
    end
end

if arg.Extrapolation
    % Initialize total transform vector (quaternion ; translation vec.)
    qq = [ones(1,arg.iter+1);zeros(6,arg.iter+1)];
    % Allocate vector for direction change and change angle.
    dq = zeros(7,arg.iter+1);
    theta = zeros(1,arg.iter+1);
end

t(1) = toc;

% Go into main iteration loop
for k=1:arg.iter

    % Do matching
    switch arg.Matching
        case 'bruteForce'
            [match mindist] = match_bruteForce(q,pt);
        case 'Delaunay'
            [match mindist] = match_Delaunay(q,pt,DT);
        case 'kDtree'
            [match mindist] = match_kDtree(q,pt,kdOBJ);
    end

    % If matches to edge vertices should be rejected
    if arg.EdgeRejection
        p_idx = not(ismember(match, bdr));
        q_idx = match(p_idx);
        mindist = mindist(p_idx);
    else
        p_idx = true(1, Np);
        q_idx = match;
    end

    % If worst matches should be rejected
    if arg.WorstRejection
        edge = round((1-arg.WorstRejection)*sum(p_idx));
        pairs = find(p_idx);
        [~, idx] = sort(mindist);
        p_idx(pairs(idx(edge:end))) = false;
        q_idx = match(p_idx);
        mindist = mindist(p_idx);
    end

    if k == 1
        ER(k) = sqrt(sum(mindist.^2)/length(mindist));
    end

    switch arg.Minimize
        case 'point'
            % Determine weight vector
            weights = arg.Weight(match);
            [R,T] = eq_point(q(:,q_idx),pt(:,p_idx), weights(p_idx));
        case 'plane'
            weights = arg.Weight(match);
            [R,T] = eq_plane(q(:,q_idx),pt(:,p_idx),arg.Normals(:,q_idx),weights(p_idx));
        case 'lmaPoint'
            [R,T] = eq_lmaPoint(q(:,q_idx),pt(:,p_idx));
    end

    %%% ADDED: limit rotation and make T consistent with the capped R
    if isfinite(arg.MaxRotationDeg)
        Rcand = capRotationStep(R, TR(:,:,k), arg.MaxRotationDeg);   % cap step vs current total
        if ~isequal(Rcand, R)
            switch arg.Minimize
                case {'point','lmaPoint'}
                    % Recompute T = q_bar - R*p_bar using the same pairs/weights
                    ww = weights(p_idx);
                    ww = ww ./ sum(ww);
                    q_bars = q(:,q_idx)  * ww(:);
                    p_barss = pt(:,p_idx) * ww(:);
                    T = q_bars - Rcand * p_barss;
                    R = Rcand;

                case 'plane'
                    % Recompute T that best fits plane constraints for fixed R
                    % Solve: minimize sum w_i ( n_i^T (R p_i + T - q_i) )^2
                    n = arg.Normals(:,q_idx);
                    ww = weights(p_idx);
                    Wn = n .* repmat(ww,3,1);
                    A = Wn * Wn.';                                     % 3x3
                    rhs = Wn * ((q(:,q_idx) - Rcand*pt(:,p_idx)).');   % 3xm * m x 1 per column -> 3x1
                    T = A \ sum(rhs,2);                                % 3x1
                    R = Rcand;
            end
        end
    end

    % Add to the total transformation
    TR(:,:,k+1) = R*TR(:,:,k);
    TT(:,:,k+1) = R*TT(:,:,k)+T;

    % Apply last transformation
    pt = TR(:,:,k+1) * p + repmat(TT(:,:,k+1), 1, Np);

    % Root mean of objective function
    ER(k+1) = rms_error(q(:,q_idx), pt(:,p_idx));

    % If Extrapolation, we might be able to move quicker
    if arg.Extrapolation
        qq(:,k+1) = [rmat2quat(TR(:,:,k+1));TT(:,:,k+1)];
        dq(:,k+1) = qq(:,k+1) - qq(:,k);
        theta(k+1) = (180/pi)*acos(dot(dq(:,k),dq(:,k+1))/(norm(dq(:,k))*norm(dq(:,k+1))));
        if arg.Verbose
            disp(['Direction change ' num2str(theta(k+1)) ' degree in iteration ' num2str(k)]);
        end
        if k>2 && theta(k+1) < 10 && theta(k) < 10
            d = [ER(k+1), ER(k), ER(k-1)];
            v = [0, -norm(dq(:,k+1)), -norm(dq(:,k))-norm(dq(:,k+1))];
            vmax = 25 * norm(dq(:,k+1));
            dv = extrapolate(v,d,vmax);
            if dv ~= 0
                q_mark = qq(:,k+1) + dv * dq(:,k+1)/norm(dq(:,k+1));
                q_mark(1:4) = q_mark(1:4)/norm(q_mark(1:4));
                qq(:,k+1) = q_mark;
                TR(:,:,k+1) = quat2rmat(qq(1:4,k+1));
                TT(:,:,k+1) = qq(5:7,k+1);
                % Reapply total transformation
                pt = TR(:,:,k+1) * p + repmat(TT(:,:,k+1), 1, Np);
                % Recalculate root mean of objective function
                % Note this is costly and only for fun!
                switch arg.Matching
                    case 'bruteForce'
                        [~, mindist] = match_bruteForce(q,pt);
                    case 'Delaunay'
                        [~, mindist] = match_Delaunay(q,pt,DT);
                    case 'kDtree'
                        [~, mindist] = match_kDtree(q,pt,kdOBJ);
                end
                ER(k+1) = sqrt(sum(mindist.^2)/length(mindist));
            end
        end
    end
    t(k+1) = toc;

    % if k >= 6 && std(ER(k-5:k+1)) < 1e-4
    %     disp(k)
    %     break;
    % end

end

% ER = nonzeros(ER);

if not(arg.ReturnAll)
    TR = TR(:,:,end);
    TT = TT(:,:,end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [match mindist] = match_bruteForce(q, p)
        mm = size(p,2);
        nnn = size(q,2);
        match = zeros(1,mm);
        mindist = zeros(1,mm);
        for ki=1:mm
            dd=zeros(1,nnn);
            for ti=1:3
                dd=dd+(q(ti,:)-p(ti,ki)).^2;
            end
            [mindist(ki),match(ki)]=min(dd);
        end

        mindist = sqrt(mindist);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [match mindist] = match_Delaunay(q, p, DT)
        match = transpose(nearestNeighbor(DT, transpose(p)));
        mindist = sqrt(sum((p-q(:,match)).^2,1));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [match mindist] = match_kDtree(~, p, kdOBJ)
        [match mindist] = knnsearch(kdOBJ,transpose(p));
        match = transpose(match);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [R,T] = eq_point(q,p,weights)

        mm = size(p,2);
        nnn = size(q,2);

        % normalize weights
        weights = weights ./ sum(weights);

        % find data centroid and deviations from centroid
        q_bar = q * transpose(weights);
        q_marks = q - repmat(q_bar, 1, nnn);
        % Apply weights
        q_marks = q_marks .* repmat(weights, 3, 1);

        % find data centroid and deviations from centroid
        p_bars = p * transpose(weights);
        p_mark = p - repmat(p_bars, 1, mm);
        % Apply weights
        %p_mark = p_mark .* repmat(weights, 3, 1);

        N = p_mark*transpose(q_marks); % taking points of q in matched order

        [U,~,VVV] = svd(N); % singular value decomposition

        R = VVV*diag([1 1 det(U*VVV')])*transpose(U);

        T = q_bar - R*p_bars;
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [R,T] = eq_plane(q,p,n,weights)

        n = n .* repmat(weights,3,1);

        c = cross(p,n);

        cn = vertcat(c,n);

        C = cn*transpose(cn);

        b = - [sum(sum((p-q).*repmat(cn(1,:),3,1).*n));
            sum(sum((p-q).*repmat(cn(2,:),3,1).*n));
            sum(sum((p-q).*repmat(cn(3,:),3,1).*n));
            sum(sum((p-q).*repmat(cn(4,:),3,1).*n));
            sum(sum((p-q).*repmat(cn(5,:),3,1).*n));
            sum(sum((p-q).*repmat(cn(6,:),3,1).*n))];

        X = C\b;

        cx = cos(X(1)); cy = cos(X(2)); cz = cos(X(3));
        sx = sin(X(1)); sy = sin(X(2)); sz = sin(X(3));

        R = [cy*cz cz*sx*sy-cx*sz cx*cz*sy+sx*sz;
            cy*sz cx*cz+sx*sy*sz cx*sy*sz-cz*sx;
            -sy cy*sx cx*cy];

        T = X(4:6);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [R,T] = eq_lmaPoint(q,p)

        Rx = @(a)[1     0       0;
            0     cos(a)  -sin(a);
            0     sin(a)  cos(a)];

        Ry = @(b)[cos(b)    0   sin(b);
            0         1   0;
            -sin(b)   0   cos(b)];

        Rz = @(g)[cos(g)    -sin(g) 0;
            sin(g)    cos(g)  0;
            0         0       1];

        Rot = @(x)Rx(x(1))*Ry(x(2))*Rz(x(3));

        myfun = @(x,xdata)Rot(x(1:3))*xdata+repmat(x(4:6),1,length(xdata));


        options = optimset('Algorithm', 'levenberg-marquardt');
        x = lsqcurvefit(myfun, zeros(6,1), p, q, [], [], options);


        R = Rot(x(1:3));
        T = x(4:6);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Extrapolation in quaternion space. Details are found in:
%
% Besl, P., & McKay, N. (1992). A method for registration of 3-D shapes.
% IEEE Transactions on pattern analysis and machine intelligence, 239?256.

    function [dv] = extrapolate(vv,dd,vmax)

        p1 = polyfit(vv,dd,1); % linear fit
        p2 = polyfit(vv,dd,2); % parabolic fit
        v1 = -p1(2)/p1(1); % linear zero crossing
        v2 = -p2(2)/(2*p2(1)); % polynomial top point

        if issorted([0 v2 v1 vmax]) || issorted([0 v2 vmax v1])
            disp('Parabolic update!');
            dv = v2;
        elseif issorted([0 v1 v2 vmax]) || issorted([0 v1 vmax v2])...
                || (v2 < 0 && issorted([0 v1 vmax]))
            disp('Line based update!');
            dv = v1;
        elseif v1 > vmax && v2 > vmax
            disp('Maximum update!');
            dv = vmax;
        else
            disp('No extrapolation!');
            dv = 0;
        end
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Determine the RMS error between two point equally sized point clouds with
% point correspondance.
% ER = rms_error(p1,p2) where p1 and p2 are 3xn matrices.

    function ER = rms_error(p1,p2)
        dsq = sum(power(p1 - p2, 2),1);
        ER = sqrt(mean(dsq));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Converts (orthogonal) rotation matrices R to (unit) quaternion
% representations
%
% Input: A 3x3xn matrix of rotation matrices
% Output: A 4xn matrix of n corresponding quaternions
%
% http://en.wikipedia.org/wiki/Rotation_matrix#Quaternion

    function quaternion = rmat2quat(R)

        Qxx = R(1,1,:);
        Qxy = R(1,2,:);
        Qxz = R(1,3,:);
        Qyx = R(2,1,:);
        Qyy = R(2,2,:);
        Qyz = R(2,3,:);
        Qzx = R(3,1,:);
        Qzy = R(3,2,:);
        Qzz = R(3,3,:);

        w = 0.5 * sqrt(1+Qxx+Qyy+Qzz);
        xx = 0.5 * sign(Qzy-Qyz) .* sqrt(1+Qxx-Qyy-Qzz);
        y = 0.5 * sign(Qxz-Qzx) .* sqrt(1-Qxx+Qyy-Qzz);
        z = 0.5 * sign(Qyx-Qxy) .* sqrt(1-Qxx-Qyy+Qzz);

        quaternion = reshape([w;xx;y;z],4,[]);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Converts (unit) quaternion representations to (orthogonal) rotation matrices R
%
% Input: A 4xn matrix of n quaternions
% Output: A 3x3xn matrix of corresponding rotation matrices
%
% http://en.wikipedia.org/wiki/Quaternions_and_spatial_rotation#From_a_quaternion_to_an_orthogonal_matrix

    function R = quat2rmat(quaternion)
        q0(1,1,:) = quaternion(1,:);
        qx(1,1,:) = quaternion(2,:);
        qy(1,1,:) = quaternion(3,:);
        qz(1,1,:) = quaternion(4,:);

        R = [q0.^2+qx.^2-qy.^2-qz.^2 2*qx.*qy-2*q0.*qz 2*qx.*qz+2*q0.*qy;
            2*qx.*qy+2*q0.*qz q0.^2-qx.^2+qy.^2-qz.^2 2*qy.*qz-2*q0.*qx;
            2*qx.*qz-2*q0.*qy 2*qy.*qz+2*q0.*qx q0.^2-qx.^2-qy.^2+qz.^2];
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Least squares normal estimation from point clouds using PCA
%
% H. Hoppe, T. DeRose, T. Duchamp, J. McDonald, and W. Stuetzle.
% Surface reconstruction from unorganized points.
% In Proceedings of ACM Siggraph, pages 71:78, 1992.
%
% p should be a matrix containing the horizontally concatenated column
% vectors with points. k is a scalar indicating how many neighbors the
% normal estimation is based upon.
%
% Note that for large point sets, the function performs significantly
% faster if Statistics Toolbox >= v. 7.3 is installed.
%
% Jakob Wilm 2010

    function n = lsqnormest(p, k)
        m = size(p,2);
        n = zeros(3,m);

        vv = ver('stats');
        if str2double(vv.Version) >= 7.5
            neighbors = transpose(knnsearch(transpose(p), transpose(p), 'k', k+1));
        else
            neighbors = k_nearest_neighbors(p, p, k+1);
        end

        for ii = 1:m
            x = p(:,neighbors(2:end, ii));
            p_bar = 1/k * sum(x,2);

            P = (x - repmat(p_bar,1,k)) * transpose(x - repmat(p_bar,1,k)); %spd matrix P
            %P = 2*cov(x);

            [V,DD] = eig(P);

            [~, idxs] = min(diag(DD)); % choses the smallest eigenvalue

            n(:,ii) = V(:,idxs);   % returns the corresponding eigenvector
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Program to find the k - nearest neighbors (kNN) within a set of points.
% Distance metric used: Euclidean distance
%
% Note that this function makes repetitive use of min(), which seems to be
% more efficient than sort() for k < 30.

    function [neighborIds neighborDistances] = k_nearest_neighbors(dataMatrix, queryMatrix, k)

        numDataPoints = size(dataMatrix,2);
        numQueryPoints = size(queryMatrix,2);

        neighborIds = zeros(k,numQueryPoints);
        neighborDistances = zeros(k,numQueryPoints);

        D = size(dataMatrix, 1); %dimensionality of points

        for i=1:numQueryPoints
            dd=zeros(1,numDataPoints);
            for tt=1:D % this is to avoid slow repmat()
                dd=dd+(dataMatrix(tt,:)-queryMatrix(tt,i)).^2;
            end
            for j=1:k
                [s,tt] = min(dd);
                neighborIds(j,i)=tt;
                neighborDistances(j,i)=sqrt(s);
                dd(tt) = NaN; % remove found number from d
            end
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Boundary point determination. Given a set of 3D points and a
% corresponding triangle representation, returns those point indices that
% define the border/edge of the surface.

    function bound = find_bound(pts, poly)

        %Correcting polygon indices and converting datatype
        poly = double(poly);
        pts = double(pts);

        %Calculating freeboundary points:
        % TR = triangulation(poly, pts(1,:)', pts(2,:)', pts(3,:)');
        TRs = delaunayTriangulation(pts(1,:)', pts(2,:)', pts(3,:)');
        FF = freeBoundary(TRs);

        %Output
        bound = FF(:,1);
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helpers to limit rotation angle (principal angle)        %%% ADDED
    function Rcapped = capRotationStep(Rstep, Rbase, maxDeg)
        % Ensure proper rotations
        Rstep = projectSO3(Rstep);
        Rbase = projectSO3(Rbase);

        maxRad = deg2rad(maxDeg);

        % Cap the step itself to avoid wild jumps
        [u_step, th_step] = rotAxisAngle_safe(Rstep);
        if th_step > maxRad
            Rstep = axangRodrigues(u_step, maxRad);
            th_step = maxRad;
        end

        % Cap the NET rotation relative to the *initial* pose:
        % new total = Rstep * Rbase
        Rnet = projectSO3(Rstep * Rbase);
        th_net = rotAngle(Rnet);

        if th_net > maxRad
            if th_step < 1e-12
                Rcapped = eye(3);
                return
            end
            scale = maxRad / th_net;
            Rcapped = axangRodrigues(u_step, th_step * scale);
            Rcapped = projectSO3(Rcapped);
        else
            Rcapped = Rstep;
        end
    end

    function theta = rotAngle(R)
        cc = (trace(R)-1)/2;
        cc = max(-1,min(1,cc));
        theta = acos(cc);
    end

    function [u,theta] = rotAxisAngle_safe(R)
        R = projectSO3(R);
        cc = (trace(R)-1)/2;
        cc = max(-1,min(1,cc));
        theta = acos(cc);

        if theta < 1e-12
            u = [1;0;0]; theta = 0; return
        end

        ux = (R(3,2)-R(2,3))/(2*sin(theta));
        uy = (R(1,3)-R(3,1))/(2*sin(theta));
        uz = (R(2,1)-R(1,2))/(2*sin(theta));
        u = [ux; uy; uz];
        nn = norm(u);
        if nn < 1e-12, u = [1;0;0]; else, u = u/nn; end
    end

    function R = axangRodrigues(u, theta)
        u = u(:); nn = norm(u);
        if nn < 1e-12 || abs(theta) < 1e-15, R = eye(3); return, end
        u = u/nn;
        ux = [  0   -u(3)  u(2);
            u(3)    0   -u(1);
            -u(2)  u(1)    0 ];
        R = eye(3)*cos(theta) + sin(theta)*ux + (1-cos(theta))*(u*u.');
    end

    function R = projectSO3(Rin)
        [UU,~,VV] = svd(Rin);
        R = UU*diag([1,1,det(UU*VV')])*VV';
    end
end
