function [all_aligned_nodes, RTs] = icp_all(all_bone_indx, combined_nodes, side_indx)
% This function aligned the user input bone to a predefined template bone.
% It requires the bone index bone to identify which bone was chosen
% (bone_indx), the bone nodal points (nodes), the coordinate system chosen
% by the user (bone_coord), and a logical value for the user manually
% choosing a better starting point the icp code doesn't undo the chosen
% position.

%% Read in Template Bone
addpath('Template_Bones/All_Template')

% Initialize storage for combined STL
nodes_template = [];
con_template = [];
offset = 0; % To handle indexing for faces

if side_indx == 2
    combined_nodes = combined_nodes .* [-1,1,1];
end

% figure()
% plot3(combined_nodest(:,1),combined_nodest(:,2),combined_nodest(:,3),'.k')
% axis equal


for n = 1:length(all_bone_indx)
    if all_bone_indx(n) == 1
        TR_template = stlread('Talus.stl');
        a = 2;
    elseif all_bone_indx(n) == 2
        TR_template = stlread('Calcaneus.stl');
        a = 2;
    elseif all_bone_indx(n) == 3
        TR_template = stlread('Navicular.stl');
        a = 1;
    elseif all_bone_indx(n) == 4
        TR_template = stlread('Cuboid.stl');
        a = 2;
    elseif all_bone_indx(n) == 5
        TR_template = stlread('Med_Cuneiform.stl');
        a = 3;
    elseif all_bone_indx(n) == 6
        TR_template = stlread('Int_Cuneiform.stl');
        a = 3;
    elseif all_bone_indx(n) == 7
        TR_template = stlread('Lat_Cuneiform.stl');
        a = 3;
    elseif all_bone_indx(n) == 8
        TR_template = stlread('Metatarsal1.stl');
        a = 2;
    elseif all_bone_indx(n) == 9
        TR_template = stlread('Metatarsal2.stl');
        a = 2;
    elseif all_bone_indx(n) == 10
        TR_template = stlread('Metatarsal3.stl');
        a = 2;
    elseif all_bone_indx(n) == 11
        TR_template = stlread('Metatarsal4.stl');
        a = 2;
    elseif all_bone_indx(n) == 12
        TR_template = stlread('Metatarsal5.stl');
        a = 2;
    elseif all_bone_indx(n) == 13
        TR_template = stlread('Tibia.stl');
        a = 3;
    elseif all_bone_indx(n) == 14
        TR_template = stlread('Fibula.stl');
        a = 3;
    end

    nodes_temp = TR_template.Points;
    con_temp = TR_template.ConnectivityList;

    % Append nodes and faces with offsets
    nodes_template = [nodes_template; nodes_temp];
    con_template = [con_template; con_temp + offset];
    offset = offset + size(nodes_temp, 1);
end

%% Adjusting the cropped/smaller models
% Creates similar sized models for cropped tibia or fibula
if all(all_bone_indx == 13) || all(all_bone_indx == 14)
    nodes_template_length = (max(nodes_template(:,a)) - min(nodes_template(:,a)));
    max_nodes_x = (max(combined_nodes(:,1)) - min(combined_nodes(:,1)));
    max_nodes_y = (max(combined_nodes(:,2)) - min(combined_nodes(:,2)));
    max_nodes_z = (max(combined_nodes(:,3)) - min(combined_nodes(:,3)));
    max_nodes_length = max([max_nodes_x  max_nodes_y max_nodes_z]);
    if nodes_template_length/1.5 > max_nodes_length % Determines if the user's model is 2/3 the length of the template model
        temp = find(nodes_template(:,3) < (min(nodes_template(:,a)) + max_nodes_length));
        nodes_template = [nodes_template(temp,1) nodes_template(temp,2) nodes_template(temp,3)];
        x = (-20:4:10)';
        y = (-10:4:20)';
        [x, y] = meshgrid(x,y);
        z = (min(nodes_template(:,a)) + max_nodes_length) .* ones(length(x(:,1)),1);
        k = 1;
        % Creates a temporary plane for icp alignment accuracy
        for n = 1:length(z)
            for m = 1:length(z)
                plane(k,:) = [x(m,n) y(m,n) z(1)];
                k = k + 1;
            end
        end

        nodes_template = [nodes_template(:,1) nodes_template(:,2) nodes_template(:,3);
            plane(:,1) plane(:,2) plane(:,3)];

        if bone_coord == 1
            nodes_template = center(nodes_template,1);
        end

        if nodes_template_length/5 > max_nodes_length
            tibfib_switch = 2; % under 1/5 tibia/fibula is available
            warning('Input bone is shorter than recommended.')
        else
            tibfib_switch = 1;
        end
    else
        tibfib_switch = 1; % over 1/5 tibia/fibula is available
    end
else
    tibfib_switch = 1; % over 1/5 tibia/fibula is available
end

% Similar process as above for cropped metatarsals
if all(all_bone_indx >= 8) && all(all_bone_indx <= 12)
    nodes_template_length = (max(nodes_template(:,a)) - min(nodes_template(:,a)));
    max_nodes_length = max([(max(combined_nodes(:,1)) - min(combined_nodes(:,1))) (max(combined_nodes(:,2)) - min(combined_nodes(:,2))) (max(combined_nodes(:,3)) - min(combined_nodes(:,3)))]);
    if nodes_template_length/1.25 > max_nodes_length
        temp = find(nodes_template(:,2) < (min(nodes_template(:,a)) + max_nodes_length));
        nodes_template = [nodes_template(temp,1) nodes_template(temp,2) nodes_template(temp,3)];
        x = (-10:1:10)';
        z = (-10:1:10)';
        [x, z] = meshgrid(x,z);
        y = (min(nodes_template(:,a)) + max_nodes_length) .* ones(length(x(:,1)),1);
        k = 1;
        for n = 1:length(y)
            for m = 1:length(y)
                plane(k,:) = [x(m,n) y(1) z(m,n)];
                k = k + 1;
            end
        end

        nodes_template = [nodes_template(:,1) nodes_template(:,2) nodes_template(:,3);
            plane(:,1) plane(:,2) plane(:,3)];
    end
end

% Determines maximum axis of bone model and compares it to the template
multiplier = (max(nodes_template(:,a)) - min(nodes_template(:,a)))/(max(combined_nodes(:,a)) - min(combined_nodes(:,a)));
parttib_multiplier = (max(nodes_template(:,1)) - min(nodes_template(:,1)))/(max(combined_nodes(:,1)) - min(combined_nodes(:,1)));

% If the users model is smaller than the template, then this temporarly
% makes it a similar size to the template, for icp alignment accuracy
if multiplier > 1
    combined_nodes = combined_nodes*multiplier;
elseif parttib_multiplier > 1 && tibfib_switch == 2 && bone_indx >= 13
    combined_nodes = combined_nodes*parttib_multiplier;
end

%% Performing ICP alignment
% This is the initial alignment with no rotation. 
% Two different icp approaches are used, the first includeds the faces and
% the second is just the points.

iterations = 50;
[R1,T1,ER1] = icp(nodes_template',combined_nodes', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[R1_0,T1_0,ER1_0] = icp(nodes_template',combined_nodes', iterations,'Matching','kDtree','WorstRejection',0.1);

% The users model is rotated about the z axis and realigned
nodesz90 = combined_nodes*rotz(90);
nodesz180 = combined_nodes*rotz(180);
nodesz270 = combined_nodes*rotz(270);

[Rz90,Tz90,ERz90] = icp(nodes_template',nodesz90', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Rz90_wr,Tz90_wr,ERz90_wr] = icp(nodes_template',nodesz90', iterations,'Matching','kDtree','WorstRejection',0.1);
[Rz180,Tz180,ERz180] = icp(nodes_template',nodesz180', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Rz180_wr,Tz180_wr,ERz180_wr] = icp(nodes_template',nodesz180', iterations,'Matching','kDtree','WorstRejection',0.1);
[Rz270,Tz270,ERz270] = icp(nodes_template',nodesz270', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Rz270_wr,Tz270_wr,ERz270_wr] = icp(nodes_template',nodesz270', iterations,'Matching','kDtree','WorstRejection',0.1);

% The users model is rotated about the y axis and realigned
nodesy90 = combined_nodes*roty(90);
nodesy180 = combined_nodes*roty(180);
nodesy270 = combined_nodes*roty(270);

[Ry90,Ty90,ERy90] = icp(nodes_template',nodesy90', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Ry90_wr,Ty90_wr,ERy90_wr] = icp(nodes_template',nodesy90', iterations,'Matching','kDtree','WorstRejection',0.1);
[Ry180,Ty180,ERy180] = icp(nodes_template',nodesy180', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Ry180_wr,Ty180_wr,ERy180_wr] = icp(nodes_template',nodesy180', iterations,'Matching','kDtree','WorstRejection',0.1);
[Ry270,Ty270,ERy270] = icp(nodes_template',nodesy270', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Ry270_wr,Ty270_wr,ERy270_wr] = icp(nodes_template',nodesy270', iterations,'Matching','kDtree','WorstRejection',0.1);

% The users model is rotated about the x axis and realigned
nodesx90 = combined_nodes*rotx(90);
nodesx180 = combined_nodes*rotx(180);
nodesx270 = combined_nodes*rotx(270);

[Rx90,Tx90,ERx90] = icp(nodes_template',nodesx90', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Rx90_wr,Tx90_wr,ERx90_wr] = icp(nodes_template',nodesx90', iterations,'Matching','kDtree','WorstRejection',0.1);
[Rx180,Tx180,ERx180] = icp(nodes_template',nodesx180', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Rx180_wr,Tx180_wr,ERx180_wr] = icp(nodes_template',nodesx180', iterations,'Matching','kDtree','WorstRejection',0.1);
[Rx270,Tx270,ERx270] = icp(nodes_template',nodesx270', iterations,'Matching','kDtree','EdgeRejection',logical(1),'Triangulation',con_temp);
[Rx270_wr,Tx270_wr,ERx270_wr] = icp(nodes_template',nodesx270', iterations,'Matching','kDtree','WorstRejection',0.1);

% All errors are stored in this matrix
ER_all = [ER1(end),ER1_0(end),ERz90(end),ERz90_wr(end),ERz180(end),ERz180_wr(end),ERz270(end),ERz270_wr(end),...
    ERy90(end),ERy90_wr(end),ERy180(end),ERy180_wr(end),ERy270(end),ERy270_wr(end),...
    ERx90(end),ERx90_wr(end),ERx180(end),ERx180_wr(end),ERx270(end),ERx270_wr(end)];

format long g
ER_min = min(ER_all);

% The minimum error out of all of the alignment steps is used moving
% forward to determine the most accurately aligned model.
if ER1(end) == ER_min
    all_aligned_nodes = (R1*(combined_nodes') + repmat(T1,1,length(combined_nodes')))';
    iflip = [1 0 0; 0 1 0; 0 0 1];
    iR = R1; 
    iT= T1;
elseif ER1_0(end) == ER_min
    all_aligned_nodes = (R1_0*(combined_nodes') + repmat(T1_0,1,length(combined_nodes')))';
    iflip = [1 0 0; 0 1 0; 0 0 1];
    iR = R1_0;
    iT= T1_0;
elseif ERz90(end) == ER_min
    all_aligned_nodes = (Rz90*(nodesz90') + repmat(Tz90,1,length(nodesz90')))';
    iflip = rotz(90);
    iR = Rz90;
    iT= Tz90;
elseif ERz90_wr(end) == ER_min
    all_aligned_nodes = (Rz90_wr*(nodesz90') + repmat(Tz90_wr,1,length(nodesz90')))';
    iflip = rotz(90);
    iR = Rz90_wr;
    iT= Tz90_wr;
elseif ERz180(end) == ER_min
    all_aligned_nodes = (Rz180*(nodesz180') + repmat(Tz180,1,length(nodesz180')))';
    iflip = rotz(180);
    iR = Rz180;
    iT= Tz180;
elseif ERz180_wr(end) == ER_min
    all_aligned_nodes = (Rz180_wr*(nodesz180') + repmat(Tz180_wr,1,length(nodesz180')))';
    iflip = rotz(180);
    iR = Rz180_wr;
    iT= Tz180_wr;
elseif ERz270(end) == ER_min
    all_aligned_nodes = (Rz270*(nodesz270') + repmat(Tz270,1,length(nodesz270')))';
    iflip = rotz(270);
    iR = Rz270;
    iT= Tz270;
elseif ERz270_wr(end) == ER_min
    all_aligned_nodes = (Rz270_wr*(nodesz270') + repmat(Tz270_wr,1,length(nodesz270')))';
    iflip = rotz(270);
    iR = Rz270_wr;
    iT= Tz270_wr;
elseif ERy90(end) == ER_min
    all_aligned_nodes = (Ry90*(nodesy90') + repmat(Ty90,1,length(nodesy90')))';
    iflip = roty(90);
    iR = Ry90;
    iT= Ty90;
elseif ERy90_wr(end) == ER_min
    all_aligned_nodes = (Ry90_wr*(nodesy90') + repmat(Ty90_wr,1,length(nodesy90')))';
    iflip = roty(90);
    iR = Ry90_wr;
    iT= Ty90_wr;
elseif ERy180(end) == ER_min
    all_aligned_nodes = (Ry180*(nodesy180') + repmat(Ty180,1,length(nodesy180')))';
    iflip = roty(180);
    iR = Ry180;
    iT= Ty180;
elseif ERy180_wr(end) == ER_min
    all_aligned_nodes = (Ry180_wr*(nodesy180') + repmat(Ty180_wr,1,length(nodesy180')))';
    iflip = roty(180);
    iR = Ry180_wr;
    iT= Ty180_wr;
elseif ERy270(end) == ER_min
    all_aligned_nodes = (Ry270*(nodesy270') + repmat(Ty270,1,length(nodesy270')))';
    iflip = roty(270);
    iR = Ry270;
    iT= Ty270;
elseif ERy270_wr(end) == ER_min
    all_aligned_nodes = (Ry270_wr*(nodesy270') + repmat(Ty270_wr,1,length(nodesy270')))';
    iflip = roty(270);
    iR = Ry270_wr;
    iT= Ty270_wr;
elseif ERx90(end) == ER_min
    all_aligned_nodes = (Rx90*(nodesx90') + repmat(Tx90,1,length(nodesx90')))';
    iflip = rotx(90);
    iR = Rx90;
    iT= Tx90;
elseif ERx90_wr(end) == ER_min
    all_aligned_nodes = (Rx90_wr*(nodesx90') + repmat(Tx90_wr,1,length(nodesx90')))';
    iflip = rotx(90);
    iR = Rx90_wr;
    iT= Tx90_wr;
elseif ERx180(end) == ER_min
    all_aligned_nodes = (Rx180*(nodesx180') + repmat(Tx180,1,length(nodesx180')))';
    iflip = rotx(180);
    iR = Rx180;
    iT= Tx180;
elseif ERx180_wr(end) == ER_min
    all_aligned_nodes = (Rx180_wr*(nodesx180') + repmat(Tx180_wr,1,length(nodesx180')))';
    iflip = rotx(180);
    iR = Rx180_wr;
    iT= Tx180_wr;
elseif ERx270(end) == ER_min
    all_aligned_nodes = (Rx270*(nodesx270') + repmat(Tx270,1,length(nodesx270')))';
    iflip = rotx(270);
    iR = Rx270;
    iT= Tx270;
elseif ERx270_wr(end) == ER_min
    all_aligned_nodes = (Rx270_wr*(nodesx270') + repmat(Tx270_wr,1,length(nodesx270')))';
    iflip = rotx(270);
    iR = Rx270_wr;
    iT= Tx270_wr;
end

% This undoes the enlargening of the users model
if multiplier > 1
    all_aligned_nodes = all_aligned_nodes/multiplier;
elseif parttib_multiplier > 1 && tibfib_switch == 2 && all(all_bone_indx >= 13)
    all_aligned_nodes = all_aligned_nodes/parttib_multiplier;
end

RTs.iflip = iflip;
RTs.iR = iR;
RTs.iT = iT;

%% Visualize proper alignment
figure()
    plot3(nodes_template(:,1),nodes_template(:,2),nodes_template(:,3),'.k')
hold on
plot3(all_aligned_nodes(:,1),all_aligned_nodes(:,2),all_aligned_nodes(:,3),'.b')
xlabel('X')
ylabel('Y')
zlabel('Z')
axis equal
