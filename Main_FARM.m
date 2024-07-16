%% Main Script for 3D Foot and Ankle Radiographic Measurements
clear, clc, close all

% This main code only requires the users bone model input. Select the
% folder where the file is and then select the bone model(s) you wish the
% apply a coordinate system to.

% Ensure that there are no spaces in the folder name, consider replacing 
% spaces with underscores (_).

% Currently, this code works for all bones from the tibia and fibula
% through the metatarsals.

% While it's not neccessary, naming your file with the laterality (_L_ or
% _Left_ etc.) and the name of the bone (_Calcaneus) will speed up the
% process. I recommend a file name similar to this for ease:
% group_#_bone_laterality.stl (ex. ABC_01_Tibia_Right.stl)

% Determine the files in the folder selected
FolderPathName = uigetdir('*.*', 'Select folder with your bones');
files = dir(fullfile(FolderPathName, '*.*'));
files = files(~ismember({files.name},{'.','..'}));

temp = strfind(FolderPathName,'\');
FolderName = FolderPathName(temp(end)+1:end); % Extracts the folder name selected

%% Load all files into list
temp = struct2cell(files);
list_files = temp(1,:);

% Select the models that you want a coordinate system of
[files_indx,~] = listdlg('PromptString',[{'Select all of your bones for 1 foot and ankle'} {''}], 'ListString', list_files, 'SelectionMode','multiple');

all_files = list_files(files_indx)'; % stores all files selected

% Lists for detemining bone and side
list_bone = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Medial_Cuneiform','Intermediate_Cuneiform',...
    'Lateral_Cuneiform','Metatarsal1','Metatarsal2','Metatarsal3','Metatarsal4','Metatarsal5',...
    'Tibia','Fibula'};
list_bone2 = {'Talus', 'Calcaneus', 'Navicular', 'Cuboid', 'Med_Cuneiform','Int_Cuneiform',...
    'Lat_Cuneiform','First_Metatarsal','Second_Metatarsal','Third_Metatarsal','Fourth_Metatarsal','Fifth_Metatarsal',...
    'Tibia','Fibula'};
list_side_folder = {'Right','_R.','_R_','Left','_L.','_L_'};
list_side = {'Right','Left'};

%% Initialize storage for combined STL
combined_nodes = [];
combined_faces = [];
offset = 0; % To handle indexing for faces
bone_metadata = {}; % To store bone metadata

%% Iterate through each model selected
for m = 1:length(all_files)
    clear bone_indx side_folder_indx

    % Extract the name and file extension from the file
    FileName = char(all_files(m));
    [~,name,ext] = fileparts(FileName);
    disp(name)
    name_original = name;

    % Looks through the file name for the bone name
    if ~exist('bone_indx','var')
        for n = 1:length(list_bone)
            if contains(lower(FileName), lower(list_bone{n})) || contains(lower(FileName), lower(list_bone2{n}))
                bone_indx = n;
                break;
            end
        end
    end

    % If the folder and the file don't have the bone name, the user must select
    if ~exist('bone_indx','var')
        [bone_indx,~] = listdlg('PromptString', [{strcat('Select which bone this file is:'," ",string(FileName))} {''}], 'ListString', list_bone,'SelectionMode','single');
    end

    % If the folder doesn't have the bone side, this looks through the file
    % name for the bone side
    if ~exist('side_folder_indx','var')
        for n = 1:length(list_side_folder)
            if contains(lower(FileName), lower(list_side_folder{n}))
                side_folder_indx = n;
                break;
            end
        end
    end

    % If the folder and the file don't have the bone side, the user must select
    if exist('side_folder_indx','var') && side_folder_indx <= 3
        side_indx = 1;
    elseif exist('side_folder_indx','var') && side_folder_indx >= 4
        side_indx = 2;
    else
        [side_indx,~] = listdlg('PromptString', [{strcat('Select which side this file is:'," ",string(FileName))} {''}], 'ListString', list_side,'SelectionMode','single');
    end

    all_bone_indx(1,m) = bone_indx;

    %% Load in file based on file type
    if ext == ".stl"
        TR = stlread(fullfile(FolderPathName, FileName));
        nodes = TR.Points;
        conlist = TR.ConnectivityList;

        % Append nodes and faces with offsets
        combined_nodes = [combined_nodes; nodes];
        combined_faces = [combined_faces; conlist + offset];
        offset = offset + size(nodes, 1);

        % Store metadata
        bone_metadata{end+1} = struct('name', name, 'bone_indx', bone_indx, 'side_indx', side_indx, ...
                                      'start_node', offset - size(nodes, 1) + 1, 'end_node', offset, ...
                                      'start_face', size(combined_faces, 1) - size(conlist, 1) + 1, 'end_face', size(combined_faces, 1));
    else
        disp('This is not an acceptable file type at this time, please choose either a ".stl" file type.')
        return
    end
end

all_aligned_nodes = icp_all(all_bone_indx, combined_nodes, side_indx);

figure()
plot3(combined_nodes(:,1),combined_nodes(:,2),combined_nodes(:,3),'.k')
axis equal


figure()
plot3(all_aligned_nodes(:,1),all_aligned_nodes(:,2),all_aligned_nodes(:,3),'.k')
axis equal

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

    % Define the bone name and side
    bone_name = list_bone{metadata.bone_indx};

    % Define the field name for the structure
    field_name = sprintf('%s', bone_name);

    % Create a triangulation object for the bone
    TR_bone = triangulation(bone_faces, bone_nodes);

    bonestl.(field_name) = TR_bone;

    if metadata.bone_indx == 1 || metadata.bone_indx == 2 || metadata.bone_indx == 13
        % Perform the AAFACT calculation
        out.(field_name) = AAFACT_calculation(TR_bone, metadata.bone_indx, 1);
    end
end

if ismember(1,all_bone_indx) && ismember(2,all_bone_indx)
    angles.TCA = angle_calculator(out.Talus(7,:), out.Talus(8,:), out.Calcaneus(7,:), out.Calcaneus(8,:), bonestl.Talus, bonestl.Calcaneus, "yz");
else
    angles.TCA = NaN;
end

if ismember(2,all_bone_indx)
    angles.CIA = angle_calculator(out.Calcaneus(1,:), [out.Calcaneus(1,1), out.Calcaneus(1,2)-1, out.Calcaneus(1,3)], out.Calcaneus(1,:), out.Calcaneus(2,:), bonestl.Calcaneus, bonestl.Calcaneus, "yz");
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

if length(name) > 31
    name = name(1:31);
end

fields = fieldnames(angles);
for i=1:length(fields)
    values(i,1) = getfield(angles,fields{i});
end

xlfilename = strcat(FolderPathName,'\Radiograph_Measurements_',FolderName,'.xlsx');
writematrix(A,xlfilename,'Sheet',name);
writematrix(values,xlfilename,'Sheet',name,'Range','B1')
