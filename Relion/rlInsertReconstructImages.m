% rlInsertReconstructImages.m
% Add the rlnReconstructImageName column to a subtracted particles star file.

% A typical line contains rlnImageName
%  000001@Refine3D/job217/Merged/001_X-1Y-1-2_v.mrcs 
% and the rlnReconstructImageName will be something like
%  000001@Extract/job220/A-24/001_X-1Y-1-2.mrcs 
% so we have to copy the image index, replace the path and the final character of the name.

newPath='Extract/job011/A16-2/'; % Where to find the _u particles.
newSuffix='';
oldSuffix='_v';
nSuffChars=numel(oldSuffix);

% particleStarName='Extract/job281/particles.star'
% particleStarName='Refine3D/job026/run_data.star';
particleStarName='Refine3D/job023/run_data.star';
outStarName='Refine3D/job023/run_VplusU_data.star'; % Often back in the same directory

disp(['Reading ' particleStarName]);
[pnms,pdats]=ReadStarFile(particleStarName);

%%
pdt=pdats{2};
np=numel(pdt.rlnImageName);
qdt=pdt;
qdt.rlnReconstructImageName=cell(np,1);
disp('Examples: Old image name ... Unsub image name')
for i=1:np
    oldImgName=pdt.rlnImageName{i};
    atPtr=strfind(oldImgName,'@');
    [oldPath oldStack ext]=fileparts(oldImgName(atPtr+1:end));
    newStackName=[newPath oldStack(1:end-nSuffChars) newSuffix ext];
    qdt.rlnReconstructImageName{i}=[oldImgName(1:atPtr) newStackName];
    if i<6 % print out the first few
        disp([oldImgName '  ' qdt.rlnReconstructImageName{i}]);
    end;
end;

%%
qdats=[pdats(1); qdt];
disp(['Writing ' outStarName '...']);
WriteStarFile(pnms,qdats,outStarName);
disp('done.');