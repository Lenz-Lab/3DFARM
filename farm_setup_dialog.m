function opts = farm_setup_dialog()
% FARM_SETUP_DIALOG  Single startup window for Main_FARM.
%
% opts = farm_setup_dialog()
%
% Lets the user pick the FARM sheet (and which sheet inside it, when there
% is more than one) and turn on optional settings, which all default to off.
%
% opts.folder_path    : folder of the FARM sheet, with a trailing separator
% opts.filename       : FARM sheet file name
% opts.selected_sheet : sheet to read the bone file names from
% opts.trouble        : true to manually pre-align for troubleshooting
% opts.vicon          : true to also export the VICON measurements
%
% Errors if the window is cancelled or closed.

opts = struct('folder_path', '', 'filename', '', 'selected_sheet', '', ...
    'trouble', false, 'vicon', false);
confirmed = false;

bg = get(0, 'DefaultUicontrolBackgroundColor');
fig = figure('Name', '3D FARM Setup', 'NumberTitle', 'off', 'MenuBar', 'none', ...
    'ToolBar', 'none', 'Resize', 'off', 'Color', bg, 'Units', 'pixels', ...
    'Position', [0 0 540 260], 'Tag', 'FARM_setup', ...
    'CloseRequestFcn', @(~,~) uiresume(gcbf));
movegui(fig, 'center');

% Input spreadsheet
uicontrol(fig, 'Style', 'text', 'String', 'FARM sheet:', 'HorizontalAlignment', 'left', ...
    'BackgroundColor', bg, 'Position', [15 215 80 20]);
file_box = uicontrol(fig, 'Style', 'edit', 'String', '', 'Enable', 'inactive', ...
    'HorizontalAlignment', 'left', 'Position', [95 216 335 22], 'Tag', 'file_box');
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Browse...', 'Position', [440 214 85 26], ...
    'Tag', 'browse', 'Callback', @browse);

uicontrol(fig, 'Style', 'text', 'String', 'Worksheet:', 'HorizontalAlignment', 'left', ...
    'BackgroundColor', bg, 'Position', [15 180 80 20]);
sheet_menu = uicontrol(fig, 'Style', 'popupmenu', 'String', {'(select a FARM sheet first)'}, ...
    'Enable', 'off', 'Position', [95 182 335 22], 'Tag', 'sheet_menu');

% Optional settings (all off by default)
uicontrol(fig, 'Style', 'text', 'String', 'Optional (leave unchecked for a standard run):', ...
    'HorizontalAlignment', 'left', 'FontWeight', 'bold', 'BackgroundColor', bg, ...
    'Position', [15 135 400 20]);
trouble_box = uicontrol(fig, 'Style', 'checkbox', 'Value', 0, 'BackgroundColor', bg, ...
    'String', 'Troubleshoot alignment (manually pre-align each foot)', ...
    'Position', [25 108 500 22], 'Tag', 'trouble');
vicon_box = uicontrol(fig, 'Style', 'checkbox', 'Value', 0, 'BackgroundColor', bg, ...
    'String', 'Export VICON measurements to a separate spreadsheet', ...
    'Position', [25 82 500 22], 'Tag', 'vicon');

run_button = uicontrol(fig, 'Style', 'pushbutton', 'String', 'Run', 'Enable', 'off', ...
    'Position', [340 15 85 30], 'Tag', 'run', 'Callback', @run);
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Cancel', 'Position', [440 15 85 30], ...
    'Tag', 'cancel', 'Callback', @(~,~) uiresume(fig));

uiwait(fig);

if isvalid(fig)
    delete(fig);
end
if ~confirmed
    error('No file selected.');
end

    function browse(~, ~)
        [f, p] = uigetfile('*.xlsx*', 'Please select your FARM sheet');
        if isequal(f, 0)
            return
        end
        sheets = cellstr(sheetnames(fullfile(p, f)));

        opts.filename = f;
        opts.folder_path = p;
        % Show the end of long paths so the file name stays visible
        full_path = fullfile(p, f);
        shown_path = full_path;
        if length(shown_path) > 52
            shown_path = ['...' shown_path(end-48:end)];
        end
        set(file_box, 'String', shown_path, 'TooltipString', full_path);
        set(sheet_menu, 'String', sheets, 'Value', 1);
        if numel(sheets) > 1
            set(sheet_menu, 'Enable', 'on');
        else
            set(sheet_menu, 'Enable', 'off');
        end
        set(run_button, 'Enable', 'on');
    end

    function run(~, ~)
        sheets = get(sheet_menu, 'String');
        opts.selected_sheet = sheets{get(sheet_menu, 'Value')};
        opts.trouble = logical(get(trouble_box, 'Value'));
        opts.vicon = logical(get(vicon_box, 'Value'));
        confirmed = true;
        uiresume(fig);
    end
end
