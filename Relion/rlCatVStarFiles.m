% rlCatVStarFiles.m
% concatenate the particle data (but not optics) from multiple star files

% Input vesicle-particle files
vStarNames{1}='RSC2/ves_particles1_v.star';
vStarNames{2}='RSC_new/ves_particles1_v.star';

vStarOutName='RSC_new/ves_particles1_joined_v.star';
ok=1;
for i=1:numel(vStarNames)
    disp(VStarNames{i});
    if ~exist(vStarNames{i},'file')
    disp(['  ' vStarName ' doesn''t exist.']);
    ok=0;
    end;
end;
if ~ok
    return
end;

[nm1,da1]=ReadStarFile(vStarNames{1});
for i=2:numel(vStarNames)
    [nm2,da2]=ReadStarFile(vStarNames{i});
    da1{2}=StructsConcat(da1{2},da2{2});
end;
%%
    disp(['Writing ' vStarOutName]);
    fStar=fopen(vStarOutName,'wt');
    fprintf(fStar,'\n# version 30001\n');
    WriteStarFileStruct(da1{1},'optics',fStar);
    WriteStarFileStruct(da1{2},'particles',fStar);
    fclose(fStar);
