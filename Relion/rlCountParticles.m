% rlCountParticles.m

inDir='Info_newa/';
outDir=inDir;
nParticles=0;

allNames=f2FindInfoFiles(inDir);
nNames=numel(allNames);
allMis=cell(nNames,1);
disp([num2str(nNames) ' mi files.']);
for i=1:nNames
    mi=ReadMiFile(allNames{i});
    allMis{i,1}=mi;
    miParts=size(mi.particle.picks,1);
    nParticles=nParticles+miParts;
    disp([num2str(i) '  ' allNames{i} '  ' num2str(miParts) '  ' num2str(nParticles)]);
end;
%%
save([outDir 'allNames.mat'],'allNames');
disp([outDir 'allNames.mat saved.']);
    save([outDir 'allMis.mat'],'allMis','allNames');
    disp([outDir 'allMis.mat saved.']);

