function size_scale = subject_scale(bonestl, template_root)
% SUBJECT_SCALE  Factor that brings a small foot up to the template size.
%
% size_scale = subject_scale(bonestl, template_root)
%
% The alignment and coordinate system steps were built around adult-sized
% bones and break down on much smaller feet (e.g. pediatric). For each input
% bone with a full foot template in template_root, its size relative to the
% template is sqrt(template surface area / bone surface area), which does
% not depend on the bone's orientation or mesh density. The tibia and fibula
% are left out because how much of them is scanned varies. The median of
% these ratios is returned when the foot is clearly smaller than the
% templates, otherwise 1. Adult feet measure 0.8-1.1, so they aren't scaled.
%
% Scaling only fixes the size; bones shaped differently from the templates
% (e.g. still ossifying) can still align poorly.

min_scale = 1.2; % only scale feet smaller than ~83% of the template size

ratios = [];
bone_names = fieldnames(bonestl);
for i = 1:numel(bone_names)
    tpl_path = fullfile(template_root, bone_names{i} + ".stl");
    if any(strcmp(bone_names{i}, {'Tibia', 'Fibula'})) || ~exist(tpl_path, 'file')
        continue
    end
    ratios(end+1) = sqrt(surface_area(stlread(tpl_path)) / surface_area(bonestl.(bone_names{i}))); %#ok<AGROW>
end

if isempty(ratios) || median(ratios) < min_scale
    size_scale = 1;
else
    size_scale = median(ratios);
end

end

function A = surface_area(TR)
P = TR.Points;
F = TR.ConnectivityList;
A = sum(vecnorm(cross(P(F(:,2),:) - P(F(:,1),:), P(F(:,3),:) - P(F(:,1),:), 2), 2, 2)) / 2;
end
