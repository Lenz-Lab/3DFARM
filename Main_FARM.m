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
    'Tibia','Fibula'};
list_bone2 = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Med_Cuneiform','Int_Cuneiform',...
    'Lat_Cuneiform','First_Metatarsal','Second_Metatarsal','Third_Metatarsal','Fourth_Metatarsal','Fifth_Metatarsal',...
    'Tibia','Fibula'};
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
                if contains(lower(FileName), lower(list_bone{n})) || contains(lower(FileName), lower(list_bone2{n}))
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
            TR = stlread(fullfile(folder_path, FileName));
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

    for j = 1:length(all_bone_indx)
        if ismember(all_bone_indx(j), [1, 2, 9, 13])
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
        angles.CIA = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)+1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz", side_indx);
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

    if ismember(13, all_bone_indx) % MFM Calcaneas AP vs Tibia BB AP in Sagittal Plane (Tibia Transverse Plane)

        % Ask the user if they are doing an MFM
        % mfm_response = questdlg('Are you doing an MFM calculation?', 'MFM Calculation', 'Yes', 'No', 'No');
        mfm_response = 'No';

        if strcmp(mfm_response, 'Yes')
            % If Yes, prompt for the lateral and medial tibial 3D points
            prompt = {'Enter lateral tibial 3D points (format: x y z):', 'Enter medial tibial 3D points (format: x y z):'};
            dlg_title = 'Input for MFM Tibial Points';
            num_lines = 1;
            default_points = {'0 0 0', '0 0 0'};  % Default values in case user provides no input
            answer = inputdlg(prompt, dlg_title, num_lines, default_points);

            % Convert the input strings to numeric arrays by removing any commas
            lateral_tibial_points = str2num(regexprep(answer{1}, '[,]', ' ')); %#ok<ST2NM>
            medial_tibial_points = str2num(regexprep(answer{2}, '[,]', ' '));  %#ok<ST2NM>

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
            angles.MFMTibTrans = angle_calculator(out.Calcaneus(1,:), out.Calcaneus(2,:), perpendicular_point1, perpendicular_point2, bonestl.Calcaneus, bonestl.Tibia, "xy", side_indx);
        else
            % If No, skip the MFM calculation and assign NaN
            angles.MFMTibTrans = NaN;
        end
    else
        angles.MFMTibTrans = NaN;
    end

    if ismember(2,all_bone_indx) && ismember(9,all_bone_indx) % MFM Calcaneas AP vs Metatarsal 2 AP in Transverse Plane (Forefoot Transverse Plane)
        angles.MFMForeTrans = angle_calculator(out.Calcaneus(1,:), out.Calcaneus(2,:), out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Calcaneus, bonestl.Metatarsal2, "xy", side_indx);
    else
        angles.MFMForeTrans = NaN;
    end

    if ismember(13,all_bone_indx) % MFM Tibia SI vs Z in Sagittal Plane (Tibia Sagittal Plane)
        angles.MFMTibSag = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)+1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz", side_indx, 'MFMTibSag');
        if angles.MFMTibSag > 120 || angles.MFMTibSag < -120
            close(gcf);
            angles.MFMTibSag = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)-1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz", side_indx, 'MFMTibSag');
        end
    else
        angles.MFMTibSag = NaN;
    end

    if ismember(9,all_bone_indx) % MFM Metatarsal 2 AP vs Y in Sagittal Plane (Forefoot Sagittal Plane)
        angles.MFMForeSag = angle_calculator(out.Metatarsal2(1,:), [out.Metatarsal2(1,1), out.Metatarsal2(1,2)+1, out.Metatarsal2(1,3)], out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Metatarsal2, bonestl.Metatarsal2, "yz", side_indx);
        if angles.MFMForeSag > 120 || angles.MFMForeSag < -120
            close(gcf);
            angles.MFMForeSag = angle_calculator(out.Metatarsal2(1,:), [out.Metatarsal2(1,1), out.Metatarsal2(1,2)-1, out.Metatarsal2(1,3)], out.Metatarsal2(1,:), out.Metatarsal2(2,:), bonestl.Metatarsal2, bonestl.Metatarsal2, "yz", side_indx);
        end
    else
        angles.MFMForeSag = NaN;
    end

    if ismember(2,all_bone_indx) % MFM Calcaneas SI vs Z in Frontal Plane (Hindfoot Frontal Plane)
        angles.MFMHindFront = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2), out.Calcaneus(1,3)+1], out.Calcaneus(14,:), out.Calcaneus(15,:), bonestl.Calcaneus, bonestl.Calcaneus, "xz", side_indx);
        if angles.MFMHindFront > 120 || angles.MFMHindFront < -120
            close(gcf);
            angles.MFMHindFront = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2), out.Calcaneus(1,3)-1], out.Calcaneus(14,:), out.Calcaneus(15,:), bonestl.Calcaneus, bonestl.Calcaneus, "xz", side_indx);
        end
    else
        angles.MFMHindFront = NaN;
    end

    if ismember(13,all_bone_indx) % MFM Tibia SI vs Z in Frontal Plane (Tibia Frontal Plane)
        angles.MFMTibFront = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)+1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz", side_indx);
        if angles.MFMTibFront > 120 || angles.MFMTibFront < -120
            close(gcf);
            angles.MFMTibFront = angle_calculator(out.Tibia(1,:), [out.Tibia(1,1), out.Tibia(1,2), out.Tibia(1,3)-1], out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz", side_indx);
        end
    else
        angles.MFMTibFront = NaN;
    end

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

    %% Save Angles
    A = [
        "Talocalcaneal Angle",
        "Calcaneal Inclination Angle",
        "Talar Tilt Angle",
        "Hindfoot Alignment Angle",
        "Medial Distal Tibial Angle",
        "Tibial Lateral Surface Angle",
        "MFM Tibial Transverse",
        "MFM Forefoot Transverse",
        "MFM Tibial Sagittal",
        "MFM Forefoot Sagittal",
        "MFM Hindfoot Frontal",
        "MFM Tibial Frontal",
        "Talonavicular Offset Angle 3D",
        "Talonavicular Offset Angle XY",
        "Talonavicular Offset Angle YZ"
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