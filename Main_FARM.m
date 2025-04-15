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

    %% Check Alignment
    % Compute the rotation matrix using reorient90
    % rotmat = reorient90(out); % Ensure 'out' is properly defined before this
    rotmat = reorientglobal(out); % Ensure 'out' is properly defined before this

    % Create a new structure for rotated bones
    bonestl_rotated = struct();

    % Get the field names in bonestl (e.g., 'Talus', 'Calcaneus', etc.)
    boneNames = fieldnames(bonestl);

    % Loop through each bone and apply the rotation
    for i = 1:length(boneNames)
        boneName = boneNames{i}; % Get the current bone name

        % Apply rotation to the vertices and create a new triangulation
        rotated_points = (rotmat * bonestl.(boneName).Points')';
        bonestl_rotated.(boneName) = triangulation(bonestl.(boneName).ConnectivityList, rotated_points);

        % Apply rotation to the out structure
        out_rotated.(boneName) = (rotmat * out.(boneName)')';
    end

    %% Angle Calculations
    av_origin = (out_rotated.Talus(1,:) + out_rotated.Calcaneus(1,:) + out_rotated.Metatarsal1(1,:))/3;
    av_Y = (out_rotated.Talus(2,:) + out_rotated.Calcaneus(2,:) + out_rotated.Metatarsal1(2,:))/3;
    av_Z = (out_rotated.Talus(4,:) + out_rotated.Calcaneus(4,:) + out_rotated.Metatarsal1(4,:))/3;
    av_X = (out_rotated.Talus(6,:) + out_rotated.Calcaneus(6,:) + out_rotated.Metatarsal1(6,:))/3;

    YZ_viewer = [av_origin, av_Y, av_origin, av_Z];
    XZ_viewer = [av_origin, av_X, av_origin, av_Z];
    XY_viewer = [av_origin, av_X, av_origin, av_Y];

    % YZ_viewer = [out_rotated.Talus(1,:), out_rotated.Talus(2,:), out_rotated.Talus(3,:), out_rotated.Talus(4,:)];
    % XZ_viewer = [out_rotated.Talus(3,:), out_rotated.Talus(4,:), out_rotated.Talus(5,:), out_rotated.Talus(6,:)];
    % XY_viewer = [out_rotated.Talus(5,:), out_rotated.Talus(6,:), out_rotated.Talus(1,:), out_rotated.Talus(2,:)];

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Talocalcaneal Angle
        angles.TCA = angle_calculator(out_rotated.Talus(7,:), out_rotated.Talus(8,:), out_rotated.Calcaneus(7,:), out_rotated.Calcaneus(8,:), bonestl_rotated.Talus, bonestl_rotated.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.TCA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Calcaneal Inclincation Angle
        diffe = abs(out_rotated.Calcaneus(2,:) - out_rotated.Calcaneus(1,:));
        [~, maxIndex] = max(diffe);

        if maxIndex == 2
            AP_global = [out_rotated.Calcaneus(1,1), out_rotated.Calcaneus(2,2), out_rotated.Calcaneus(1,3)];
        elseif maxIndex == 1
            AP_global = [out_rotated.Calcaneus(2,1), out_rotated.Calcaneus(1,2), out_rotated.Calcaneus(1,3)];
        elseif maxIndex == 3
            AP_global = [out_rotated.Calcaneus(1,1), out_rotated.Calcaneus(1,2), out_rotated.Calcaneus(2,3)];
        end

        angles.CIA = angle_calculator(out_rotated.Calcaneus(1,:), AP_global, out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), bonestl_rotated.Calcaneus, bonestl_rotated.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.CIA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Tibiotalar Angle
        angles.TTA = angle_calculator(out_rotated.Talus(1,:), out_rotated.Talus(6,:), out_rotated.Tibia(1,:), out_rotated.Tibia(6,:),bonestl_rotated.Tibia, bonestl_rotated.Talus, "xz", side_indx, XZ_viewer);
    else
        angles.TTA = NaN;
    end

    if ismember(2,all_bone_indx) && ismember(13,all_bone_indx) % Hindfoot Alignment Angle
        angles.HAA = angle_calculator(out_rotated.Calcaneus(13,:), out_rotated.Tibia(1,:), out_rotated.Tibia(1,:), out_rotated.Tibia(4,:), bonestl_rotated.Tibia, bonestl_rotated.Calcaneus, "xz", side_indx, XZ_viewer); % Flip this around
    else
        angles.HAA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Medial Distal Tibial Angle
        angles.MDTA = angle_calculator(out_rotated.Tibia(7,:), out_rotated.Tibia(8,:), out_rotated.Tibia(1,:), out_rotated.Tibia(4,:), bonestl_rotated.Tibia, bonestl_rotated.Tibia, "xz", side_indx, XZ_viewer);
    else
        angles.MDTA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Tibial Lateral Surface Angle
        angles.TLSA = angle_calculator(out_rotated.Tibia(9,:), out_rotated.Tibia(10,:), out_rotated.Tibia(1,:), out_rotated.Tibia(4,:), bonestl_rotated.Tibia, bonestl_rotated.Tibia, "yz", side_indx, YZ_viewer);
    else
        angles.TLSA = NaN;
    end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle XY
        angles.TNOAXY = angle_calculator(out_rotated.Talus(13,:), out_rotated.Talus(14,:), out_rotated.Talus(1,:), out_rotated.Talus(2,:), bonestl_rotated.Talus, bonestl_rotated.Talus, "xy", side_indx, XY_viewer);
    else
        angles.TNOAXY = NaN;
    end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle YZ
        angles.TNOAYZ = angle_calculator(out_rotated.Talus(13,:), out_rotated.Talus(14,:), out_rotated.Talus(1,:), out_rotated.Talus(2,:), bonestl_rotated.Talus, bonestl_rotated.Talus, "yz", side_indx, YZ_viewer);
    else
        angles.TNOAYZ = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Axial
        angles.MA_axial = angle_calculator(out_rotated.Talus(13,:), out_rotated.Talus(14,:), out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), bonestl_rotated.Talus, bonestl_rotated.Metatarsal1, "xy", side_indx, XY_viewer);
    else
        angles.MA_axial = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Sagittal
        angles.MA_sagittal = angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Talus(19,:), out_rotated.Talus(20,:), bonestl_rotated.Talus, bonestl_rotated.Metatarsal1, "yz", side_indx, YZ_viewer);
    else
        angles.MA_sagittal = NaN;
    end

    if ismember (1,all_bone_indx) && ismember(3,all_bone_indx) % Talonavicular Angle
        angles.TNA = angle_calculator(out_rotated.Talus(13,:), out_rotated.Talus(14,:), out_rotated.Navicular(1,:), out_rotated.Navicular(2,:), bonestl_rotated.Navicular, bonestl_rotated.Talus,"xy", side_indx, XY_viewer);
    else
        angles.TNA = NaN;
    end
    
    if ismember(2,all_bone_indx) && ismember(8,all_bone_indx) && ismember(12,all_bone_indx) % FAO
        z_min_coords = [out_rotated.Calcaneus(16,:); out_rotated.Metatarsal1(7,:); out_rotated.Metatarsal5(7,:)]; % columns correspond to x y z values of most inferior points
        angles.FAO = FAO_calculation(out_rotated.Calcaneus(16,:), out_rotated.Metatarsal1(7,:), out_rotated.Calcaneus(16,:), out_rotated.Metatarsal5(7,:), bonestl_rotated.Calcaneus, bonestl_rotated.Metatarsal1, bonestl_rotated.Metatarsal5, bonestl_rotated.Talus, "xy", out_rotated.Talus(21,:), z_min_coords, XY_viewer);
    else
        angles.FAO = NaN;
    end

    if ismember (8,all_bone_indx) && ismember(9,all_bone_indx) % 1-2 Intermetatarsal
        angles.Intermet12 = angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Metatarsal2(1,:), out_rotated.Metatarsal2(2,:), bonestl_rotated.Metatarsal1, bonestl_rotated.Metatarsal2,"xy", side_indx, XY_viewer);
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
    blankCells = repmat("", 37, 2); % here 3 columns; adjust as needed
    writematrix(blankCells, xlfilename, 'Sheet', ind_name, 'Range', 'A14:B50');
end

delete(gcp('nocreate')); % Stops the pool if it's running, does nothing if not
