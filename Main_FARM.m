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

%% Iterate through each model selected
for m = 1:length(all_files)
    clear bone_indx

    % Extract the name and file extension from the file
    FileName = char(all_files(m));
    [~,name,ext] = fileparts(FileName);
    disp(name)
    name_original = name;

    % Looks through the file name for the bone name
    if exist('bone_indx','var') == 0
        for n = 1:length(list_bone)
            if any(string(extract(lower(FileName),lower(list_bone(n)))) == lower(string(list_bone(n)))) ||...
                any(string(extract(lower(FileName),lower(list_bone2(n)))) == lower(string(list_bone2(n))))
                if exist('bone_indx','var') == 0
                    bone_indx = n;
                else
                    clear bone_indx
                end
            end
        end
    end

    % If the folder and the file don't have the bone name, the user must select
    % the bone name
    if exist('bone_indx','var') == 0
        [bone_indx,~] = listdlg('PromptString', [{strcat('Select which bone this file is:'," ",string(FileName))} {''}], 'ListString', list_bone,'SelectionMode','single');
    end

    % If the folder doesn't have the bone side, this looks through the file
    % name for the bone side
    if exist('side_folder_indx','var') == 0
        for n = 1:length(list_side_folder)
            if any(string(extract(lower(FileName),lower(list_side_folder(n)))) == lower(string(list_side_folder(n))))
                side_folder_indx = n;
            end
        end
    end

    % If the folder and the file don't have the bone side, the user must select
    % the bone side
    if exist('side_folder_indx','var') && side_folder_indx <= 3
        side_indx = 1;
    elseif exist('side_folder_indx','var') && side_folder_indx >= 4
        side_indx = 2;
    else
        [side_indx,~] = listdlg('PromptString', [{strcat('Select which side this file is:'," ",string(FileName))} {''}], 'ListString', list_side,'SelectionMode','single');
    end

    all_bone_indx(1,m) = bone_indx;
end

% List of all possible measurements and their required bones
measurements = {
    'Calcaneal Inclination Angle', [2]
    'Medial Distal Tibial Angle', [13]
    'Saltzman 20 degree', [2, 13]
    'Talar Tilt Angle', [1, 13]
    'Talocalcaneal Angle', [1, 2]
    'Tibial Lateral Surface Angle', [13]
};

% Create a mask to filter measurements based on available bones
mask = cellfun(@(x) all(ismember(x, all_bone_indx)), measurements(:,2));

% Filter the measurements list
filtered_measurements = measurements(mask, 1);
list_measure = horzcat(filtered_measurements)';

% Prompt the user to select measurements
[measure_indx, ~] = listdlg('PromptString', {'Which angles do you want?'}, ...
                             'ListString', list_measure, ...
                             'SelectionMode', 'multiple');

% Map selected indices back to the original measurements
original_measure_indx = find(mask);
selected_measurements = original_measure_indx(measure_indx);







