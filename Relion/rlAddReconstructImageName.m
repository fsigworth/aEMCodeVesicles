% rlAddReconstructImageName.m
% This program does one of two things. 1. It can add the
% rlReconstructImageName to a particle file to yield a particle+unsub.star
% file for final reconstruction with unsubtracted particles; 2. Or it can
% create a particles_unsub.star file that mirrors a subtracted particles
% file. This can be used for re-extracting unsub particles in parallel with
% the subtracted particles.
%
% For reference we read a pair of matching particles.star files, let's call
% them ref_u.star and ref_v.star. These are typically from a pair of
% Extract jobs. We depend on there being a line-for-line correspondence
% between the rlnImageNames in the two files. We then match filenames in
% the input file (which comes e.g. from selection or refinement) with those
% in the _v star file, and obtain all the _u names. The _u names are placed
% into the extra field rlnReconstructImageName in the output file (option
% 1) or used to replace the field rlnImageName into the output file (option
% 2). The modified input file is written out with "+unsub" or "_unsub"
% appended to the name. It is written to the same directory that the input
% file came from.

% particles.star name
% inStarName='Select/job023/particles.star';
% inStarName='RSC1_C24-4/particles_rso_all.star';
%inStarName='Refine3D/job263/run_data.star';

%inStarName='Refine3D/job034/run_data.star'; % Subtracted stack!
inStarName='Extract/job024/particles.star'; % Subtracted stack!
refVStarName='Extract/job024/particles.star';
refUStarName='Extract/job039/particles.star';

% Here we select the two options
insertReconstructImage=1; % Yes, do put in the field
makeUnsubStar=0; % Create a particle star with all unsub image names.

[pa, nm, ex]=fileparts(inStarName);
outStarName1=[pa filesep nm '+unsub' ex];
    outStarName1=[pa filesep nm '+unsub+0' ex]; %%% try extra
    insertExtraField=1;
outStarName2=[pa filesep nm '_unsub' ex];

% Get the pair of micrograph.star files. We assume that the unsub and
% subtracted micrograph names are on the same rows in the files.
if ~exist(inStarName,'file')
    disp(['The input file ' inStarName ' can''t be found.']);
    return
end;

disp(['Reading V reference: ' refVStarName]);
[nmv,datv]=ReadStarFile(refVStarName);
vImgNames=datv{2}.rlnImageName;

disp(['Reading U reference: ' refUStarName]);
[nmu,datu]=ReadStarFile(refUStarName);
uImgNames=datu{2}.rlnImageName;
uMicNames=datu{2}.rlnMicrographName;

nUNames=numel(uImgNames);
if numel(vImgNames)~=nUNames
    disp('Numbers of rows don''t match. Exiting.');
    return
end;

disp('Decoding refVStar names.')
[~,vFileNames]=rlDecodeImageName(vImgNames);
[vFileUniques,vFirst,vLookup]=unique(vFileNames);

disp('Decoding refUStar names.')
[~,uFileNames]=rlDecodeImageName(uImgNames);

% Get the input particle.star file.
disp(['Reading the input file: ' inStarName]);
[nmp,datp]=ReadStarFile(inStarName);
nparts=numel(datp{2}.rlnImageName);
dOut=datp{2}; % Copy the particle data.

disp(['Decoding ' num2str(nparts) ' particle names']);
[pSlices,inFileNames]=rlDecodeImageName(dOut.rlnImageName);
[pFileUniques,pFirsts,pLookup]=unique(inFileNames);

% match the particle filenames with refVStar
nu=numel(pFileUniques);

matchFileInds=zeros(nu,1);
for i=1:numel(pFileUniques)
    q=strcmp(pFileUniques{i},vFileUniques);
    ind=find(q);
    if numel(ind)>1
        disp(['Duplicated micrograph name? ' pFileUniques{i}]);
    elseif numel(ind)<1
        disp(['No matching micrograph name: ' pFileUniques{i}]);
        continue;
    end;
    matchFileInds(i)=ind;
end;

% for each pLookup, get matchFileInds(pLookup) which point into
% vFileUniques. vFirst(matchFileInds(pLookup)) points to the uFileName.

uNames=cell(nparts,1);
umNames=cell(nparts,1);
disp('Creating the new particle names');
for i=1:nparts
    newNameInd=vFirst(matchFileInds(pLookup(i)));
    newName=[num2str(pSlices(i),'%06d') '@' uFileNames{newNameInd}];
    uNames{i}=newName;
    umNames(i)=uMicNames(newNameInd); % pick up the micrograph name too.
end;

% if doSwap
% %%swap the fields
% temp=dOut.rlnReconstructImageName

% Insert the new field in case we want it
dOut.rlnReconstructImageName=uNames;
if insertExtraField
    dOut.vesExtra=zeros(nparts,1);
end;
dato=datp;

if insertReconstructImage
    disp(['Writing the output file ' outStarName1]);
    dato{2}=dOut;
    WriteStarFile(nmp,dato,outStarName1);
    disp('done.')
end;

if makeUnsubStar
    dOut=rmfield(dOut,'rlnReconstructImageName'); % don't want it after all.
    dOut.rlnImageName=uNames;
    dOut.rlnMicrographName=umNames;
    disp(['Writing the output file ' outStarName2]);
    dato{2}=dOut;
    WriteStarFile(nmp,dato,outStarName2);
    disp('done.')
    
end;




% Primitive old code.

% 
% 
% 
% inStarName='Select/job191/particles.star';
% outStarName='Select/job191/particles+unsub.star';
% 
% disp(['Reading ' inStarName]);
% imgNames=dat{2}.rlnImageName;
% 
% whos imgNames
% %%
% outNames=imgNames;
% nim=numel(imgNames);
% for i=1:nim
%     [partInd,micName]=rlDecodeImageName(imgNames{i});
%     [pa,nm,ex]=fileparts(micName);
%     nm(end)='u'; % swap the final character from 'v' to 'u'
%     name=imgNames{i};
%     if strndcmp(name(end-4:end),'.mrcs')
%         name(end-5)='u'; % mark unsubtracted
%         disp(name);
%         return
%     end;
% end;


% Simple old code...
%
% % rlAddReconstructImageName
% % add the column to a particles.star file
% 
% inStarName='Select/job191/particles.star';
% outStarName='Select/job191/particles+unsub.star';
% 
% disp(['Reading ' inStarName]);
% [nm,dat]=ReadStarFile(inStarName);
% imgNames=dat{2}.rlnImageName;
% 
% whos imgNames
% %%
% outNames=imgNames;
% nim=numel(imgNames);
% for i=1:nim
%     [partInd,micName]=rlDecodeImageName(imgNames{i});
%     [pa,nm,ex]=fileparts(micName);
%     nm(end)='u'; % swap the final character from 'v' to 'u'
%     name=imgNames{i};
%     if strndcmp(name(end-4:end),'.mrcs')
%         name(end-5)='u'; % mark unsubtracted
%         disp(name);
%         return
%     end;
% end;