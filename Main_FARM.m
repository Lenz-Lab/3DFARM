%% Main Script for 3D Foot and Ankle Radiographic Measurements
clear, clc, close all

% This main code requires the spreadsheet with bone file names.

% It is highly recommended that you include the TALUS in your input bones,
% however not completely neccessary.

% Ensure that there are no spaces in the folder name, consider replacing
% spaces with underscores (_).

% While it's not neccessary, naming your file with the laterality (_L_ or
% _Left_ etc.) and the name of the bone (_Calcaneus) will speed up the
% process. I recommend a file name similar to this for ease:
% group_#_bone_laterality.stl (ex. ABC_01_Tibia_Right.stl)

% Setup: Load Spreadsheet with bone File Names
[filename, folder_path] = uigetfile('*.xlsx*', 'Please select your FARM sheet');
if isequal(filename, 0)
    error('No file selected.');
end
sheet_path = fullfile(folder_path, filename);

% Get list of sheets
sheets = sheetnames(sheet_path);

% If there is more than one sheet, ask the user to select one
if length(sheets) > 1
    [sheet_idx, tf] = listdlg('PromptString', 'Select a sheet:', 'SelectionMode', 'single', 'ListString', sheets);
    if ~tf
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
list_bone3 = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Medial_Cuneiform','Intermediate_Cuneiform',...
    'Lateral_Cuneiform','Metatarsal_1','Metatarsal_2','Metatarsal_3','Metatarsal_4','Metatarsal_5',...
    'Tibia','Fibula'};
list_side_folder = {'Right','_R.','_R_','Left','_L.','_L_'};
list_side = {'Right','Left'};

%% Iterate through each person (column)
for col = 1:width(data)
    % Clear variables for each person
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

            [~, RTs] = icp_template(i, temp_points, 1, 1, 2);


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

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Calcaneal Inclincation Angle
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

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Medial Distal Tibial Angle
        angles.MDTA = angle_calculator(out.Tibia(7,:), out.Tibia(8,:), out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz", side_indx);
    else
        angles.MDTA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Tibial Lateral Surface Angle
        angles.TLSA = angle_calculator(out.Tibia(9,:), out.Tibia(10,:), out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz", side_indx);
    else
        angles.TLSA = NaN;
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
        "Calcaneal Inclination Angle",
        "Talar Tilt Angle",
        "Hindfoot Alignment Angle",
        "Medial Distal Tibial Angle",
        "Tibial Lateral Surface Angle",
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
