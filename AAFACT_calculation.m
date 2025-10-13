function out = AAFACT_calculation(TR_bone, bone_indx, side_indx)

%% Initialize 'out'
% Define the size mapping for initialization based on bone_indx
size_mapping = containers.Map({1, 2, 3, 8, 12, 13}, {23, 16, 7, 7, 7, 10}); % Default to 6 if not specified
default_size = 6;

if isKey(size_mapping, bone_indx)
    out = zeros(size_mapping(bone_indx), 3);
else
    out = zeros(default_size, 3);
end

%% Setup which bone coordinate systems needed to be calculated
if bone_indx == 1
    bone_coord = [1, 2]; % TN&TT
elseif bone_indx == 2
    bone_coord = 1; % CC
else
    bone_coord = 1; % Others
end

nodes_original = TR_bone.Points;
conlist_original = TR_bone.ConnectivityList;

%% Loop for each desired Coordinate System
for n = 1:length(bone_coord)
    nodes = nodes_original;
    conlist = conlist_original;

    if side_indx == 1
        nodes = nodes .* [-1,1,1];
        conlist = [conlist(:,3) conlist(:,2) conlist(:,1)];
    end

    joint_indx = 1;

    %% ICP to Template
    % Align users model to the prealigned template model. This orients the
    % model in a fashion that the superior region is in the positive Z
    % direction, the anterior region is in the positive Y direction, and the
    % medial region is in the positive X direction.
    [nodes,cm_nodes] = center(nodes,1);
    better_start = 1;
    [aligned_nodes, RTs] = icp_template_simp(bone_indx, nodes, bone_coord(n), better_start);

    %% Performs coordinate system calculation
    [Temp_Coordinates, Temp_Nodes, MDTA, TLSA, z_min_xyz, MEARY, TTA, HAA] = CoordinateSystem(aligned_nodes, bone_indx, bone_coord(n), side_indx);

    %% Joint Origin
    if joint_indx > 1
        [Temp_Coordinates, ~] = JointOrigin(Temp_Coordinates, Temp_Nodes, conlist, bone_indx, joint_indx, side_indx);
    end

    if bone_indx == 1 && bone_coord(n) == 2
        joint_indx = 3;
        [Temp_Coordinates_FAO, ~] = JointOrigin(Temp_Coordinates, Temp_Nodes, conlist, bone_indx, joint_indx, side_indx);
        FAO_peak = Temp_Coordinates_FAO(1,:); % point of talar dome center
    else
        FAO_peak = [0,0,0];
    end

    %% Temporarily Attach Coordinate System
    Temp_Nodes_Coords = [Temp_Nodes; Temp_Coordinates; HAA; TTA; FAO_peak; z_min_xyz; MEARY; MDTA; TLSA];

    %% Reorient and Translate to Original Input Origin and Orientation
    [~, coords_final, coords_final_unit, ~, HAA_final, TTA_final, talus_coords_FAO, z_min_xyz_final, MEARY_final, MDTA_final, TLSA_final] = reorient(Temp_Nodes_Coords, cm_nodes, side_indx, RTs);

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
    % coords_final_unit = [origin; AP vector; origin; SI vector; origin; ML vector]
    switch bone_indx
        case 1 % Talus
            switch bone_coord(n)
                case 2 % TT Talus
                    out(1:6, :) = coords_final_unit;
                    out(15, :) = talus_coords_FAO;
                    out(16:17, :) = TTA_final;
                case 1 % TN Talus
                    out(7:12, :) = coords_final_unit;
                    out(13:14, :) = MEARY_final;
            end
        case 2 % Calcaneus
            switch bone_coord(n)
                case 1 % CC Calc
                    out(1:6, :) = coords_final_unit;
                    out(7, :) = z_min_xyz_final;
                    out(8:9, :) = HAA_final;
            end
        case 3 % Navicular
            out(1:6, :) = coords_final_unit;
        case 8 % Metatarsal 1
            out(1:6, :) = coords_final_unit;
            out(7, :) = z_min_xyz_final;
        case 12 % Metatarsal 5
            out(1:6, :) = coords_final_unit;
            out(7, :) = z_min_xyz_final;
        case 13 % Tibia
            out(1:6, :) = coords_final_unit;
            out(7:8, :) = MDTA_final;
            out(9:10, :) = TLSA_final;
        otherwise
            out = coords_final_unit;
    end

end
end
