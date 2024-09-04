% rlMakeParticleSplit.m
% Given a micrographs_split file created in a Select job, select only the
% particles in a particles.star file that come from those micrographs, and
% write out a particles_split file.

inMicrographSplitName='Select/job085/micrographs_split100.star';
inParticleStarName='Refine3D/job075/run_data_unsub.star';
outParticleSplitName='Select/job085/particles_split100.star';

disp(['Reading micrographs: ' inMicrographSplitName]);
[nmm,datm]=ReadStarFile(inMicrographSplitName);

micNames=datm{2}.rlnMicrographName;
nMics=numel(micNames);
disp([num2str(nMics) ' micrographs.']);

disp(['Reading particles: ' inParticleStarName]);
[nmp,datp]=ReadStarFile(inParticleStarName);

pMicNames=datp{2}.rlnMicrographName;
nParts=numel(pMicNames);
disp([num2str(nParts) ' particles in the input stack']);
disp('Comparing micrograph names.')
activeParticles=false(nParts,1);
for i=1:nMics
    activeParticles=activeParticles | strcmp(micNames{i},pMicNames);
end;

numActive=sum(activeParticles);
disp([num2str(numActive) ' matched particles.']);

if numActive>0
    active=cell(2,1);
    active{1}=[];
    active{2}=activeParticles;
    disp(' ');
    disp(['Writing ' outParticleSplitame]);
 headerText='\n# version 30001\n';
WriteStarFile(nmp,datp,outParticleSplitName,headerText,active);
end;
disp('done.');

