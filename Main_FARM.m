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

    % Initialize storage for combined STL
    combined_nodes = [];
    combined_faces = [];
    offset = 0; % To handle indexing for faces
    bone_metadata = {}; % To store bone metadata

    % Iterate through each STL file for the current person
    for file_idx = 1:length(stl_files)
        clear bone_indx 
        FileName = char(stl_files{file_idx});
        [~, ~, ext] = fileparts(FileName);
        % disp(name)
        % name_original = name;

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

        % If the folder doesn't have the bone side, this looks through the file
        % name for the bone side
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

            % Append nodes and faces with offsets
            combined_nodes = [combined_nodes; nodes];
            combined_faces = [combined_faces; conlist + offset];
            offset = offset + size(nodes, 1);

            % Store metadata
            bone_metadata{end+1} = struct('name', ind_name, 'bone_indx', bone_indx, 'side_indx', side_indx, ...
                'start_node', offset - size(nodes, 1) + 1, 'end_node', offset, ...
                'start_face', size(combined_faces, 1) - size(conlist, 1) + 1, 'end_face', size(combined_faces, 1));
        else
            disp('This is not an acceptable file type at this time, please choose either a ".stl" file type.')
            return
        end
    end

    % figure()
    % plot3(combined_nodes(:,1),combined_nodes(:,2),combined_nodes(:,3),'.k')
    % axis equal

    if side_indx == 1
        combined_nodes = combined_nodes .* [-1,1,1];
    end

    if ismember(1, all_bone_indx)
        n = find(1 == all_bone_indx);
        metadata = bone_metadata{n};

        % Extract the corresponding nodes and faces for this bone
        start_node = metadata.start_node;
        end_node = metadata.end_node;
        start_face = metadata.start_face;
        end_face = metadata.end_face;

        % Extract the nodes and faces
        temp_talus_nodes = combined_nodes(start_node:end_node, :);

        [~, RTs] = icp_all(1, temp_talus_nodes);

        combined_nodes = combined_nodes*RTs.iflip;

        all_aligned_nodes = (RTs.iR*(combined_nodes') + repmat(RTs.iT,1,length(combined_nodes')))';
    else
        error('You must include the talus, even if you arent analyzing it')
    end

    % all_aligned_nodes = icp_all(all_bone_indx, combined_nodes, side_indx);

    % Iterate through each bone in bone_metadata to separate and save
    for n = 1:length(bone_metadata)
        % Get the metadata for the current bone
        metadata = bone_metadata{n};

        % Extract the corresponding nodes and faces for this bone
        start_node = metadata.start_node;
        end_node = metadata.end_node;
        start_face = metadata.start_face;
        end_face = metadata.end_face;

        % Extract the nodes and faces
        bone_nodes = all_aligned_nodes(start_node:end_node, :);
        bone_faces = combined_faces(start_face:end_face, :);

        % Adjust face indices to start from 1
        bone_faces = bone_faces - (start_node - 1);

        % Define the bone name and its index
        bone_indx = metadata.bone_indx;
        bone_name = list_bone{bone_indx};

        % Define the field name for the structure
        field_name = sprintf('%s', bone_name);

        % Create a triangulation object for the bone
        TR_bone = triangulation(bone_faces, bone_nodes);

        bonestl.(field_name) = TR_bone;

        if bone_indx == 1 || bone_indx == 2 || bone_indx == 13
            % Perform the AAFACT calculation
            out.(field_name) = AAFACT_calculation(TR_bone, bone_indx, 2);
        end
    end

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx)
        angles.TCA = angle_calculator(out.Talus(7,:), out.Talus(8,:), out.Calcaneus(7,:), out.Calcaneus(8,:), bonestl.Talus, bonestl.Calcaneus, "yz");
    else
        angles.TCA = NaN;
    end

    if ismember(2,all_bone_indx)
        angles.CIA = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)+1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz");
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

    xlfilename = strcat(folder_path,'\Radiograph_Measurements_', FolderName, '.xlsx');
    writematrix(A,xlfilename,'Sheet',ind_name);
    writematrix(values,xlfilename,'Sheet',ind_name,'Range','B1');

    

end
