function [med_mal, lat_mal] = bimal_calculator(bonestl_transformed, side_indx)
% BIMAL_CALCULATOR  Medial and lateral malleolus points from the tibia/fibula.
%
% [med_mal, lat_mal] = bimal_calculator(bonestl_transformed, side_indx)
%
% Uses the tibia and fibula meshes already in the shared bonestl_transformed
% frame (Z = superior/inferior, +X = medial). For each bone, the distal
% 30 mm is isolated and split into n regions along X, the same region-
% splitting approach used in CoordinateSystem.m. The medial malleolus is
% the average of the most-medial region on the tibia; the lateral
% malleolus is the average of the most-lateral region on the fibula.

n = 10;
distal_height = 30; % mm, distal region of interest

vis = 0; % set to 1 to plot the distal regions used for each malleolus

tib_pts = bonestl_transformed.Tibia.Points;
fib_pts = bonestl_transformed.Fibula.Points;

med_mal = distal_region_average(tib_pts, distal_height, n, 'medial', vis);
lat_mal = distal_region_average(fib_pts, distal_height, n, 'lateral', vis);

end

function av_point = distal_region_average(pts, distal_height, n, side, vis)
% Isolate the distal (lowest Z) region of the bone, split it into n
% regions along X, and average the points in the most medial/lateral one.

z_min = min(pts(:,3));
distal_pts = pts(pts(:,3) <= z_min + distal_height, :);

x_min = min(distal_pts(:,1));
x_max = max(distal_pts(:,1));
nth_x = (x_max - x_min) / n;

if strcmp(side, 'medial') % most positive X region
    roi = distal_pts(:,1) >= (x_max - nth_x);
else % 'lateral', most negative X region
    roi = distal_pts(:,1) <= (x_min + nth_x);
end

av_point = mean(distal_pts(roi,:), 1);

if vis
    figure()
    plot3(pts(:,1), pts(:,2), pts(:,3), 'k.')
    hold on
    plot3(distal_pts(roi,1), distal_pts(roi,2), distal_pts(roi,3), 'ys')
    plot3(av_point(1), av_point(2), av_point(3), 'r.', 'MarkerSize', 50)
    xlabel('X'); ylabel('Y'); zlabel('Z')
    axis equal
end

end
