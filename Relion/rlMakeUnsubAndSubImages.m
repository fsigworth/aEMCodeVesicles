% rlMakeUnsubAndSubParticleStarFiles.m
% Prepare to use the unsub image for further reconstruction, for example.
% Creates three output files, each having the new fields
% rscUnsubImageName and rscSubImage name. The files are
%   name+unsub.star (has the rlnReconstructImage field = unsub image
% The other two lack the rlnReconstructImage field:
%   name_unsub.star (rlnImageName is copied from rscUnsubName)
%   name_sub.star   (rlnImageName is copied from rscSubName)
% First, check that rlnSubImageName doesn't exist.
% then
% Move the rlnImageName to rlnSubImageName
% Move the rlnReconstructImageName to rlnImageName

inStarName='Refine3D/job098/run_data.star';
[pa, nm, ex]=fileparts(inStarName);
outStarName0=[pa filesep nm '+unsub' ex];
outStarName1=[pa filesep nm '_unsub' ex];
outStarName2=[pa filesep nm '_sub' ex];

% Get the input particle.star file.
disp(['Reading the input file: ' inStarName]);
[nmp,datp]=ReadStarFile(inStarName);
nparts=numel(datp{2}.rlnImageName);
dOut0=datp{2}; % Copy the particle data.

names=fieldnames(dOut0);
if ~any(strcmp(names,'rlnReconstructImageName'))
    disp(['no rlnReconstructImageName found in ' inStarName '.'])
    disp('Quitting.');
    return
end;

if any(strcmp(names,'rscSubImageName'))
    disp('rscSubImageName field already exists.');
else
    dOut0.rscSubImageName=dOut0.rlnImageName;
end;

dOut0.rscUnsubImageName=dOut0.rlnReconstructImageName;

dOut1=rmfield(dOut0,'rlnReconstructImageName');

dOut1.rlnImageName=dOut1.rscUnsubImageName;

dOut2=dOut1;
dOut2.rlnImageName=dOut2.rscSubImageName;

disp(['Writing ' outStarName0]);
    datp{2}=dOut0;
    WriteStarFile(nmp,datp,outStarName0);
disp(['Writing ' outStarName1]);
    datp{2}=dOut1;
    WriteStarFile(nmp,datp,outStarName1);
disp(['Writing ' outStarName2]);
    datp{2}=dOut2;
    WriteStarFile(nmp,datp,outStarName2);
disp('done.');

