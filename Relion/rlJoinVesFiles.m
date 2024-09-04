% rlJoinVesFiles.m
% Join particle_ves files together

% Load two particles.star files
% pStarName='Refine3D/job140/run_data.star';
pStarNames={'RSC2b/ves_particles2_v.star'
            'RSC_newb/ves_particles1_v.star'};
outName='RSC_newb/ves_particles1_ves_join.star';

numToJoin=numel(pStarNames);
theField='vesCenterX' % field for counting particles
ok=true;
disp('Input files:');
for i=1:numToJoin
    disp(pStarNames{i});
    if ~exist(pStarNames{i},'file')
        ok=false;
        disp([pStarNames{i} ' not found.']);
    end;
end;
if ~ok
    disp('Exiting.');
    return
end;

disp(' ');
[nm,da]=ReadStarFile(pStarNames{1});
disp([ pStarNames{1} ': ' num2str(numel(da{2}.(theField))) ' entries'])
disp(' ');
for i=2:numToJoin
    [nm2,da2]=ReadStarFile(pStarNames{i});
    disp([pStarNames{i} ': ' num2str(numel(da2{2}.(theField))) ' entries'])
    disp(' ');
    for j=1:numel(da)
        da{j}=StructsConcat(da{j},da2{j});
    end;
end;

disp([num2str(numel(da{2}.(theField))) ' entries total.']);
disp(['Writing ' outName]);
WriteStarFile(nm,da,outName);
