function overlap = ncoverlap_calculator(A, B, C, bonestl_transformed, side_indx)

ab = [A(:,2:3); A(:,2), B(:,3)];
AB = pdist(ab,'euclidean');

ac = [A(:,2:3); A(:,2),C(:,3)];
AC = pdist(ac,'euclidean');

overlap = AC/AB * 100;

if C(:,3) > A(:,3)
    overlap = -overlap;
end


figure('Color','w'); hold on
p1 = patch('Faces',bonestl_transformed.Navicular.ConnectivityList,'Vertices',bonestl_transformed.Navicular.Points,...
    'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
alpha(p1,0.5)
p2 = patch('Faces',bonestl_transformed.Cuboid.ConnectivityList,'Vertices',bonestl_transformed.Cuboid.Points,...
    'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
alpha(p2,0.5)

plot3(zeros(2,1),ab(:,1),ab(:,2),'-r','LineWidth',2)
plot3(zeros(2,1),ac(:,1),ac(:,2),'-b','LineWidth',4)

viewv = [-90 0]*(side_indx==1) + [90 0]*(side_indx==2);
view(viewv);
camlight HEADLIGHT; material dull
axis equal off
xlabel('x'); ylabel('y'); zlabel('z'); set(gca,'XTick',[],'YTick',[],'ZTick',[])
ttl = "Overlap Ratio = " + sprintf('%.2f',overlap);
title(ttl, 'Interpreter','none')