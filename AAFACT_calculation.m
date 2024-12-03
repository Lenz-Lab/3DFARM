function out = AAFACT_calculation(TR_bone, bone_indx, side_indx)

if bone_indx == 1
    bone_coord = [1, 2, 3]; % TN&TT&ST
elseif bone_indx == 2
    bone_coord = [1, 2]; % CC&ST
else
    bone_coord = 1; % Others
end

% Lists for detemining bone and side
list_bone = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Medial_Cuneiform','Intermediate_Cuneiform',...
    'Lateral_Cuneiform','Metatarsal1','Metatarsal2','Metatarsal3','Metatarsal4','Metatarsal5',...
    'Tibia','Fibula'};
list_bone2 = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Med_Cuneiform','Int_Cuneiform',...
    'Lat_Cuneiform','First_Metatarsal','Second_Metatarsal','Third_Metatarsal','Fourth_Metatarsal','Fifth_Metatarsal',...
    'Tibia','Fibula'};
list_side_folder = {'Right','_R.','_R_','Left','_L.','_L_'};
list_side = {'Right','Left'};

nodes_original = TR_bone.Points;
conlist_original = TR_bone.ConnectivityList;

%% Loop for each desired Coordinate System
for n = 1:length(bone_coord)
    nodes = nodes_original;
    conlist = conlist_original;
    % name = name_original;

    % if side_indx == 1
    %     nodes = nodes.*[1,1,-1]; % Flip all rights to left
    %     conlist = [conlist(:,3) conlist(:,2) conlist(:,1)];
    % end
    % if bone_indx == 1 && bone_coord == 2
    %     joint_indx = [1,3];
    % else
        joint_indx = 1;
    % end

    %% ICP to Template
    % Align users model to the prealigned template model. This orients the
    % model in a fashion that the superior region is in the positive Z
    % direction, the anterior region is in the positive Y direction, and the
    % medial region is in the positive X direction.
    [nodes,cm_nodes] = center(nodes,1);
    better_start = 1;
    [aligned_nodes, RTs] = icp_template(bone_indx, nodes, bone_coord(n), better_start);

    %% Performs coordinate system calculation
    [Temp_Coordinates, Temp_Nodes, z_min_xyz, MEARY, MDTA, TLSA, SVA] = CoordinateSystem(aligned_nodes, bone_indx, bone_coord(n),side_indx);

    %% Joint Origin
    % for n = 1:length(joint_indx)
        % joint = joint_indx(n);
        if joint_indx > 1
            [Temp_Coordinates, Joint] = JointOrigin(Temp_Coordinates, Temp_Nodes, conlist, bone_indx, joint_indx, side_indx);
        else
            Joint = "Center";
        end
    % end

        if bone_indx == 1 && bone_coord(n) == 2
            joint_indx = 3;
            [Temp_Coordinates_FAO, ~] = JointOrigin(Temp_Coordinates, Temp_Nodes, conlist, bone_indx, joint_indx, side_indx);
            FAO_peak = Temp_Coordinates_FAO(1,:); % point of talar dome center?
        else
            FAO_peak = [0,0,0];
        end

    %% Temporarily Attach Coordinate System
    Temp_Nodes_Coords = [Temp_Nodes; Temp_Coordinates; FAO_peak; z_min_xyz; MEARY; MDTA; TLSA; SVA];

    %% Reorient and Translate to Original Input Origin and Orientation
    [~, coords_final, coords_final_unit, ~, talus_coords_FAO, z_min_xyz_final, MEARY_final, MDTA_final, TLSA_final, SVA_final] = reorient(Temp_Nodes_Coords, cm_nodes, side_indx, RTs);

    if bone_indx == 1 && bone_coord(n) == 3 % Additional alignment for talus subtalar ACS
        [aligned_nodes_TST, RTs_TST] = icp_template(bone_indx, nodes, 1, better_start);
        [Temp_Coordinates_TST, Temp_Nodes_TST] = CoordinateSystem(aligned_nodes_TST, bone_indx, 1, side_indx);

        Temp_Nodes_Coords_TST = [Temp_Nodes_TST; Temp_Coordinates_TST; FAO_peak; z_min_xyz; MEARY; MDTA; TLSA; SVA];

        [~, coords_final_TST, coords_final_unit_TST, ~] = reorient(Temp_Nodes_Coords_TST, cm_nodes, side_indx, RTs_TST);

        coords_final = [coords_final(1,:); ((coords_final_TST(2,:) + coords_final(2,:)).'/2)'
            coords_final(3,:); ((coords_final_TST(4,:) + coords_final(4,:)).'/2)'
            coords_final(5,:); ((coords_final_TST(6,:) + coords_final(6,:)).'/2)'];

        coords_final_unit = [coords_final_unit(1,:); ((coords_final_unit_TST(2,:) + coords_final_unit(2,:)).'/2)'
            coords_final_unit(3,:); ((coords_final_unit_TST(4,:) + coords_final_unit(4,:)).'/2)'
            coords_final_unit(5,:); ((coords_final_unit_TST(6,:) + coords_final_unit(6,:)).'/2)'];
    end

    % Final_Bone = triangulation(conlist,nodes_original);
    % figure()
    % plot3(Final_Bone.Points(:,1),Final_Bone.Points(:,2),Final_Bone.Points(:,3),'k.')
    % hold on
    % plot3(z_min_xyz_final(:,1),z_min_xyz_final(:,2),z_min_xyz_final(:,3),'rs','MarkerSize',20)
    % axis equal

    %% Final Plotting
    % screen_size = get(0, 'ScreenSize');
    % fig_width = 800;
    % fig_height = 600;
    % fig_left = (screen_size(3) - fig_width) / 2;
    % fig_bottom = (screen_size(4) - fig_height) / 2;
    %
    % fig1 = figure('Position', [fig_left, fig_bottom+15, fig_width, fig_height]);
    % Final_Bone = triangulation(conlist,nodes_original);
    % patch('Faces',Final_Bone.ConnectivityList,'Vertices',Final_Bone.Points,...
    %     'FaceColor', [0.85 0.85 0.85], ...
    %     'EdgeColor','none',...
    %     'FaceLighting','gouraud',...
    %     'AmbientStrength', 0.15);
    % view([-15 20])
    % camlight HEADLIGHT
    % material('dull');
    % hold on
    % arrow(coords_final(1,:),coords_final(2,:),'FaceColor','g','EdgeColor','g','LineWidth',5,'Length',10)
    % arrow(coords_final(3,:),coords_final(4,:),'FaceColor','b','EdgeColor','b','LineWidth',5,'Length',10)
    % arrow(coords_final(5,:),coords_final(6,:),'FaceColor','r','EdgeColor','r','LineWidth',5,'Length',10)
    % legend(' Nodal Points',' AP Axis',' SI Axis',' ML Axis')
    % text(coords_final(2,1),coords_final(2,2),coords_final(2,3),'   Anterior','HorizontalAlignment','left','FontSize',15,'Color','g');
    % text(coords_final(4,1),coords_final(4,2),coords_final(4,3),'   Superior','HorizontalAlignment','left','FontSize',15,'Color','b');
    % if side_indx == 1
    %     text(coords_final(6,1),coords_final(6,2),coords_final(6,3),'   Lateral','HorizontalAlignment','left','FontSize',15,'Color','r');
    % else
    %     text(coords_final(6,1),coords_final(6,2),coords_final(6,3),'   Medial','HorizontalAlignment','left','FontSize',15,'Color','r');
    % end
    % grid off
    % axis off
    % xlabel('X')
    % ylabel('Y')
    % zlabel('Z')
    % axis equal

    %% Save both coordinate systems to spreadsheet
    if bone_indx == 1 && bone_coord(n) == 2 % TT Talus
        out(1:6,:) = coords_final_unit;
        out(21,:) = talus_coords_FAO;%******
    elseif bone_indx == 1 && bone_coord(n)  == 3 % ST Talus
        out(7:12,:) = coords_final_unit;
    elseif bone_indx == 1 && bone_coord(n) == 1 % TN Talus - me
        out(13:18,:) = coords_final_unit;
        out(19:20,:) = MEARY_final;
    elseif bone_indx == 2 && bone_coord(n)  == 1 % CC Calc
        out(1:6,:) = coords_final_unit;
        out(13,:) = SVA_final;
    elseif bone_indx == 2 && bone_coord(n)  == 2 % ST Calc
        out(7:12,:) = coords_final_unit;
    elseif bone_indx == 13 % Tibia
        out = [coords_final_unit;
            MDTA_final;
            TLSA_final];
    elseif bone_indx == 8 % Metatarsal1
        out(1:6,:) = coords_final_unit;
    elseif bone_indx == 3 % Navicular
        out(1:6,:) = coords_final_unit;
    else
        out = coords_final_unit;
    end

    % establishing minimum points for FAO calculation
    if bone_indx == 2 && bone_coord(n) == 1
        out(31,:) = z_min_xyz_final;
    elseif bone_indx == 8
        out(32,:) = z_min_xyz_final;
    elseif bone_indx == 12
        out(33,:) = z_min_xyz_final;
    end
    % end    

end
end
