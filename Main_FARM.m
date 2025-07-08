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
list_bone4 = {'Talus', 'Calc', 'Navicular', 'Cuboid', 'Med_Cuneiform','Int_Cuneiform',...
    'Lat_Cuneiform','1st_Met','2nd_Met','3rd_Met','4th_Met','5th_Met',...
    'Tibia','Fibula'};
list_side_folder = {'Right','_R.','_R_','_R ','_R\','Left','_L.','_L_','_L ','_L\'};
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
                if contains(lower(FileName), lower(list_bone{n})) || contains(lower(FileName), lower(list_bone2{n})) || contains(lower(FileName), lower(list_bone3{n})) || contains(lower(FileName), lower(list_bone4{n}))
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
        if exist('side_folder_indx', 'var') && side_folder_indx <= 5
            side_indx = 1;
        elseif exist('side_folder_indx', 'var') && side_folder_indx >= 6
            side_indx = 2;
        else
            [side_indx, ~] = listdlg('PromptString', [{strcat('Select which side this file is:', " ", string(FileName))} {''}], 'ListString', list_side, 'SelectionMode', 'single');
        end

        all_bone_indx(1, file_idx) = bone_indx;

        % Load in file based on file type
        if strcmp(ext, '.stl')

            try
                % Attempt to read the STL file using the full path
                TR = stlread(fullfile(folder_path, FileName));
            catch
                try
                    % If the first attempt fails, try reading using just the filename
                    TR = stlread(FileName);
                catch ME
                    % If both attempts fail, display an error message
                    error('Failed to read STL file: %s\nError: %s', FileName, ME.message);
                end
            end

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

    for j = 1:length(all_bone_indx)
        if ismember(all_bone_indx(j), [1, 2, 3, 8, 9, 12, 13])
            AAFACT_bone = list_bone{all_bone_indx(j)};
            % Perform the AAFACT calculation
            out.(AAFACT_bone) = AAFACT_calculation(bonestl.(AAFACT_bone), all_bone_indx(j), side_indx);
        else
            AAFACT_bone = list_bone{all_bone_indx(j)};
            % Add filler for unused bones
            out.(AAFACT_bone) = [0 0 0];
        end
    end

    %% Transform View
    if isfield(out, 'Calcaneus') && isfield(out, 'Metatarsal1') && isfield(out, 'Talus')
        coordSys1 = [out.Calcaneus(1,:); out.Calcaneus(2,:); out.Calcaneus(4,:); out.Calcaneus(6,:)];
        coordSys2 = [out.Talus(1,:); out.Talus(2,:); out.Talus(4,:); out.Talus(6,:)];
        coordSys3 = [out.Metatarsal1(1,:); out.Metatarsal1(2,:); out.Metatarsal1(4,:); out.Metatarsal1(6,:)];

        T_transform = averageCoordinateSystems(coordSys1, coordSys2, coordSys3, side_indx);
    else
        coordSysT = [out.Talus(1,:); out.Talus(2,:); out.Talus(4,:); out.Talus(6,:)];
        T_transform = averageCoordinateSystems(coordSysT, coordSysT, coordSysT, side_indx);
    end

    % Create a new structure for transformed bones
    bonestl_transformed = struct();

    % Get the field names in bonestl (e.g., 'Talus', 'Calcaneus', etc.)
    boneNames = fieldnames(bonestl);

    % Loop through each bone and apply the rotation
    for i = 1:length(boneNames)
        boneName = boneNames{i}; % Get the current bone name

        % Convert to homogenous coordinates (nx4)
        n = size(bonestl.(boneName).Points, 1);
        homogeneous_points = [bonestl.(boneName).Points, ones(n, 1)];

        % Transform vertices and create new triangulation
        transformed_homogeneous = (T_transform * homogeneous_points')';
        transformed_points = transformed_homogeneous(:, 1:3);
        bonestl_transformed.(boneName) = triangulation(bonestl.(boneName).ConnectivityList, transformed_points);

        n = size(out.(boneName), 1);
        homogeneous_out = [out.(boneName), ones(n, 1)];
        transformed_homogeneous_out = (T_transform * homogeneous_out')';
        out_rotated.(boneName) = transformed_homogeneous_out(:, 1:3);
    end

    % Perform for Saltzman View
    for i = 1:length(boneNames)
        boneName = boneNames{i};
        if boneName == "Talus" || boneName == "Calcaneus" || boneName == "Tibia"
            homogeneous_points = [bonestl_transformed.(boneName).Points];

            Saltz_transform = rotx(20);

            % Transform vertices and create new triangulation
            transformed_saltzhomogeneous = (Saltz_transform * homogeneous_points')';
            transformed_saltzpoints = transformed_saltzhomogeneous(:, :);
            bonestl_saltztransformed.(boneName) = triangulation(bonestl.(boneName).ConnectivityList, transformed_saltzpoints);

            homogeneous_saltzout = [out_rotated.(boneName)];
            transformed_homogeneous_saltzout = (Saltz_transform * homogeneous_saltzout')';
            out_saltzrotated.(boneName) = transformed_homogeneous_saltzout(:, :);
        end
    end

    %% Angle Calculations
    av_origin = [0 0 0];
    av_Y = [0 1 0];
    av_Z = [0 0 1];
    av_X = [1 0 0];

    YZ_viewer = [av_origin, av_Y, av_origin, av_Z];
    XZ_viewer = [av_origin, av_X, av_origin, av_Z];
    XY_viewer = [av_origin, av_X, av_origin, av_Y];

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Sagittal Talocalcaneal Angle
        angles.STCA = angle_calculator(out_rotated.Talus(19,:), out_rotated.Talus(20,:), out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), bonestl_transformed.Talus, bonestl_transformed.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.TCA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Axial Talocalcaneal Angle
        angles.ATCA = angle_calculator(out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), out_rotated.Talus(19,:), out_rotated.Talus(20,:), bonestl_transformed.Talus, bonestl_transformed.Calcaneus, "xy", side_indx, XY_viewer);
    else
        angles.TCA = NaN;
    end

    if ismember(2,all_bone_indx) % Calcaneal Inclincation Angle
        diffe = abs(out_rotated.Calcaneus(2,:) - out_rotated.Calcaneus(1,:));
        [~, maxIndex] = max(diffe);

        if maxIndex == 2
            AP_global = [out_rotated.Calcaneus(1,1), out_rotated.Calcaneus(2,2), out_rotated.Calcaneus(1,3)];
        elseif maxIndex == 1
            AP_global = [out_rotated.Calcaneus(2,1), out_rotated.Calcaneus(1,2), out_rotated.Calcaneus(1,3)];
        elseif maxIndex == 3
            AP_global = [out_rotated.Calcaneus(1,1), out_rotated.Calcaneus(1,2), out_rotated.Calcaneus(2,3)];
        end

        angles.CIA = angle_calculator(out_rotated.Calcaneus(1,:), AP_global, out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), bonestl_transformed.Calcaneus, bonestl_transformed.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.CIA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Talar Tilt Angle
        if side_indx == 1
            angles.TTA = angle_calculator(out_rotated.Tibia(1,:), out_rotated.Tibia(6,:), out_rotated.Talus(22,:), out_rotated.Talus(23,:), bonestl_transformed.Tibia, bonestl_transformed.Talus, "xz", side_indx, XZ_viewer);
        else
            angles.TTA = angle_calculator(out_rotated.Tibia(1,:), out_rotated.Tibia(6,:), out_rotated.Talus(23,:), out_rotated.Talus(22,:), bonestl_transformed.Tibia, bonestl_transformed.Talus, "xz", side_indx, XZ_viewer);
        end
    else
        angles.TTA = NaN;
    end

    if ismember(2,all_bone_indx) && ismember(13,all_bone_indx) % Hindfoot Alignment Angle
        angles.HAA = angle_calculator(out_saltzrotated.Tibia(1,:), out_saltzrotated.Tibia(4,:), out_saltzrotated.Calcaneus(13,:), out_saltzrotated.Talus(21,:), bonestl_saltztransformed.Tibia, bonestl_saltztransformed.Calcaneus, "xz", side_indx, XZ_viewer);
    else
        angles.HAA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Medial Distal Tibial Angle
        angles.MDTA = abs(angle_calculator(out_rotated.Tibia(1,:), out_rotated.Tibia(4,:), out_rotated.Tibia(7,:), out_rotated.Tibia(8,:), bonestl_transformed.Tibia, bonestl_transformed.Tibia, "xz", side_indx, XZ_viewer));
    else
        angles.MDTA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Tibial Lateral Surface Angle
        angles.TLSA = angle_calculator(out_rotated.Tibia(9,:), out_rotated.Tibia(10,:), out_rotated.Tibia(1,:), out_rotated.Tibia(4,:), bonestl_transformed.Tibia, bonestl_transformed.Tibia, "yz", side_indx, YZ_viewer);
    else
        angles.TLSA = NaN;
    end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle XY
        angles.TNOAXY = abs(angle_calculator(out_rotated.Talus(1,:), out_rotated.Talus(2,:), out_rotated.Talus(13,:), out_rotated.Talus(14,:), bonestl_transformed.Talus, bonestl_transformed.Talus, "xy", side_indx, XY_viewer));
    else
        angles.TNOAXY = NaN;
    end

    % if ismember(1,all_bone_indx) % Talar Neck Offset Angle YZ
    %     angles.TNOAYZ = angle_calculator(out_rotated.Talus(13,:), out_rotated.Talus(14,:), out_rotated.Talus(1,:), out_rotated.Talus(2,:), bonestl_transformed.Talus, bonestl_transformed.Talus, "yz", side_indx, YZ_viewer);
    % else
    %     angles.TNOAYZ = NaN;
    % end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Axial
        angles.MA_axial = angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Talus(13,:), out_rotated.Talus(14,:),  bonestl_transformed.Talus, bonestl_transformed.Metatarsal1, "xy", side_indx, XY_viewer);
    else
        angles.MA_axial = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Sagittal
        angles.MA_sagittal = angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Talus(19,:), out_rotated.Talus(20,:), bonestl_transformed.Talus, bonestl_transformed.Metatarsal1, "yz", side_indx, YZ_viewer);
    else
        angles.MA_sagittal = NaN;
    end

    if ismember (1,all_bone_indx) && ismember(3,all_bone_indx) % Talonavicular Angle
        angles.TNA = angle_calculator( out_rotated.Navicular(1,:), out_rotated.Navicular(2,:),out_rotated.Talus(13,:), out_rotated.Talus(14,:), bonestl_transformed.Navicular, bonestl_transformed.Talus,"xy", side_indx, XY_viewer);
    else
        angles.TNA = NaN;
    end
    
    if ismember(2,all_bone_indx) && ismember(8,all_bone_indx) && ismember(12,all_bone_indx) % FAO
        z_min_coords = [out_rotated.Calcaneus(16,:); out_rotated.Metatarsal1(7,:); out_rotated.Metatarsal5(7,:)]; % columns correspond to x y z values of most inferior points
        angles.FAO = FAO_calculation(out_rotated.Calcaneus(16,:), out_rotated.Metatarsal1(7,:), out_rotated.Calcaneus(16,:), out_rotated.Metatarsal5(7,:), bonestl_transformed.Calcaneus, bonestl_transformed.Metatarsal1, bonestl_transformed.Metatarsal5, bonestl_transformed.Talus, "xy", out_rotated.Talus(21,:), z_min_coords, XY_viewer);
    else
        angles.FAO = NaN;
    end

    if ismember (8,all_bone_indx) && ismember(9,all_bone_indx) % 1-2 Intermetatarsal
        angles.Intermet12 = abs(angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Metatarsal2(1,:), out_rotated.Metatarsal2(2,:), bonestl_transformed.Metatarsal1, bonestl_transformed.Metatarsal2,"xy", side_indx, XY_viewer));
    else
        angles.Intermet12 = NaN;
    end

    % if ismember(1,all_bone_indx) % Talar Declination Angle
    %     diffe = abs(out_rotated.Talus(2,:) - out_rotated.Talus(1,:));
    %     [~, maxIndex] = max(diffe);
    % 
    %     if maxIndex == 2
    %         AP_global = [out_rotated.Talus(1,1), out_rotated.Talus(2,2), out_rotated.Talus(1,3)];
    %     elseif maxIndex == 1
    %         AP_global = [out_rotated.Talus(2,1), out_rotated.Talus(1,2), out_rotated.Talus(1,3)];
    %     elseif maxIndex == 3
    %         AP_global = [out_rotated.Talus(1,1), out_rotated.Talus(1,2), out_rotated.Talus(2,3)];
    %     end
    % 
    %     angles.TDA = angle_calculator(out_rotated.Talus(1,:), AP_global, out_rotated.Talus(1,:), out_rotated.Talus(2,:), bonestl_transformed.Talus, bonestl_transformed.Talus, "yz", side_indx, YZ_viewer);
    % else
    %     angles.TDA = NaN;
    % end

    if ismember(2,all_bone_indx) && ismember(8,all_bone_indx) % Calcaneal 1st Metatarsal Angle
        angles.C1M = 180 - angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), bonestl_transformed.Calcaneus, bonestl_transformed.Metatarsal1, "yz", side_indx, YZ_viewer);
    else
        angles.C1M = NaN;
    end

    if ismember(13,all_bone_indx) && ismember(2,all_bone_indx) % Tibiocalcaneal Angle
        angles.TibCA = angle_calculator( out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), out_rotated.Tibia(3,:), out_rotated.Tibia(4,:), bonestl_transformed.Tibia, bonestl_transformed.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.TibCA = NaN;
    end

    % if ismember(3,all_bone_indx) && ismember(2,all_bone_indx) % Navicular Ground Angle
    %     diffe = abs(out_rotated.Navicular(2,:) - out_rotated.Navicular(1,:));
    %     [~, maxIndex] = max(diffe);
    % 
    %     if maxIndex == 2
    %         AP_global = [out_rotated.Navicular(1,1), out_rotated.Navicular(2,2), out_rotated.Navicular(1,3)];
    %     elseif maxIndex == 1
    %         AP_global = [out_rotated.Navicular(2,1), out_rotated.Navicular(1,2), out_rotated.Navicular(1,3)];
    %     elseif maxIndex == 3
    %         AP_global = [out_rotated.Navicular(1,1), out_rotated.Navicular(1,2), out_rotated.Navicular(2,3)];
    %     end
    % 
    %     angles.NGA = angle_calculator(out_rotated.Navicular(1,:), AP_global, out_rotated.Calcaneus(16,:), out_rotated.Navicular(7,:), bonestl_transformed.Navicular, bonestl_transformed.Navicular, "yz", side_indx, YZ_viewer);
    % else
    %     angles.NGA = NaN;
    % end

    %% Save Angles
    A = [
        "Sagittal Talocalcaneal Angle",
        "Axial Talocalcaneal Angle",
        "Calcaneal Inclination Angle",
        "Talar Tilt Angle",
        "Hindfoot Alignment Angle",
        "Medial Distal Tibial Angle",
        "Tibial Lateral Surface Angle",
        "Talonavicular Offset Angle (Axial)",
        % "Talonavicular Offset Angle (Sagittal)",
        "Meary's Angle (Axial)",
        "Meary's Angle (Sagittal)",
        "Talonavicular Angle",
        "Foot and Ankle Offset (%)",
        "Intermetatarsal 1-2",
        % "Talar Declination Angle",
        "Calcaneal 1st Metatarsal Angle",
        "Tibiocalcaneal Angle",
        % "Navicular Ground Angle",
        % "Medial-Lateral Column Ratio"
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
    blankCells = repmat("", 37, 2); % here 3 columns; adjust as needed
    writematrix(blankCells, xlfilename, 'Sheet', ind_name, 'Range', 'A15:B50');
end
