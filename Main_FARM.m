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

choice = questdlg('Are you troubleshooting alignment?', ...
    'Troubleshoot?', 'Yes', 'No', 'No');
trouble = strcmp(choice,'Yes');

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
list_side_folder = {'Right','_R.','_R_','_R ','_R\','_R','Left','_L.','_L_','_L ','_L\','_L'};
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

        % Looks at the column name for the bone laterality
        if ~exist('side_folder_indx', 'var')
            for n = 1:length(list_side_folder)
                if contains(lower(ind_name), lower(list_side_folder{n}))
                    side_folder_indx = n;
                    break;
                end
            end
        end

        % If the folder and the file don't have the bone side, the user must select
        if exist('side_folder_indx', 'var') && side_folder_indx <= 6
            side_indx = 1;
        elseif exist('side_folder_indx', 'var') && side_folder_indx >= 7
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

    %% PreAlignment
    addpath(fullfile("Template_Bones","Anatomical_Bones"));

    % Decide side folder
    if side_indx == 1
        side_str = "Right";
    elseif side_indx == 2
        side_str = "Left";
    else
        error('side_indx must be 1 (Right) or 2 (Left).');
    end

    % Unique bone indices actually loaded for this person
    bone_inds_unique = unique(all_bone_indx(:)');

    % Build combined SUBJECT tri
    allPts = [];
    allTri = [];
    boneRanges = struct('name', {}, 'v_idx', {}, 'f_idx', {});

    for i = 1:numel(bone_inds_unique)
        bidx = bone_inds_unique(i);
        boneName = list_bone{bidx};

        TRb = bonestl.(boneName);
        V   = TRb.Points;
        F   = TRb.ConnectivityList;

        offsetV = size(allPts, 1);
        offsetF = size(allTri, 1);
        allPts = [allPts; V]; %#ok<AGROW>
        allTri = [allTri; F + offsetV]; %#ok<AGROW>

        v_idx = (offsetV + 1) : (offsetV + size(V,1));
        f_idx = (offsetF + 1) : (offsetF + size(F,1));
        boneRanges(end+1) = struct('name', boneName, 'v_idx', v_idx, 'f_idx', f_idx); %#ok<SAGROW>
    end

    TR_subject_combined = triangulation(allTri, allPts);
    TR_subject_combined = center(TR_subject_combined,3);

    % Build combined TEMPLATE tri
    template_root = fullfile("Template_Bones","Anatomical_Bones", side_str);

    allPtsT = [];
    allTriT = [];

    for i = 1:numel(bone_inds_unique)
        bidx = bone_inds_unique(i);
        boneName = list_bone{bidx};

        tpl_path = fullfile(template_root, boneName + ".stl");
        if ~exist(tpl_path, 'file')
            continue
        end

        TRt = stlread(tpl_path);
        Vt  = TRt.Points;
        Ft  = TRt.ConnectivityList;

        offsetT = size(allPtsT,1);
        allPtsT = [allPtsT; Vt]; %#ok<AGROW>
        allTriT = [allTriT; Ft + offsetT]; %#ok<AGROW>
    end

    TR_template_combined = triangulation(allTriT, allPtsT);

    if trouble == 0
        [aligned_subject_combined_points] = icp_complete(TR_template_combined.Points,TR_subject_combined.Points,TR_template_combined.ConnectivityList,2,trouble);
    elseif trouble == 1
        manual_aligned_subject_combined_points = manual_align_points(TR_subject_combined.Points, side_indx);
        [aligned_subject_combined_points] = icp_complete(TR_template_combined.Points,manual_aligned_subject_combined_points,TR_template_combined.ConnectivityList,2,trouble);
    end

    % A fast global -> local index map we’ll reuse and reset per bone
    Ntot = size(aligned_subject_combined_points, 1);
    global2local = zeros(Ntot, 1, 'uint32');

    for k = 1:numel(boneRanges)
        boneName = boneRanges(k).name;
        v_idx    = boneRanges(k).v_idx;   % global vertex indices for this bone
        f_idx    = boneRanges(k).f_idx;   % face ROWS (in allTri) for this bone

        % Vertices for this bone (already aligned)
        Vb = aligned_subject_combined_points(v_idx, :);

        % Global faces that belong to this bone
        Fb_global = allTri(f_idx, :);

        % Build local remap: global -> [1..numel(v_idx)]
        global2local(:) = 0;
        global2local(v_idx) = uint32(1:numel(v_idx));
        Fb_local = [ global2local(Fb_global(:,1)), ...
            global2local(Fb_global(:,2)), ...
            global2local(Fb_global(:,3)) ];

        % Construct aligned triangulation for this bone
        bonestl.(boneName) = triangulation(double(Fb_local), double(Vb));
    end

    %% AAFACT calculations
    for j = 1:length(all_bone_indx)
        if ismember(all_bone_indx(j), [1, 2, 3, 4, 8, 9, 12, 13])
            AAFACT_bone = list_bone{all_bone_indx(j)};
            TR_bone = bonestl.(AAFACT_bone);
            bone_indx = all_bone_indx(j);
            % Perform the AAFACT calculation
            out.(AAFACT_bone) = AAFACT_calculation(TR_bone, bone_indx, side_indx);
        else
            AAFACT_bone = list_bone{all_bone_indx(j)};
            % Add filler for unused bones
            out.(AAFACT_bone) = [0 0 0];
        end
    end

    %% Transform View
    boneNames = fieldnames(bonestl);

    % For Hindfoot/Forefoot Measurements
    if isfield(out, 'Calcaneus') && isfield(out, 'Metatarsal1') && isfield(out, 'Talus')
        coordSys1 = [out.Calcaneus(1,:); out.Calcaneus(2,:); out.Calcaneus(4,:); out.Calcaneus(6,:)];
        coordSys2 = [out.Talus(1,:); out.Talus(2,:); out.Talus(4,:); out.Talus(6,:)];
        coordSys3 = [out.Metatarsal1(1,:); out.Metatarsal1(2,:); out.Metatarsal1(4,:); out.Metatarsal1(6,:)];

        T_transform = averageCoordinateSystems(coordSys1, coordSys2, coordSys3, side_indx);

        [out_rotated, bonestl_transformed, ~, ~] = ...
            transform_bones(T_transform, boneNames, bonestl, out);
    end

    % For Ankle Measurements
    if isfield(out, 'Tibia')
        coordSysT = [out.Tibia(1,:); out.Tibia(2,:); out.Tibia(4,:); out.Tibia(6,:)];
        T_transform = averageCoordinateSystems(coordSysT, coordSysT, coordSysT, side_indx);

        [out_tibiarotated, bonestl_tibiatransformed, bonestl_saltztransformed, out_saltzrotated] = ...
            transform_bones(T_transform, boneNames, bonestl, out);
    end

    % For Misc Measurements (Not recommended)
    if isfield(out, 'Talus') && (~isfield(out, 'Calcaneus') || ~isfield(out, 'Metatarsal1'))
        coordSysT = [out.Talus(1,:); out.Talus(2,:); out.Talus(4,:); out.Talus(6,:)];
        T_transform = averageCoordinateSystems(coordSysT, coordSysT, coordSysT, side_indx);

        [out_rotated, bonestl_transformed, ~, ~] = ...
            transform_bones(T_transform, boneNames, bonestl, out);
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
        angles.STCA = angle_calculator(out_rotated.Talus(13,:), out_rotated.Talus(14,:), out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), bonestl_transformed.Talus, bonestl_transformed.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.STCA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Axial Talocalcaneal Angle
        angles.ATCA = angle_calculator(out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), out_rotated.Talus(13,:), out_rotated.Talus(14,:), bonestl_transformed.Talus, bonestl_transformed.Calcaneus, "xy", side_indx, XY_viewer);
    else
        angles.ATCA = NaN;
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
            angles.TTA = angle_calculator(out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(6,:), out_tibiarotated.Talus(16,:), out_tibiarotated.Talus(17,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Talus, "xz", side_indx, XZ_viewer);
        else
            angles.TTA = angle_calculator(out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(6,:), out_tibiarotated.Talus(17,:), out_tibiarotated.Talus(16,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Talus, "xz", side_indx, XZ_viewer);
        end
    else
        angles.TTA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) && ismember(13,all_bone_indx) % Hindfoot Alignment Angle
        angles.HAA = angle_calculator(out_tibiarotated.Calcaneus(7,:), out_tibiarotated.Talus(15,:), out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(4,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Calcaneus, "xz", side_indx, XZ_viewer);
    else
        angles.HAA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(2,all_bone_indx) && ismember(13,all_bone_indx) % 20 deg Hindfoot Alignment Angle
        angles.HAA20 = angle_calculator(out_saltzrotated.Calcaneus(7,:), out_saltzrotated.Talus(15,:), out_saltzrotated.Tibia(1,:), out_saltzrotated.Tibia(4,:), bonestl_saltztransformed.Tibia, bonestl_saltztransformed.Calcaneus, "xz", side_indx, XZ_viewer);
    else
        angles.HAA20 = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Hindfoot Moment Arm
        [angles.HMA, Q, segPts] = vect_distance_calculator(out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(4,:), out_tibiarotated.Calcaneus(7,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Calcaneus, "xz", side_indx, XZ_viewer);
    else
        angles.HMA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Medial Distal Tibial Angle
        angles.MDTA = abs(angle_calculator(out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(4,:), out_tibiarotated.Tibia(7,:), out_tibiarotated.Tibia(8,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Tibia, "xz", side_indx, XZ_viewer));
    else
        angles.MDTA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Tibial Lateral Surface Angle
        angles.TLSA = angle_calculator(out_tibiarotated.Tibia(9,:), out_tibiarotated.Tibia(10,:), out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(4,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Tibia, "yz", side_indx, YZ_viewer);
    else
        angles.TLSA = NaN;
    end

    if ismember(1,all_bone_indx) % Talar Neck Offset Angle XY
        angles.TNOAXY = abs(angle_calculator(out_rotated.Talus(1,:), out_rotated.Talus(2,:), out_rotated.Talus(7,:), out_rotated.Talus(8,:), bonestl_transformed.Talus, bonestl_transformed.Talus, "xy", side_indx, XY_viewer));
    else
        angles.TNOAXY = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Axial
        angles.MA_axial = angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Talus(7,:), out_rotated.Talus(8,:),  bonestl_transformed.Talus, bonestl_transformed.Metatarsal1, "xy", side_indx, XY_viewer);
    else
        angles.MA_axial = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(8,all_bone_indx) % Meary's Sagittal
        angles.MA_sagittal = angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Talus(13,:), out_rotated.Talus(14,:), bonestl_transformed.Talus, bonestl_transformed.Metatarsal1, "yz", side_indx, YZ_viewer);
    else
        angles.MA_sagittal = NaN;
    end

    if ismember (1,all_bone_indx) && ismember(3,all_bone_indx) % Talonavicular Angle
        angles.TNA = angle_calculator( out_rotated.Navicular(1,:), out_rotated.Navicular(2,:),out_rotated.Talus(7,:), out_rotated.Talus(8,:), bonestl_transformed.Navicular, bonestl_transformed.Talus,"xy", side_indx, XY_viewer);
    else
        angles.TNA = NaN;
    end
    
    if ismember(2,all_bone_indx) && ismember(8,all_bone_indx) && ismember(12,all_bone_indx) % Foot Type Percentage
        z_min_coords = [out_rotated.Calcaneus(7,:); out_rotated.Metatarsal1(7,:); out_rotated.Metatarsal5(7,:)]; % columns correspond to x y z values of most inferior points
        angles.FTP = FTP_calculation(out_rotated.Calcaneus(7,:), out_rotated.Metatarsal1(7,:), out_rotated.Calcaneus(7,:), out_rotated.Metatarsal5(7,:), bonestl_transformed.Calcaneus, bonestl_transformed.Metatarsal1, bonestl_transformed.Metatarsal5, bonestl_transformed.Talus, "xy", out_rotated.Talus(15,:), z_min_coords, XY_viewer, side_indx);
    else
        angles.FTP = NaN;
    end

    if ismember (8,all_bone_indx) && ismember(9,all_bone_indx) % 1-2 Intermetatarsal
        angles.Intermet12 = abs(angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Metatarsal2(1,:), out_rotated.Metatarsal2(2,:), bonestl_transformed.Metatarsal1, bonestl_transformed.Metatarsal2,"xy", side_indx, XY_viewer));
    else
        angles.Intermet12 = NaN;
    end

    if ismember(2,all_bone_indx) && ismember(8,all_bone_indx) % Calcaneal 1st Metatarsal Angle
        angles.C1M = 180 - angle_calculator(out_rotated.Metatarsal1(1,:), out_rotated.Metatarsal1(2,:), out_rotated.Calcaneus(1,:), out_rotated.Calcaneus(2,:), bonestl_transformed.Calcaneus, bonestl_transformed.Metatarsal1, "yz", side_indx, YZ_viewer);
    else
        angles.C1M = NaN;
    end

    if ismember(13,all_bone_indx) && ismember(2,all_bone_indx) % Sagittal Tibiocalcaneal Angle
        angles.TibCA = angle_calculator(out_tibiarotated.Calcaneus(1,:), out_tibiarotated.Calcaneus(2,:), out_tibiarotated.Tibia(3,:), out_tibiarotated.Tibia(4,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Calcaneus, "yz", side_indx, YZ_viewer);
    else
        angles.TibCA = NaN;
    end

    if ismember(1,all_bone_indx) && ismember(13,all_bone_indx) % Axial Tibiocalcaneal Angle
        angles.TibCAx = angle_calculator(out_tibiarotated.Tibia(1,:), out_tibiarotated.Tibia(2,:), out_tibiarotated.Calcaneus(1,:), out_tibiarotated.Calcaneus(2,:), bonestl_tibiatransformed.Tibia, bonestl_tibiatransformed.Calcaneus, "xy", side_indx, XY_viewer);
    else
        angles.TibCAx = NaN;
    end

    if ismember(8,all_bone_indx) && ismember(12,all_bone_indx) % Metatarsal Stacking Angle
        angles.MSA = angle_calculator(out_rotated.Metatarsal5(8,:), out_rotated.Metatarsal5(7,:), out_rotated.Metatarsal5(8,:), out_rotated.Metatarsal1(7,:), bonestl_transformed.Metatarsal1, bonestl_transformed.Metatarsal5, "yz", side_indx, YZ_viewer);
    else
        angles.MSA = NaN;
    end

    if ismember(8,all_bone_indx) && ismember(12,all_bone_indx) && ismember(1,all_bone_indx) && ismember(2,all_bone_indx) % Medial-Lateral Column Ratio
        angles.MLCR = mlcr_calculator(out_rotated.Metatarsal1(7,:), out_rotated.Talus(13,:), out_rotated.Metatarsal5(7,:), out_rotated.Calcaneus(10,:), bonestl_transformed, side_indx);
    else
        angles.MLCR = NaN;
    end

    if ismember(3,all_bone_indx) && ismember(4,all_bone_indx) % Naviculocuboid Overlap
        angles.NCO = ncoverlap_calculator(out_rotated.Cuboid(7,:), out_rotated.Cuboid(8,:), out_rotated.Navicular(7,:), bonestl_transformed, side_indx);
    else
        angles.NCO = NaN;
    end

    %% Save Angles
    A = [
        "Talocalcaneal Angle (Sagittal)",
        "Talocalcaneal Angle (Axial)",
        "Calcaneal Inclination Angle",
        "Talar Tilt Angle",
        "Hindfoot Alignment Angle",
        "20 deg Hindfoot Alignment Angle",
        "Hindfoot Moment Arm",
        "Medial Distal Tibial Angle",
        "Tibial Lateral Surface Angle",
        "Talonavicular Offset Angle (Axial)",
        "Meary's Angle (Axial)",
        "Meary's Angle (Sagittal)",
        "Talonavicular Angle",
        "Foot Type Percentage (%)",
        "Intermetatarsal 1-2",
        "Calcaneal 1st Metatarsal Angle",
        "Tibiocalcaneal Angle (Sagittal)",
        "Tibiocalcaneal Angle (Axial)",
        "Metatarsal Stacking Angle",
        "Medial-Lateral Column Ratio",
        "Naviculocuboid Overlap"
        ];

    if length(ind_name) > 31
        ind_name = ind_name(1:31);
    end

    fields = fieldnames(angles);
    for i=1:length(fields)
        values(i,1) = getfield(angles,fields{i});
    end

    range = strcat('A',string(length(A)+1),':B100');

    for try_index = 1:5
        try
            xlfilename = strcat(folder_path,'Radiograph_Measurements_', FolderName, '.xlsx');
            writematrix(A,xlfilename,'Sheet',ind_name);
            writematrix(values,xlfilename,'Sheet',ind_name,'Range','B1');
            blankCells = repmat("", length(A)+2, 2);
            writematrix(blankCells, xlfilename, 'Sheet', ind_name, 'Range', range);
            try_index = 5;
        catch
            disp("Error attempting to write to Excel file, reattempting...")
            continue
        end
    end
end
