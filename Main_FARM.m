%% Main Script for 3D Foot and Ankle Radiographic Measurements
clear, clc, close all

% This main code requires the spreadsheet with bone file names, and the
% talus must be one of those bones.

% The talus is required regardless of measurement to ensure proper
% consistent alignment.

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

    % Check if the word "talus" is present in any cell
    isTalusPresent = any(cellfun(@(x) contains(x, 'talus', 'IgnoreCase', true), stl_files));

    % If "talus" is not found, display an error message
    if ~isTalusPresent
        error('You must include the talus, even if you aren''t analyzing it');
    end

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

            if side_indx == 1
                bone_nodes = nodes .* [1,1,-1];
                bone_faces = [conlist(:,3) conlist(:,2) conlist(:,1)];
            else
                bone_nodes = nodes;
                bone_faces = conlist;
            end

            bone_name = list_bone{bone_indx};

            % Define the field name for the structure
            field_name = sprintf('%s', bone_name);

            % Create a triangulation object for the bone
            TR_bone = triangulation(bone_faces, bone_nodes);

            bonestl.(field_name) = TR_bone;

        else
            disp('This is not an acceptable file type at this time, please choose either a ".stl" file type.')
            return
        end

        % if ~ismember(1, all_bone_indx)
        %     error('You must include the talus, even if you arent analyzing it')
        % end

        % for n = 1:length(all_bone_indx)
        if bone_indx == 1 || bone_indx == 2 || bone_indx == 13
            % Perform the AAFACT calculation
            out.(field_name) = AAFACT_calculation(bonestl.(field_name), bone_indx, 2);
        end
    end


    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx)
        angles.TCA = angle_calculator(out.Talus(7,:), out.Talus(8,:), out.Calcaneus(7,:), out.Calcaneus(8,:), bonestl.Talus, bonestl.Calcaneus, "yz");
    else
        angles.TCA = NaN;
    end

    if ismember(2,all_bone_indx)
        angles.CIA = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)+1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz");
        if angles.CIA > 120
            close(gcf);
            angles.CIA = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)-1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz");
        end
    else
        angles.CIA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx)
        angles.TTA = angle_calculator(out.Tibia(1,:), out.Tibia(6,:), out.Talus(1,:), out.Talus(6,:), bonestl.Tibia, bonestl.Talus, "xz");
    else
        angles.TTA = NaN;
    end

    if ismember(2,all_bone_indx) && ismember(13,all_bone_indx)
        angles.SVA = angle_calculator(out.Tibia(1,:), out.Tibia(4,:), out.Calcaneus(13,:), out.Tibia(1,:), bonestl.Tibia, bonestl.Calcaneus, "xz");
    else
        angles.SVA = NaN;
    end

    if ismember(13,all_bone_indx)
        angles.MDTA = angle_calculator(out.Tibia(7,:), out.Tibia(8,:), out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "xz");
    else
        angles.MDTA = NaN;
    end

    if ismember(13,all_bone_indx)
        angles.TLSA = angle_calculator(out.Tibia(9,:), out.Tibia(10,:), out.Tibia(1,:), out.Tibia(4,:), bonestl.Tibia, bonestl.Tibia, "yz");
    else
        angles.TLSA = NaN;
    end

    %% Save Angles
    A = [
        "Talocalcaneal Angle",
        "Calcaneal Inclination Angle",
        "Talar Tilt Angle",
        "Saltzman 20 degree",
        "Medial Distal Tibial Angle",
        "Tibial Lateral Surface Angle"
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
