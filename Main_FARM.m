%% Main Script for 3D Foot and Ankle Radiographic Measurements
clear, clc, close all

% This main code requires the spreadsheet with bone file names.

% Ensure that there are no spaces in the folder name, consider replacing
% spaces with underscores (_).

% While it's not neccessary, naming your file with the laterality (_L_ or
% _Left_ etc.) and the name of the bone (_Calcaneus) will speed up the
% process. I recommend a file name similar to this for ease:
% group_#_bone_laterality.stl (ex. ABC_01_Tibia_Right.stl)

% Load the spreadsheet
[filename, folder_path] = uigetfile('*.xlsx*', 'Please select your FARM sheet');
sheet_path = fullfile(folder_path, filename);

% Get list of sheets
sheets = sheetnames(sheet_path);
% If there is more than one sheet, ask the user to select one
if length(sheets) > 1
    [sheet_idx, tf] = listdlg('PromptString', 'Select a sheet:', 'SelectionMode', 'single', 'ListString', sheets);
    if tf == 0
        error('No sheet selected. Exiting.');
    end
    selected_sheet = sheets{sheet_idx};
else
    selected_sheet = sheets{1};
end


data = readtable(sheet_path, 'ReadVariableNames', false, 'Sheet', selected_sheet);
temp = strfind(folder_path,'\');
FolderName = folder_path(temp(end-1)+1:end-1);

% Extract person names (first row)
names = data{1, :};

% Lists for detemining bone and side
list_bone = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Medial_Cuneiform','Intermediate_Cuneiform',...
    'Lateral_Cuneiform','Metatarsal1','Metatarsal2','Metatarsal3','Metatarsal4','Metatarsal5',...
    'Tibia','Fibula','ANKM','ANK'};
list_bone2 = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Med_Cuneiform','Int_Cuneiform',...
    'Lat_Cuneiform','First_Metatarsal','Second_Metatarsal','Third_Metatarsal','Fourth_Metatarsal','Fifth_Metatarsal',...
    'Tibia','Fibula','ANKM','ANK'};
list_bone3 = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Medial_Cuneiform','Intermediate_Cuneiform',...
    'Lateral_Cuneiform','Metatarsal_1','Metatarsal_2','Metatarsal_3','Metatarsal_4','Metatarsal_5',...
    'Tibia','Fibula','ANKM','ANK'};
list_side_folder = {'Right','_R.','_R_','Left','_L.','_L_'};
list_side = {'Right','Left'};

%% Iterate through each person (column)
for col = 1:width(data)
    clear side_indx bone_metadata side_folder_indx
    ind_name = names{col};
    fprintf('Processing files for: %s\n', ind_name);

    % Extract the STL file names for the current person (excluding the first row)
    stl_files = data{2:end, col};
    stl_files = stl_files(~cellfun('isempty', stl_files)); % Remove empty cells

    % Iterate through each STL file for the current person
    for file_idx = 1:length(stl_files)
        clear bone_indx
        FileName = char(stl_files{file_idx});
        [~, ~, ext] = fileparts(FileName);

        % Looks through the file name for the bone name
        if ~exist('bone_indx', 'var')
            for n = 1:length(list_bone)
                if contains(lower(FileName), lower(list_bone{n})) || contains(lower(FileName), lower(list_bone2{n})) || contains(lower(FileName), lower(list_bone3{n}))
                    bone_indx = n;
                    break;
                end
            end
        end

        % If the file doesn't have the bone name, the user must select
        if ~exist('bone_indx', 'var')
            [bone_indx, ~] = listdlg('PromptString', [{strcat('Select which bone this file is:', " ", string(FileName))} {''}], 'ListString', list_bone, 'SelectionMode', 'single');
        end

        % Looks through the file name for the bone laterality
        if ~exist('side_folder_indx', 'var')
            for n = 1:length(list_side_folder)
                if contains(lower(FileName), lower(list_side_folder{n}))
                    side_folder_indx = n;
                    break;
                end
            end
        end

        % If the folder and the file don't have the bone side, the user must select
        if exist('side_folder_indx', 'var') && side_folder_indx <= 3
            side_indx = 1;
        elseif exist('side_folder_indx', 'var') && side_folder_indx >= 4
            side_indx = 2;
        else
            [side_indx, ~] = listdlg('PromptString', [{strcat('Select which side this file is:', " ", string(FileName))} {''}], 'ListString', list_side, 'SelectionMode', 'single');
        end

        all_bone_indx(1, file_idx) = bone_indx;

        % Load in file based on file type
        if strcmp(ext, '.stl')
            % TR = stlread(fullfile(folder_path, FileName));
            TR = stlread(fullfile(FileName));
            nodes = TR.Points;
            conlist = TR.ConnectivityList;

            bone_name = list_bone{bone_indx};

            % Define the field name for the structure
            field_name = sprintf('%s', bone_name);

            % Create a triangulation object for the bone
            TR_bone = triangulation(conlist, nodes);

            bonestl.(field_name) = TR_bone;

        else
            disp('This is not an acceptable file type at this time, please choose an ".stl" file type.')
            return
        end
    end

    % Loop through list_bone in order
    for i = 1:length(list_bone)
        % Check if the current bone index is in all_bone_indx
        if ismember(i, all_bone_indx)
            % Get the name of the first available bone
            bone_name = list_bone{i};

            [temp_points,cm] = center(bonestl.(bone_name).Points,1);

            % Run icp_template on the first available bone
            if side_indx == 1
                temp_points = temp_points.* [-1,1,1];
            end

            [~, RTs] = icp_template(i, temp_points, 1, 1);


            % Apply the transformation to all bones in all_bone_indx
            for j = all_bone_indx
                transform_bone_name = list_bone{j};

                points = bonestl.(transform_bone_name).Points - cm;

                if side_indx == 1
                    points = points.* [-1,1,1];
                end

                 points = (RTs.Rmetpca * points')';

                % Transform the bone points
                transformed_points = ...
                    (RTs.iR * ((points * RTs.iflip)') + repmat(RTs.iT, 1, length(points')))';

                if side_indx == 1
                    bonestl.(transform_bone_name) = triangulation(bonestl.(transform_bone_name).ConnectivityList,transformed_points.* [-1,1,1]);
                else
                    bonestl.(transform_bone_name) = triangulation(bonestl.(transform_bone_name).ConnectivityList,transformed_points);
                end

                clear transformed_points

            end

            % Exit the loop after transforming all bones
            break;
        end
    end

    % Potentially parallel loop this
    for j = 1:length(all_bone_indx)
        if ismember(all_bone_indx(j), [1, 2, 3, 8, 9, 12, 13])
            AAFACT_bone = list_bone{all_bone_indx(j)};
            % Perform the AAFACT calculation
            out.(AAFACT_bone) = AAFACT_calculation(bonestl.(AAFACT_bone), all_bone_indx(j), side_indx);
        end
    end

    %% Angle Calculations

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Talocalcaneal Angle
        angles.TCA = angle_calculator(out.Talus(7,:), out.Talus(8,:), out.Calcaneus(7,:), out.Calcaneus(8,:), bonestl.Talus, bonestl.Calcaneus, "yz", side_indx);
    else
        angles.TCA = NaN;
    end

    if ismember(2,all_bone_indx) % Calcaneal Inclincation Angle
        angles.CIA = -angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)+1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz", side_indx);
        if angles.CIA > 120 || angles.CIA < -120
            close(gcf);
            angles.CIA = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)-1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz", side_indx);
        end
    else
        angles.CIA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Tibiotalar Angle
        angles.TTA = angle_calculator(out.Tibia(1,:), out.Tibia(6,:), out.Talus(1,:), out.Talus(6,:), bonestl.Tibia, bonestl.Talus, "xz", side_indx);
    else
        angles.TTA = NaN;
    end

    if ismember(2,all_bone_indx) && ismember(13,all_bone_indx) % Hindfoot Alignment Angle
        angles.HAA = angle_calculator(out.Tibia(1,:), out.Tibia(4,:), out.Calcaneus(13,:), out.Tibia(1,:), bonestl.Tibia, bonestl.Calcaneus, "xz", side_indx, 'SVA');
    else
        angles.HAA = NaN;
    end

    if ismember(13,all_bone_indx) % Medial Distal Tibial Angle
        angles.MDTA = angle_calculator(out.Tibia(7,:), out.Tibia(8,:), out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz", side_indx);
    else
        angles.MDTA = NaN;
    end

    if ismember(13,all_bone_indx) % Tibial Lateral Surface Angle
        angles.TLSA = angle_calculator(out.Tibia(9,:), out.Tibia(10,:), out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz", side_indx);
    else
        angles.TLSA = NaN;
    end

    if ismember(13, all_bone_indx) && ismember(15, all_bone_indx) && ismember(16, all_bone_indx) % MFM Tibia AP

            % Convert the input strings to numeric arrays by removing any commas
            lateral_tibial_points = mean(bonestl.ANK.Points);
            medial_tibial_points = mean(bonestl.ANKM.Points);

            % Assuming lateral_tibial_points and medial_tibial_points are already inputted

            % Calculate the vector from medial to lateral point
            medial_to_lateral_vector = lateral_tibial_points - medial_tibial_points;

            % Project this vector onto the XY plane (ignore Z component)
            medial_to_lateral_vector_xy = medial_to_lateral_vector;
            medial_to_lateral_vector_xy(3) = 0;  % Set the Z component to 0

            % Find a vector perpendicular to the XY projection
            % The normal vector to the XY plane is [0, 0, 1]
            normal_vector_xy = [0, 0, 1];

            % Use the cross product to find the perpendicular vector in the XY plane
            perpendicular_vector = cross(medial_to_lateral_vector_xy, normal_vector_xy);

            % Calculate the midpoint between the medial and lateral points
            midpoint = (medial_tibial_points + lateral_tibial_points) / 2;

            % Calculate two points from the perpendicular vector
            % First point is the midpoint between medial and lateral points
            perpendicular_point1 = midpoint;

            % Second point is the midpoint plus the perpendicular vector
            perpendicular_point2 = midpoint + perpendicular_vector;


            % Do the MFM calculation using the input tibial points
            angles.MFMTibAP = angle_calculator(out.Tibia(1,:), out.Tibia(2,:), perpendicular_point1, perpendicular_point2, bonestl.Tibia, bonestl.Tibia, "xy", side_indx);
            if angles.MFMTibAP > 120 || angles.MFMTibAP < -120
                close(gcf);
                angles.MFMTibAP = angle_calculator(out.Tibia(1,:), out.Tibia(2,:), perpendicular_point2, perpendicular_point1, bonestl.Tibia, bonestl.Tibia, "xy", side_indx);
            end
    else
        angles.MFMTibAP = NaN;
    end

    if ismember(2,all_bone_indx) % MFM Calcaneas AP vs Metatarsal 2 AP in Transverse Plane (MFM Calc AP)
        angles.MFMCalcAP = angle_calculator(out.Calcaneus(1,:), out.Calcaneus(2,:), [0 0 0], [0 1 0], bonestl.Calcaneus, bonestl.Calcaneus, "xy", side_indx);
    else
        angles.MFMCalcAP = NaN;
    end

    if ismember(9,all_bone_indx) % MFM Calcaneas AP vs Metatarsal 2 AP in Transverse Plane (MFM 2M AP)
        angles.MFMM2AP = angle_calculator(out.Metatarsal2(1,:), out.Metatarsal2(2,:), [0 0 0], [0 1 0], bonestl.Metatarsal2, bonestl.Metatarsal2, "xy", side_indx);
    else
        angles.MFMM2AP = NaN;
    end

    % if ismember(2,all_bone_indx) && ismember(9,all_bone_indx) % MFM Calcaneas AP vs Metatarsal 2 AP in Transverse Plane (Forefoot Transverse Plane)
    %     angles.MFMForeTrans = angle_calculator(out.Calcaneus(1,:), out.Calcaneus(2,:), out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Calcaneus, bonestl.Metatarsal2, "xy", side_indx);
    % else
    %     angles.MFMForeTrans = NaN;
    % end

    if ismember(13,all_bone_indx) % MFM Tibia SI vs Z in Sagittal Plane (MFM Tibia Lateral)
        angles.MFMTibLat = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)+1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz", side_indx, 'MFMTibSag');
        if angles.MFMTibLat > 120 || angles.MFMTibLat < -120
            close(gcf);
            angles.MFMTibLat = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)-1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz", side_indx, 'MFMTibSag');
        end
    else
        angles.MFMTibLat = NaN;
    end

    if ismember(9,all_bone_indx) % MFM Metatarsal 2 AP vs Y in Sagittal Plane (MFM 2M Lateral)
        angles.MFM2MLat = -angle_calculator(out.Metatarsal2(1,:), [out.Metatarsal2(1,1), out.Metatarsal2(1,2)+1, out.Metatarsal2(1,3)], out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Metatarsal2, bonestl.Metatarsal2, "yz", side_indx);
        if angles.MFM2MLat > 120 || angles.MFM2MLat < -120
            close(gcf);
            angles.MFM2MLat = angle_calculator(out.Metatarsal2(1,:), [out.Metatarsal2(1,1), out.Metatarsal2(1,2)-1, out.Metatarsal2(1,3)], out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Metatarsal2, bonestl.Metatarsal2, "yz", side_indx);
        end
    else
        angles.MFM2MLat = NaN;
    end

    if ismember(13, all_bone_indx) && ismember(2, all_bone_indx) % Milwaukee

        prompt = {'Enter the trace angle:'};
        dlg_title = 'Trace Angle Input';
        num_lines = 1;
        answer = inputdlg(prompt, dlg_title, num_lines);
        trace = str2double(answer{1}); % Convert to numeric

        if side_indx == 1
            new_tibia = bonestl.Tibia.Points * rotz(-trace) * rotx(-45);
            new_calcaneus = bonestl.Calcaneus.Points * rotz(-trace) * rotx(-45);

            new_out_tib = out.Tibia * rotz(-trace) * rotx(-45);
            new_out_calc = out.Calcaneus * rotz(-trace) * rotx(-45);
        else
            new_tibia = bonestl.Tibia.Points * rotz(trace) * rotx(-45);
            new_calcaneus = bonestl.Calcaneus.Points * rotz(trace) * rotx(-45);

            new_out_tib = out.Tibia * rotz(trace) * rotx(-45);
            new_out_calc = out.Calcaneus * rotz(trace) * rotx(-45);
        end

        TR_tibia = triangulation(bonestl.Tibia.ConnectivityList,new_tibia);
        TR_calcaneus = triangulation(bonestl.Calcaneus.ConnectivityList,new_calcaneus);

        % Do the Milwaukee calculation using the input tibia and calc
        angles.MilTib = angle_calculator(new_out_tib(3,:), new_out_tib(4,:), [0 0 0], [0 0 1], TR_tibia, TR_tibia, "xz", side_indx);
        angles.MilCalc = angle_calculator(new_out_calc(1,:), new_out_calc(2,:), [0 0 0], [0 0 1], TR_calcaneus, TR_calcaneus, "xz", side_indx);
    else
        angles.MilTib = NaN;
        angles.MilCalc = NaN;
    end

    % if ismember(2,all_bone_indx) % MFM Calcaneas SI vs Z in Frontal Plane (Hindfoot Frontal Plane)
    %     angles.MFMHindFront = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2), out.Calcaneus(1,3)+1], out.Calcaneus(14,:), out.Calcaneus(15,:), bonestl.Calcaneus, bonestl.Calcaneus, "xz", side_indx);
    %     if angles.MFMHindFront > 120 || angles.MFMHindFront < -120
    %         close(gcf);
    %         angles.MFMHindFront = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2), out.Calcaneus(1,3)-1], out.Calcaneus(14,:), out.Calcaneus(15,:), bonestl.Calcaneus, bonestl.Calcaneus, "xz", side_indx);
    %     end
    % else
    %     angles.MFMHindFront = NaN;
    % end
    % 
    % if ismember(13,all_bone_indx) % MFM Tibia SI vs Z in Frontal Plane (Tibia Frontal Plane)
    %     angles.MFMTibFront = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)+1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz", side_indx);
    %     if angles.MFMTibFront > 120 || angles.MFMTibFront < -120
    %         close(gcf);
    %         angles.MFMTibFront = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)-1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz", side_indx);
    %     end
    % else
    %     angles.MFMTibFront = NaN;
    % end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle 3D
        angles.TNOA3D = angle_calculator(out.Talus(1,:), out.Talus(2,:), out.Talus(13,:), out.Talus(14,:), bonestl.Talus, bonestl.Talus, "3D", side_indx);
    else
        angles.TNOA3D = NaN;
    end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle XY
        angles.TNOAXY = angle_calculator(out.Talus(13,:), out.Talus(14,:), out.Talus(1,:), out.Talus(2,:), bonestl.Talus, bonestl.Talus, "xy", side_indx);
    else
        angles.TNOAXY = NaN;
    end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle YZ
        angles.TNOAYZ = angle_calculator(out.Talus(13,:), out.Talus(14,:), out.Talus(1,:), out.Talus(2,:), bonestl.Talus, bonestl.Talus, "yz", side_indx);
    else
        angles.TNOAYZ = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Axial
        angles.MA_axial = angle_calculator(out.Talus(13,:), out.Talus(14,:), out.Metatarsal1(1,:), out.Metatarsal1(2,:), bonestl.Talus, bonestl.Metatarsal1, "xy", side_indx);
    else
        angles.MA_axial = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Sagittal
        angles.MA_sagittal = angle_calculator(out.Talus(19,:), out.Talus(20,:), out.Metatarsal1(1,:), out.Metatarsal1(2,:), bonestl.Talus, bonestl.Metatarsal1, "yz", side_indx);
    else
        angles.MA_sagittal = NaN;
    end

    if ismember (1,all_bone_indx) && ismember(3,all_bone_indx) % Talonavicular Angle
        angles.TNCA = angle_calculator(out.Talus(13,:), out.Talus(14,:), out.Navicular(1,:), out.Navicular(2,:), bonestl.Navicular, bonestl.Talus,"xy", side_indx);
    else
        angles.TNCA = NaN;
    end
    
    if ismember(2,all_bone_indx) && ismember(8,all_bone_indx) && ismember(12,all_bone_indx) % FAO
        z_min_coords = [out.Calcaneus(16,:); out.Metatarsal1(7,:); out.Metatarsal5(7,:)]; % columns correspond to x y z values of most inferior points
        angles.FAO = FAO_calculation(out.Calcaneus(16,:), out.Metatarsal1(7,:), out.Calcaneus(16,:), out.Metatarsal5(7,:), bonestl.Calcaneus, bonestl.Metatarsal1, bonestl.Metatarsal5, bonestl.Talus, "xy", out.Talus(21,:), z_min_coords);
    else
        angles.FAO = NaN;
    end

    if ismember (8,all_bone_indx) && ismember(9,all_bone_indx) % 1-2 Intermetatarsal
        angles.Intermet12 = angle_calculator(out.Metatarsal1(1,:), out.Metatarsal1(2,:), out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Metatarsal1, bonestl.Metatarsal2,"xy", side_indx);
    else
        angles.Intermet12 = NaN;
    end


    %% Save Angles
    A = [
        "Talocalcaneal Angle",
        "Calcaneal Inclination Angle (MFM Calcaneus Lateral)",
        "Talar Tilt Angle",
        "Hindfoot Alignment Angle",
        "Medial Distal Tibial Angle",
        "Tibial Lateral Surface Angle",
        "MFM Tibial AP",
        "MFM Calcaneal AP",
        "MFM 2nd Metatarsal AP",
        "MFM Tibial Lateral",
        "MFM 2nd Metatarsal Lateral",
        "Milwaukee Tibia",
        "Milwaukee Calcaneus",
        "Talonavicular Offset Angle 3D",
        "Talonavicular Offset Angle XY",
        "Talonavicular Offset Angle YZ",
        "Meary's Angle (Axial)",
        "Meary's Angle (Sagittal)",
        "Talonavicular Angle",
        "Foot and Ankle Offset (%)",
        "Intermetatarsal 1-2"
        ];

    if length(ind_name) > 31
        ind_name = ind_name(1:31);
    end

    fields = fieldnames(angles);
    for i=1:length(fields)
        values(i,1) = getfield(angles,fields{i});
    end

    xlfilename = strcat(folder_path,'Radiograph_Measurements_', FolderName, '.xlsx');
    writematrix(A,xlfilename,'Sheet',ind_name);
    writematrix(values,xlfilename,'Sheet',ind_name,'Range','B1');

end

delete(gcp('nocreate')); % Stops the pool if it's running, does nothing if not
