function [Temp_Coordinates, Temp_Nodes, MDTA, TLSA, z_min_xyz, z_min_xyz_MSA, MEARY, TTA, HAA, MLCR, NC_nav, NC_cub, DMAA] = CoordinateSystem(aligned_nodes,bone_indx,bone_coord,side_indx)
% This function produces the coordinate system for the users bone in the
% temporarily aligned orientation.
vis = 0;
z_min_xyz = [];
z_min_xyz_MSA = [];

%% TT CS for Talus
if bone_indx == 1 && bone_coord >= 2
    nodes_aligned_original = aligned_nodes;
    aligned_nodes = [aligned_nodes(aligned_nodes(:,2)<10,1) aligned_nodes(aligned_nodes(:,2)<10,2) aligned_nodes(aligned_nodes(:,2)<10,3)];
end

%% Tibial Realignment for Medial Malleolus
if bone_indx == 13
    nodes_aligned_original = aligned_nodes;
    cutting_plane = min(aligned_nodes(:,3)) + 14; % Temporarily removes the tibial plafond
    cutting_plane2 = min(aligned_nodes(:,3)) + 100; % Temporarily shortens the tibia
    aligned_nodes = [aligned_nodes(aligned_nodes(:,3)>cutting_plane,1) aligned_nodes(aligned_nodes(:,3)>cutting_plane,2) aligned_nodes(aligned_nodes(:,3)>cutting_plane,3)];
    aligned_nodes = [aligned_nodes(aligned_nodes(:,3)<cutting_plane2,1) aligned_nodes(aligned_nodes(:,3)<cutting_plane2,2) aligned_nodes(aligned_nodes(:,3)<cutting_plane2,3)];
end

%% HAA backhalf
if bone_indx == 2
    nodes_aligned_original = aligned_nodes;
    aligned_nodes_HAA = [aligned_nodes(aligned_nodes(:,2)<0,1) aligned_nodes(aligned_nodes(:,2)<0,2) aligned_nodes(aligned_nodes(:,2)<0,3)];
else
    aligned_nodes_HAA = aligned_nodes;
end

%% NC medial half
if bone_indx == 3
    nodes_aligned_original = aligned_nodes;
    aligned_nodes_NC = [aligned_nodes(aligned_nodes(:,1)>10,1) aligned_nodes(aligned_nodes(:,1)>10,2) aligned_nodes(aligned_nodes(:,1)>10,3)];
else
    aligned_nodes_NC = aligned_nodes;
end

%% Metatarsal 1 head
if bone_indx == 8
    y_min = min(aligned_nodes(:,2));
    y_max = max(aligned_nodes(:,2));
    range_y = y_max - y_min;
    cutoff = range_y*0.25;

    nodes_aligned_original = aligned_nodes;
    aligned_nodes_DMAA = [aligned_nodes(aligned_nodes(:,2)>cutoff,1) aligned_nodes(aligned_nodes(:,2)>cutoff,2) aligned_nodes(aligned_nodes(:,2)>cutoff,3)];
else
    aligned_nodes_DMAA = aligned_nodes;
end

%% Split up the bone into nth sections in all three planes
x_min = min(aligned_nodes(:,1));
y_min = min(aligned_nodes(:,2));
z_min = min(aligned_nodes(:,3));
x_max = max(aligned_nodes(:,1));
y_max = max(aligned_nodes(:,2));
z_max = max(aligned_nodes(:,3));

range_x = x_max - x_min;
range_y = y_max - y_min;
range_z = z_max - z_min;

% Splits bone up in n sections
if bone_indx == 1 % Talus
    n = 3;
elseif bone_indx == 2 % Calcaneus
    n = 10;
elseif bone_indx == 3 % Navicular
    n = 5;
elseif bone_indx == 4 % Cuboid
    n = 5;
elseif bone_indx >= 5 && bone_indx <= 7 % Cuneiforms
    n = 3;
elseif bone_indx >= 8 && bone_indx <= 12 % Metatarsals
    n = 3;
elseif bone_indx == 13 || bone_indx == 14 % Tibia or Fibula
    n = 3;
elseif bone_indx == 15 || bone_indx == 16 % Phalanx
    n = 3;
end

%% Just for TTA
% Positive Z Nth ROI TTA
nth_z = range_z/7;

positive_z_nth = z_max - nth_z;

positive_z_nth_ROI = (aligned_nodes(:,3) >= positive_z_nth) & (aligned_nodes(:,1) >= 5);

if bone_indx == 1 && bone_coord >= 2
    step = 1;
    z_min_allowed = min(aligned_nodes(:,3)); % stop before going below data
    while ~any(positive_z_nth_ROI) && positive_z_nth > z_min_allowed
        positive_z_nth = positive_z_nth - step;
        positive_z_nth_ROI = (aligned_nodes(:,3) >= positive_z_nth) & (aligned_nodes(:,1) >= 5);
    end
    if ~any(positive_z_nth_ROI)
        warning('No nodes found even after relaxing to z_min.');
    end
end

positive_z_nth_x = nonzeros(aligned_nodes(:,1).*positive_z_nth_ROI);
positive_z_nth_y = nonzeros(aligned_nodes(:,2).*positive_z_nth_ROI);
positive_z_nth_z = nonzeros(aligned_nodes(:,3).*positive_z_nth_ROI);

av_positive_z_nth_x = mean(positive_z_nth_x);
av_positive_z_nth_y = mean(positive_z_nth_y);
av_positive_z_nth_z = mean(positive_z_nth_z);

av_positive_z_nth_tta = [av_positive_z_nth_x,av_positive_z_nth_y,av_positive_z_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_z_nth_x,positive_z_nth_y,positive_z_nth_z,'ys')
    plot3(av_positive_z_nth_x,av_positive_z_nth_y,av_positive_z_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative X Nth ROI TTA
negative_z_nth = z_max - nth_z;

negative_z_nth_ROI = (aligned_nodes(:,3) >= negative_z_nth) & (aligned_nodes(:,1) <= -5);

negative_z_nth_x = nonzeros(aligned_nodes(:,1).*negative_z_nth_ROI);
negative_z_nth_y = nonzeros(aligned_nodes(:,2).*negative_z_nth_ROI);
negative_z_nth_z = nonzeros(aligned_nodes(:,3).*negative_z_nth_ROI);

av_negative_z_nth_x = mean(negative_z_nth_x);
av_negative_z_nth_y = mean(negative_z_nth_y);
av_negative_z_nth_z = mean(negative_z_nth_z);

av_negative_z_nth_tta = [av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_z_nth_x,negative_z_nth_y,negative_z_nth_z,'ys')
    plot3(av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Just for DMAA
% Positive Y Nth ROI DMAA
y_min_DMAA = min(aligned_nodes_DMAA(:,2));
y_max_DMAA = max(aligned_nodes_DMAA(:,2));
range_y_DMAA = y_max_DMAA - y_min_DMAA;

nth_y = range_y_DMAA/5;

positive_y_nth = y_max_DMAA - nth_y;

positive_y_nth_ROI = (aligned_nodes_DMAA(:,2) >= positive_y_nth);

positive_y_nth_x = nonzeros(aligned_nodes_DMAA(:,1).*positive_y_nth_ROI);
positive_y_nth_y = nonzeros(aligned_nodes_DMAA(:,2).*positive_y_nth_ROI);
positive_y_nth_z = nonzeros(aligned_nodes_DMAA(:,3).*positive_y_nth_ROI);

av_positive_y_nth_x = mean(positive_y_nth_x);
av_positive_y_nth_y = mean(positive_y_nth_y);
av_positive_y_nth_z = mean(positive_y_nth_z);

av_positive_y_nth_DMAA = [av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes_DMAA(:,1),aligned_nodes_DMAA(:,2),aligned_nodes_DMAA(:,3),'k.')
    hold on
    plot3(positive_y_nth_x,positive_y_nth_y,positive_y_nth_z,'ys')
    plot3(av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative Y nth ROI HAA
negative_y_nth = y_min_DMAA + nth_y;

negative_y_nth_ROI = (aligned_nodes_DMAA(:,2) <= negative_y_nth);

negative_y_nth_x = nonzeros(aligned_nodes_DMAA(:,1).*negative_y_nth_ROI);
negative_y_nth_y = nonzeros(aligned_nodes_DMAA(:,2).*negative_y_nth_ROI);
negative_y_nth_z = nonzeros(aligned_nodes_DMAA(:,3).*negative_y_nth_ROI);

av_negative_y_nth_x = mean(negative_y_nth_x);
av_negative_y_nth_y = mean(negative_y_nth_y);
av_negative_y_nth_z = mean(negative_y_nth_z);

av_negative_y_nth_DMAA = [av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes_DMAA(:,1),aligned_nodes_DMAA(:,2),aligned_nodes_DMAA(:,3),'k.')
    hold on
    plot3(negative_y_nth_x,negative_y_nth_y,negative_y_nth_z,'ys')
    plot3(av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Just for MDTA and TLSA
% Positive Y Nth ROI TLSA
nth_y = range_y/10;

positive_y_nth = y_max - nth_y;

positive_y_nth_ROI = (aligned_nodes(:,2) >= positive_y_nth) & (aligned_nodes(:,3) <= 0);

positive_y_nth_x = nonzeros(aligned_nodes(:,1).*positive_y_nth_ROI);
positive_y_nth_y = nonzeros(aligned_nodes(:,2).*positive_y_nth_ROI);
positive_y_nth_z = nonzeros(aligned_nodes(:,3).*positive_y_nth_ROI);

av_positive_y_nth_x = mean(positive_y_nth_x);
av_positive_y_nth_y = mean(positive_y_nth_y);
av_positive_y_nth_z = mean(positive_y_nth_z);

av_positive_y_nth_tlsa = [av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_y_nth_x,positive_y_nth_y,positive_y_nth_z,'ys')
    plot3(av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative Y nth ROI TLSA
negative_y_nth = y_min + nth_y;

negative_y_nth_ROI = (aligned_nodes(:,2) <= negative_y_nth) & (aligned_nodes(:,3) <= 0);

negative_y_nth_x = nonzeros(aligned_nodes(:,1).*negative_y_nth_ROI);
negative_y_nth_y = nonzeros(aligned_nodes(:,2).*negative_y_nth_ROI);
negative_y_nth_z = nonzeros(aligned_nodes(:,3).*negative_y_nth_ROI);

av_negative_y_nth_x = mean(negative_y_nth_x);
av_negative_y_nth_y = mean(negative_y_nth_y);
av_negative_y_nth_z = mean(negative_y_nth_z);

av_negative_y_nth_tlsa = [av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_y_nth_x,negative_y_nth_y,negative_y_nth_z,'ys')
    plot3(av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative X nth ROI MDTA
nth_x = range_x/8;

negative_x_nth = x_min + nth_x;

negative_x_nth_ROI = (aligned_nodes(:,1) <= negative_x_nth) & (aligned_nodes(:,3) <= 0);

negative_x_nth_x = nonzeros(aligned_nodes(:,1).*negative_x_nth_ROI);
negative_x_nth_y = nonzeros(aligned_nodes(:,2).*negative_x_nth_ROI);
negative_x_nth_z = nonzeros(aligned_nodes(:,3).*negative_x_nth_ROI);

av_negative_x_nth_x = mean(negative_x_nth_x);
av_negative_x_nth_y = mean(negative_x_nth_y);
av_negative_x_nth_z = mean(negative_x_nth_z);

av_negative_x_nth_mdta = [av_negative_x_nth_x,av_negative_x_nth_y,av_negative_x_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_x_nth_x,negative_x_nth_y,negative_x_nth_z,'ys')
    plot3(av_negative_x_nth_x,av_negative_x_nth_y,av_negative_x_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Positive X nth ROI MDTA
if bone_indx == 3
    nth_x = range_x/10;
else
    nth_x = range_x/4;
end

positive_x_nth = x_max - nth_x;

positive_x_nth_ROI = (aligned_nodes(:,1) >= positive_x_nth) & (aligned_nodes(:,3) <= 0);

positive_x_nth_x = nonzeros(aligned_nodes(:,1).*positive_x_nth_ROI);
positive_x_nth_y = nonzeros(aligned_nodes(:,2).*positive_x_nth_ROI);
positive_x_nth_z = nonzeros(aligned_nodes(:,3).*positive_x_nth_ROI);

av_positive_x_nth_x = mean(positive_x_nth_x);
av_positive_x_nth_y = mean(positive_x_nth_y);
av_positive_x_nth_z = mean(positive_x_nth_z);

av_positive_x_nth_mdta = [av_positive_x_nth_x,av_positive_x_nth_y,av_positive_x_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_x_nth_x,positive_x_nth_y,positive_x_nth_z,'ys')
    plot3(av_positive_x_nth_x,av_positive_x_nth_y,av_positive_x_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Just for MEARY 
% Positive Y Nth ROI MEARY
nth_y = range_y/6;

positive_y_nth = y_max - nth_y;

positive_y_nth_ROI = (aligned_nodes(:,2) >= positive_y_nth) & (aligned_nodes(:,3) <= 0);

positive_y_nth_x = nonzeros(aligned_nodes(:,1).*positive_y_nth_ROI);
positive_y_nth_y = nonzeros(aligned_nodes(:,2).*positive_y_nth_ROI);
positive_y_nth_z = nonzeros(aligned_nodes(:,3).*positive_y_nth_ROI);

av_positive_y_nth_x = mean(positive_y_nth_x);
av_positive_y_nth_y = mean(positive_y_nth_y);
av_positive_y_nth_z = mean(positive_y_nth_z);

av_positive_y_nth_MEARY = [av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_y_nth_x,positive_y_nth_y,positive_y_nth_z,'ys')
    plot3(av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative Y nth ROI MEARY
negative_y_nth = y_min + nth_y;

negative_y_nth_ROI = (aligned_nodes(:,2) <= negative_y_nth) & (aligned_nodes(:,3) <= 0);

negative_y_nth_x = nonzeros(aligned_nodes(:,1).*negative_y_nth_ROI);
negative_y_nth_y = nonzeros(aligned_nodes(:,2).*negative_y_nth_ROI);
negative_y_nth_z = nonzeros(aligned_nodes(:,3).*negative_y_nth_ROI);

av_negative_y_nth_x = mean(negative_y_nth_x);
av_negative_y_nth_y = mean(negative_y_nth_y);
av_negative_y_nth_z = mean(negative_y_nth_z);

av_negative_y_nth_MEARY = [av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_y_nth_x,negative_y_nth_y,negative_y_nth_z,'ys')
    plot3(av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative Y nth ROI MEARY
negative_y_nth = y_min + nth_y;

negative_y_nth_ROI = (aligned_nodes(:,2) <= negative_y_nth) & (aligned_nodes(:,3) >= 0);

negative_y_nth_x = nonzeros(aligned_nodes(:,1).*negative_y_nth_ROI);
negative_y_nth_y = nonzeros(aligned_nodes(:,2).*negative_y_nth_ROI);
negative_y_nth_z = nonzeros(aligned_nodes(:,3).*negative_y_nth_ROI);

av_negative_y_nth_x = mean(negative_y_nth_x);
av_negative_y_nth_y = mean(negative_y_nth_y);
av_negative_y_nth_z = mean(negative_y_nth_z);

av_negative_y_nth_MLCR = [av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_y_nth_x,negative_y_nth_y,negative_y_nth_z,'ys')
    plot3(av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Just for HAA 
% Positive Y Nth ROI HAA
y_min_HAA = min(aligned_nodes_HAA(:,2));
y_max_HAA = max(aligned_nodes_HAA(:,2));
range_y_HAA = y_max_HAA - y_min_HAA;

nth_y = range_y_HAA/5;

positive_y_nth = y_max_HAA - nth_y;

positive_y_nth_ROI = (aligned_nodes_HAA(:,2) >= positive_y_nth);

positive_y_nth_x = nonzeros(aligned_nodes_HAA(:,1).*positive_y_nth_ROI);
positive_y_nth_y = nonzeros(aligned_nodes_HAA(:,2).*positive_y_nth_ROI);
positive_y_nth_z = nonzeros(aligned_nodes_HAA(:,3).*positive_y_nth_ROI);

av_positive_y_nth_x = mean(positive_y_nth_x);
av_positive_y_nth_y = mean(positive_y_nth_y);
av_positive_y_nth_z = mean(positive_y_nth_z);

av_positive_y_nth_HAA = [av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes_HAA(:,1),aligned_nodes_HAA(:,2),aligned_nodes_HAA(:,3),'k.')
    hold on
    plot3(positive_y_nth_x,positive_y_nth_y,positive_y_nth_z,'ys')
    plot3(av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative Y nth ROI HAA
negative_y_nth = y_min_HAA + nth_y;

negative_y_nth_ROI = (aligned_nodes_HAA(:,2) <= negative_y_nth);

negative_y_nth_x = nonzeros(aligned_nodes_HAA(:,1).*negative_y_nth_ROI);
negative_y_nth_y = nonzeros(aligned_nodes_HAA(:,2).*negative_y_nth_ROI);
negative_y_nth_z = nonzeros(aligned_nodes_HAA(:,3).*negative_y_nth_ROI);

av_negative_y_nth_x = mean(negative_y_nth_x);
av_negative_y_nth_y = mean(negative_y_nth_y);
av_negative_y_nth_z = mean(negative_y_nth_z);

av_negative_y_nth_HAA = [av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes_HAA(:,1),aligned_nodes_HAA(:,2),aligned_nodes_HAA(:,3),'k.')
    hold on
    plot3(negative_y_nth_x,negative_y_nth_y,negative_y_nth_z,'ys')
    plot3(av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Just NC Overlap
z_min_NC = min(aligned_nodes(:,3));
z_max_NC = max(aligned_nodes(:,3));
range_z_NC = z_max_NC - z_min_NC;

nth_z = range_z_NC/10;

% Positive Z nth ROI
positive_z_nth = z_max - nth_z;

positive_z_nth_ROI = aligned_nodes(:,3) >= positive_z_nth;

positive_z_nth_x = nonzeros(aligned_nodes(:,1).*positive_z_nth_ROI);
positive_z_nth_y = nonzeros(aligned_nodes(:,2).*positive_z_nth_ROI);
positive_z_nth_z = nonzeros(aligned_nodes(:,3).*positive_z_nth_ROI);

av_positive_z_nth_x = mean(positive_z_nth_x);
av_positive_z_nth_y = mean(positive_z_nth_y);
av_positive_z_nth_z = mean(positive_z_nth_z);

av_positive_z_nth_NC = [av_positive_z_nth_x,av_positive_z_nth_y,av_positive_z_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_z_nth_x,positive_z_nth_y,positive_z_nth_z,'gs')
    plot3(av_positive_z_nth_x,av_positive_z_nth_y,av_positive_z_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

% Negative Z nth ROI
negative_z_nth = z_min + nth_z;

negative_z_nth_ROI = aligned_nodes(:,3) <= negative_z_nth;

negative_z_nth_x = nonzeros(aligned_nodes(:,1).*negative_z_nth_ROI);
negative_z_nth_y = nonzeros(aligned_nodes(:,2).*negative_z_nth_ROI);
negative_z_nth_z = nonzeros(aligned_nodes(:,3).*negative_z_nth_ROI);

av_negative_z_nth_x = mean(negative_z_nth_x);
av_negative_z_nth_y = mean(negative_z_nth_y);
av_negative_z_nth_z = mean(negative_z_nth_z);

av_negative_z_nth_NC = [av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z];

if vis == 1
figure()
plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
hold on
plot3(negative_z_nth_x,negative_z_nth_y,negative_z_nth_z,'gs')
plot3(av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z,'r.','MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
axis equal
end

% Negative Z nth ROI
z_min_NC = min(aligned_nodes_NC(:,3));
z_max_NC = max(aligned_nodes_NC(:,3));
range_z_NC = z_max_NC - z_min_NC;

nth_z = range_z_NC/10;

negative_z_nth = z_min_NC + nth_z;

negative_z_nth_ROI = aligned_nodes_NC(:,3) <= negative_z_nth;

negative_z_nth_x = nonzeros(aligned_nodes_NC(:,1).*negative_z_nth_ROI);
negative_z_nth_y = nonzeros(aligned_nodes_NC(:,2).*negative_z_nth_ROI);
negative_z_nth_z = nonzeros(aligned_nodes_NC(:,3).*negative_z_nth_ROI);

av_negative_z_nth_x = mean(negative_z_nth_x);
av_negative_z_nth_y = mean(negative_z_nth_y);
av_negative_z_nth_z = mean(negative_z_nth_z);

av_negative_z_nth_NC_nav = [av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes_NC(:,1),aligned_nodes_NC(:,2),aligned_nodes_NC(:,3),'k.')
    hold on
    plot3(negative_z_nth_x,negative_z_nth_y,negative_z_nth_z,'gs')
    plot3(av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Split up for ACS
nth_x = range_x/n;
nth_y = range_y/n;
nth_z = range_z/n;

%% Positive Y Nth ROI
positive_y_nth = y_max - nth_y;

positive_y_nth_ROI = aligned_nodes(:,2) >= positive_y_nth;

positive_y_nth_x = nonzeros(aligned_nodes(:,1).*positive_y_nth_ROI);
positive_y_nth_y = nonzeros(aligned_nodes(:,2).*positive_y_nth_ROI);
positive_y_nth_z = nonzeros(aligned_nodes(:,3).*positive_y_nth_ROI);

av_positive_y_nth_x = mean(positive_y_nth_x);
av_positive_y_nth_y = mean(positive_y_nth_y);
av_positive_y_nth_z = mean(positive_y_nth_z);

av_positive_y_nth = [av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_y_nth_x,positive_y_nth_y,positive_y_nth_z,'ys')
    plot3(av_positive_y_nth_x,av_positive_y_nth_y,av_positive_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Negative Y nth ROI
negative_y_nth = y_min + nth_y;

negative_y_nth_ROI = aligned_nodes(:,2) <= negative_y_nth;

negative_y_nth_x = nonzeros(aligned_nodes(:,1).*negative_y_nth_ROI);
negative_y_nth_y = nonzeros(aligned_nodes(:,2).*negative_y_nth_ROI);
negative_y_nth_z = nonzeros(aligned_nodes(:,3).*negative_y_nth_ROI);

av_negative_y_nth_x = mean(negative_y_nth_x);
av_negative_y_nth_y = mean(negative_y_nth_y);
av_negative_y_nth_z = mean(negative_y_nth_z);

av_negative_y_nth = [av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_y_nth_x,negative_y_nth_y,negative_y_nth_z,'ys')
    plot3(av_negative_y_nth_x,av_negative_y_nth_y,av_negative_y_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Positive Z nth ROI
positive_z_nth = z_max - nth_z;

positive_z_nth_ROI = aligned_nodes(:,3) >= positive_z_nth;

positive_z_nth_x = nonzeros(aligned_nodes(:,1).*positive_z_nth_ROI);
positive_z_nth_y = nonzeros(aligned_nodes(:,2).*positive_z_nth_ROI);
positive_z_nth_z = nonzeros(aligned_nodes(:,3).*positive_z_nth_ROI);

av_positive_z_nth_x = mean(positive_z_nth_x);
av_positive_z_nth_y = mean(positive_z_nth_y);
av_positive_z_nth_z = mean(positive_z_nth_z);

av_positive_z_nth = [av_positive_z_nth_x,av_positive_z_nth_y,av_positive_z_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_z_nth_x,positive_z_nth_y,positive_z_nth_z,'ys')
    plot3(av_positive_z_nth_x,av_positive_z_nth_y,av_positive_z_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Negative Z nth ROI
negative_z_nth = z_min + nth_z;

negative_z_nth_ROI = aligned_nodes(:,3) <= negative_z_nth;

negative_z_nth_x = nonzeros(aligned_nodes(:,1).*negative_z_nth_ROI);
negative_z_nth_y = nonzeros(aligned_nodes(:,2).*negative_z_nth_ROI);
negative_z_nth_z = nonzeros(aligned_nodes(:,3).*negative_z_nth_ROI);

av_negative_z_nth_x = mean(negative_z_nth_x);
av_negative_z_nth_y = mean(negative_z_nth_y);
av_negative_z_nth_z = mean(negative_z_nth_z);

av_negative_z_nth = [av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z];

if vis == 1
figure()
plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
hold on
plot3(negative_z_nth_x,negative_z_nth_y,negative_z_nth_z,'ys')
plot3(av_negative_z_nth_x,av_negative_z_nth_y,av_negative_z_nth_z,'r.','MarkerSize',50)
xlabel('X')
ylabel('Y')
zlabel('Z')
axis equal
end

%% Negative X nth ROI
negative_x_nth = x_min + nth_x;

negative_x_nth_ROI = aligned_nodes(:,1) <= negative_x_nth;

negative_x_nth_x = nonzeros(aligned_nodes(:,1).*negative_x_nth_ROI);
negative_x_nth_y = nonzeros(aligned_nodes(:,2).*negative_x_nth_ROI);
negative_x_nth_z = nonzeros(aligned_nodes(:,3).*negative_x_nth_ROI);

av_negative_x_nth_x = mean(negative_x_nth_x);
av_negative_x_nth_y = mean(negative_x_nth_y);
av_negative_x_nth_z = mean(negative_x_nth_z);

av_negative_x_nth = [av_negative_x_nth_x,av_negative_x_nth_y,av_negative_x_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(negative_x_nth_x,negative_x_nth_y,negative_x_nth_z,'ys')
    plot3(av_negative_x_nth_x,av_negative_x_nth_y,av_negative_x_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Positive X nth ROI
positive_x_nth = x_max - nth_x;

positive_x_nth_ROI = aligned_nodes(:,1) >= positive_x_nth;

positive_x_nth_x = nonzeros(aligned_nodes(:,1).*positive_x_nth_ROI);
positive_x_nth_y = nonzeros(aligned_nodes(:,2).*positive_x_nth_ROI);
positive_x_nth_z = nonzeros(aligned_nodes(:,3).*positive_x_nth_ROI);

av_positive_x_nth_x = mean(positive_x_nth_x);
av_positive_x_nth_y = mean(positive_x_nth_y);
av_positive_x_nth_z = mean(positive_x_nth_z);

av_positive_x_nth = [av_positive_x_nth_x,av_positive_x_nth_y,av_positive_x_nth_z];

if vis == 1
    figure()
    plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    hold on
    plot3(positive_x_nth_x,positive_x_nth_y,positive_x_nth_z,'ys')
    plot3(av_positive_x_nth_x,av_positive_x_nth_y,av_positive_x_nth_z,'r.','MarkerSize',50)
    xlabel('X')
    ylabel('Y')
    zlabel('Z')
    axis equal
end

%% Raw Axis Calculation
if bone_indx == 3 % Navicular
    first_point = av_positive_x_nth;
    second_point = av_negative_x_nth;
    third_point = av_positive_z_nth;
elseif bone_indx == 13 || bone_indx == 14 % Tibia, Fibula
    first_point = av_positive_z_nth;
    second_point = av_negative_z_nth;
    if av_negative_z_nth(3) > av_negative_x_nth(3)
        third_point = [av_negative_x_nth(1) av_negative_x_nth(2) 0];
    else
        third_point = av_negative_x_nth;
    end
else % Cuneiforms, Metatarsals, Calcaneus, Cuboid, Talus
    first_point = av_positive_y_nth;
    second_point = av_negative_y_nth;
    third_point = av_positive_z_nth;
end

if bone_indx == 13
    MDTA = [av_negative_x_nth_mdta; av_positive_x_nth_mdta];
    TLSA = [av_negative_y_nth_tlsa; av_positive_y_nth_tlsa];
else
    MDTA = [0,0,0; 0,0,0];
    TLSA = [0,0,0; 0,0,0];
end

if bone_indx == 1
    MEARY = [av_negative_y_nth_MEARY; av_positive_y_nth_MEARY];
else
    MEARY = [0,0,0; 0,0,0];
end

if bone_indx == 1 && bone_coord >= 2
    TTA = [av_positive_z_nth_tta; av_negative_z_nth_tta];
else
    TTA = [0,0,0; 0,0,0];
end

if bone_indx == 2
    HAA = [av_negative_y_nth_HAA; av_positive_y_nth_HAA];
    MLCR = av_negative_y_nth_MLCR;
else
    HAA = [0,0,0; 0,0,0];
    MLCR = [0,0,0];
end

if bone_indx == 4
    NC_cub = [av_positive_z_nth_NC; av_negative_z_nth_NC];
else
    NC_cub = [0,0,0; 0,0,0];
end

if bone_indx == 3
    NC_nav = av_negative_z_nth_NC_nav;
else
    NC_nav = [0,0,0];
end

if bone_indx == 8
    DMAA = [av_positive_y_nth_DMAA; av_negative_y_nth_DMAA];
else
    DMAA = [0,0,0; 0,0,0];
end

origin = [0,0,0];

% Define the primary axis based on first_point and second_point
primary_axis_vector = first_point - second_point;
primary_axis_unit = primary_axis_vector / norm(primary_axis_vector); % Normalize

% Project the third_point onto the primary axis to find the closest point
projection_length = dot(third_point - second_point, primary_axis_unit);
closest_point_on_primary = second_point + projection_length * primary_axis_unit;

% Define the secondary axis
secondary_axis_vector = third_point - closest_point_on_primary;
secondary_axis_unit = secondary_axis_vector / norm(secondary_axis_vector); % Normalize

% Define the tertiary axis as cross product of primary and secondary axes
tertiary_axis_vector = cross(primary_axis_unit, secondary_axis_unit);
tertiary_axis_unit = tertiary_axis_vector / norm(tertiary_axis_vector); % Normalize

if side_indx == 1
    ml = -1;
else
    ml = 1;
end

% Adjust axes based on bone index and side index
if bone_indx == 3 % Navicular
    ML_vector_points = ml*[origin; origin + 50 * primary_axis_unit];
    SI_vector_points = [origin; origin + 50 * secondary_axis_unit];
    AP_vector_points = -[origin; origin + 50 * tertiary_axis_unit];
elseif bone_indx == 13 || bone_indx == 14 % Tibia, Fibula
    SI_vector_points = [origin; origin + 50 * primary_axis_unit];
    ML_vector_points = -ml*[origin; origin + 50 * secondary_axis_unit];
    AP_vector_points = -[origin; origin + 50 * tertiary_axis_unit];
else % Cuneiforms, Metatarsals, Calcaneus, Cuboid, Talus
    AP_vector_points = [origin; origin + 50 * primary_axis_unit];
    SI_vector_points = [origin; origin + 50 * secondary_axis_unit];
    ML_vector_points = ml*[origin; origin + 50 * tertiary_axis_unit];
end

% figure()
% plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
% % plot3(nodes_aligned_original(:,1),nodes_aligned_original(:,2),nodes_aligned_original(:,3),'.k')
% hold on
% plot3(AP_vector_points(:,1),AP_vector_points(:,2),AP_vector_points(:,3),'r')
% plot3(SI_vector_points(:,1),SI_vector_points(:,2),SI_vector_points(:,3),'g')
% plot3(ML_vector_points(:,1),ML_vector_points(:,2),ML_vector_points(:,3),'b')
% plot3(0,0,0,'ys')
% plot3(first_point(:,1),first_point(:,2),first_point(:,3),'rs','MarkerSize',20)
% plot3(second_point(:,1),second_point(:,2),second_point(:,3),'bs','MarkerSize',20)
% plot3(third_point(:,1),third_point(:,2),third_point(:,3),'gs','MarkerSize',20)
% legend('Nodal Points','AP Axis','SI Axis','ML Axis')
% text(AP_vector_points(2,1),AP_vector_points(2,2),AP_vector_points(2,3),'Anterior','HorizontalAlignment','left','FontSize',10,'Color','r');
% text(SI_vector_points(2,1),SI_vector_points(2,2),SI_vector_points(2,3),'Superior','HorizontalAlignment','left','FontSize',10,'Color','g');
% if side_indx == 1
%     text(ML_vector_points(2,1),ML_vector_points(2,2),ML_vector_points(2,3),'Lateral','HorizontalAlignment','left','FontSize',10,'Color','b');
% else
%     text(ML_vector_points(2,1),ML_vector_points(2,2),ML_vector_points(2,3),'Medial','HorizontalAlignment','left','FontSize',10,'Color','b');
% end
% xlabel('X')
% ylabel('Y')
% zlabel('Z')
% axis equal

%% Output Axes and Rotation Index
Temp_Coordinates = [AP_vector_points([1,2],:)
    SI_vector_points([1,2],:)
    ML_vector_points([1,2],:)];

if (bone_indx == 1 && bone_coord >= 2) || bone_indx == 13
    Temp_Nodes = nodes_aligned_original;
else
    Temp_Nodes = aligned_nodes;
end

%% FAO
if bone_indx == 8
    anterior_y_nth = y_max - range_y/2;
    anterior_y_nth_ROI = aligned_nodes(:,2) >= anterior_y_nth;
    anterior_y_nth_z = nonzeros(aligned_nodes(:,3).*anterior_y_nth_ROI);
    z_min_met1 = min(anterior_y_nth_z);
    z_point_index = find(aligned_nodes(:,3) == z_min_met1);
    z_min_xyz = aligned_nodes(z_point_index,:);
    z_min_xyz_MSA = [0,0,0];
elseif bone_indx == 12
    anterior_y_nth = y_max - range_y/2;
    anterior_y_nth_ROI = aligned_nodes(:,2) >= anterior_y_nth;
    anterior_y_nth_z = nonzeros(aligned_nodes(:,3).*anterior_y_nth_ROI);
    z_min_met5 = min(anterior_y_nth_z);
    z_point_index = find(aligned_nodes(:,3) == z_min_met5);
    z_min_xyz = aligned_nodes(z_point_index,:);

    posterior_y_nth = y_min + range_y/2;
    posterior_y_nth_ROI = aligned_nodes(:,2) <= posterior_y_nth;
    posterior_y_nth_z = nonzeros(aligned_nodes(:,3).*posterior_y_nth_ROI);
    z_min_met5 = min(posterior_y_nth_z);
    z_point_index = find(aligned_nodes(:,3) == z_min_met5);
    z_min_xyz_MSA = aligned_nodes(z_point_index,:);
elseif bone_indx == 2 && bone_coord == 1
    posterior_y_nth = y_min + range_y/2;
    posterior_y_nth_ROI = aligned_nodes(:,2) <= posterior_y_nth;
    posterior_y_nth_z = nonzeros(aligned_nodes(:,3).*posterior_y_nth_ROI);
    z_min_calc = min(posterior_y_nth_z);
    z_point_index = find(aligned_nodes(:,3) == z_min_calc);
    z_min_xyz = aligned_nodes(z_point_index,:);
    z_min_xyz_MSA = [0,0,0];

    % figure()
    % plot3(aligned_nodes(:,1),aligned_nodes(:,2),aligned_nodes(:,3),'k.')
    % hold on
    % % plot3(posterior_y_nth_z,positive_x_nth_y,positive_x_nth_z,'ys')
    % plot3(z_min_xyz(:,1),z_min_xyz(:,2),z_min_xyz(:,3),'r.','MarkerSize',50)
    % xlabel('X')
    % ylabel('Y')
    % zlabel('Z')
    % axis equal

else
    if isempty(z_min_xyz)
        z_min_xyz = [0,0,0];
    end
    if isempty(z_min_xyz_MSA)
        z_min_xyz_MSA = [0,0,0];
    end
end
