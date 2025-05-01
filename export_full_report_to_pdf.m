function export_full_report_to_pdf(measurementNames, angleValues, figureHandles, folder_path, ind_name)
pdf_filename = fullfile(folder_path, strcat('Radiograph_Measurements_', ind_name, '_Report.pdf'));

% Summary Table
fig_summary = figure('Visible', 'off');
axis off;

% Prepare text lines
summary_lines = ["Measurement Summary"; ""];
for i = 1:length(measurementNames)
    line = sprintf('%-35s : %.2f degrees', measurementNames{i}, angleValues(i));
    summary_lines = [summary_lines; line];
end

% Display as text
text(0, 1, summary_lines, 'FontName', 'Courier', 'FontSize', 10, 'VerticalAlignment', 'top');

exportgraphics(fig_summary, pdf_filename, 'ContentType', 'vector', 'Resolution', 300);
close(fig_summary);


% ===== Following Pages: Figures =====
for i = 1:length(figureHandles)
    fig = figureHandles(i);
    % Add title with measurement name and value
    figure(fig);
    sgtitle(sprintf('%s\n%.2f degrees', measurementNames{i}, angleValues(i)), 'FontSize', 14, 'FontWeight', 'bold');
        % Export and append to PDF
        exportgraphics(fig, pdf_filename, 'ContentType', 'vector', 'Resolution', 300, 'Append', true);
        close(fig);  % close after exporting to clean up
    end

    fprintf('Full PDF report saved to: %s\n', pdf_filename);
end
