function ratio = mlcr_calculator(A, B, C, D, bonestl_transformed, side_indx)

ab = [A(:,2:3); B(:,2:3)];
AB = pdist(ab,'euclidean');

cd = [C(:,2:3); D(:,2:3)];
CD = pdist(cd,'euclidean');

ratio = AB/CD;

figure('Color','w'); hold on
p1 = patch('Faces',bonestl_transformed.Talus.ConnectivityList,'Vertices',bonestl_transformed.Talus.Points,...
    'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
alpha(p1,0.5)
p2 = patch('Faces',bonestl_transformed.Calcaneus.ConnectivityList,'Vertices',bonestl_transformed.Calcaneus.Points,...
    'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
alpha(p2,0.5)
p3 = patch('Faces',bonestl_transformed.Metatarsal1.ConnectivityList,'Vertices',bonestl_transformed.Metatarsal1.Points,...
    'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
alpha(p3,0.5)
p4 = patch('Faces',bonestl_transformed.Metatarsal5.ConnectivityList,'Vertices',bonestl_transformed.Metatarsal5.Points,...
    'FaceColor',[0.85 0.85 0.85], 'EdgeColor','none','FaceLighting','gouraud','AmbientStrength',0.15);
alpha(p4,0.5)

plot3(zeros(2,1),ab(:,1),ab(:,2),'-r','LineWidth',2)
plot3(zeros(2,1),cd(:,1),cd(:,2),'-b','Linewidth',2)

viewv = [-90 0]*(side_indx==1) + [90 0]*(side_indx==2);
view(viewv);
camlight HEADLIGHT; material dull
axis equal off
xlabel('x'); ylabel('y'); zlabel('z'); set(gca,'XTick',[],'YTick',[],'ZTick',[])
ttl = "Ratio = " + sprintf('%.2f',ratio);
title(ttl, 'Interpreter','none')