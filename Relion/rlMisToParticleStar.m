% rlMisToParticleStar.m
% Given a set of mi files and a micrographs_ctf.star file,
% Create micrographs_ctf.star files and (if desired)
% create two particles.star files that can be used by
% Relion's particle extraction jobs. One is for unsubtracted and one is for
% subtracted particles. These files contain CTF parameters translated
% back from the mi files.
% They can contain an added parameter from our autopicking,
% rsAutopickNoiseVar.
% They potentially contain two added fields, vesRadius and
% vesPsi.
%
% For unsubtracted particles we can use the raw micrograph [default]
% or else a copy (possibly scaled) as Merged/*_u.mrc.
%
% Subtracted particles are either gotten from the padded, scaled micrograph
% Merged/*mv.mrc or [current selection] from the unpadded micrograph Merged/*_v.mrc.
%
% The created micrographs_ctf_sub.star file points to the subtracted
% micrographs, and if desired a micrographs_ctf_unsub.star file that points to 
% either the original micrographs_ctf.star [current selection] or to our
% unsubtracted micrographs in the Merged/ folder.
%
% We can also write a vesicle star file which contains particle and vesicle
% coordinates, for predicting psi angles from geometry.
%
% Now constraining groups to have common optics groups fs 12 Aug 23

% full path to working directory
%cd('/gpfs/gibbs/pi/sigworth/20240216/')
%cd('/gpfs/gibbs/pi/sigworth/20240321BNL/')
cd('/gpfs/gibbs/pi/tomography/sigworth/SYP')

boxSize=256; % Not critical, just written in optics groups.
doWriteMicrographStars=1;
doWriteParticleStars=0;
doWriteVesicleStars=0;

% ----Our picking data----
suffix=''; % Added to each directory name

infoDir=AddSlash(['Info' suffix])

forceLoadMiFiles=0; % Load each mi file individually instead of loading allMis.mat

% ----Input Micrograph star file
% inMicStarName='CtfFind/job002/micrographs_ctf.star'; % Existing file
%inMicStarName='JoinStar/job017/join_mics.star';
inMicStarName='CtfFind/job002/micrographs_ctf.star'; % Existing file


if ~exist(inMicStarName,'file')
    disp(['the micrographs star file ' inMicStarName ' was''nt found. Exiting.']);
    return
end;

% ---Where to find micrographs. Special cases:
useMergedUnsubMicrograph=0; % Look for Merged/_u.mrc for unsub micrographs.
% We'll also write the new micrographs_ctf_unsub.star file.
usePaddedSubMicrograph=0; % Look for Merged/*mv.mrc for padded micrographs.
% Otherwise, look for Merged/*_v.mrc files.

% ----Output micrograph star files
% doWriteMicrographStars=1;
outStarDir=AddSlash(['RSC' suffix]);
if CheckAndMakeDir(outStarDir,1)
    disp(['Output directory ' outStarDir ' exists']);
end;

outMicrographStarBasename=['micrograph_ctf' suffix];
writeMicrographStarU=doWriteMicrographStars;
writeMicrographStarV=doWriteMicrographStars;

%  ---Output particle files---
%       We put special fields into particle.star files:
% doWriteParticleStars=1;
writeVesiclePsi=1;
writeAutopickNoiseVar=1; % include these fields in the particle star files.

outParticleStarBasename=['particles' suffix];
writeParticleStarU=doWriteParticleStars;
writeParticleStarV=doWriteParticleStars;

%   If desired, we write a special subtracted file with vesicle coordinates and particle angles too.
% doWriteVesicleStars=1;
outVesicleStarNameV=['ves_' outParticleStarBasename '_v.star'];
writeVesicleStar=doWriteVesicleStars;
writeVesicleMat=doWriteVesicleStars;

% Or write a subtracted file with 6 extra fields regarding vesicles
writeExtendedVesicleStar=0;

% group strategies
useGroupsFromMi=0; % Read the assigned group no. from mi.ok(20)
% OR ELSE just use an incrementing index of micrographs, with
minGroupParts=200; % minimun number of particles in a group
maxNMicrographs=inf; % limit the number of micrographs to consider

setParticlesActive=1; % ignore particle.picks(:,10) flag.
setMisActive=1; % ignore mi.active field.

checkForMicrographs=1; % Skip micrographs where the .mrc image is missing.

if useMergedUnsubMicrograph
    unsubMicrographSuffix='_u.mrc';
end;

if usePaddedSubMicrograph
    disp('usePaddedSubMicrograph is a feature not yet implemented. Exiting.');
    return
else
    subMicrographSuffix='_v.mrc'; % for image made in micrograph coordinates, instead of 'mv.mrc'
end;

disp(['Reading ' inMicStarName]);
[mcNames,mcDat]=ReadStarFile(inMicStarName);
% mcNames
opt=mcDat{1};
mic=mcDat{2};
%
nMics=numel(mic.rlnMicrographName);
if maxNMicrographs<nMics
    mic=TrimStructFields(mic,1,maxNMicrographs); %%%%%%%
    nMics=maxNMicrographs;
end;
disp([num2str(nMics) ' micrographs in star file.']);
disp(' ');

%inMicPath=fileparts(mic.rlnMicrographName{1}); % pick up the path from the first one.

uMicNames=cell(nMics,1);
vMicNames=cell(nMics,1);
% %


% Does an allMis.mat file already exist in the infoDir?
allMisFilename=[AddSlash(infoDir) 'allMis.mat'];

if forceLoadMiFiles || ~exist(allMisFilename,'file')
    allMiNames=f2FindInfoFiles(infoDir);
    nmi=numel(allMiNames);
    allMis=cell(0,1);
    disp(['Reading files in ' infoDir]);
    tic
    for micInd=1:nmi
        allMis{micInd,1}=ReadMiFile(allMiNames{micInd});
        if mod(micInd,500)==0
            disp(micInd);
        end;
    end;
    toc
    disp(['Writing ' allMisFilename]);
    save(allMisFilename,'allMis');
    % We'll have to add the '-v7.3' option if allMis is >2GB in size
else
    disp(['Loading mi files from ' allMisFilename]);
    load(allMisFilename);
    nmi=numel(allMis);
end;
disp(' ');
%
% ni=nMics; %%%%%%%
%%
pts=struct;
partSubMicName=cell(1,1);
partUnsubMicName=cell(1,1);

ves=struct; % structure for the vesicle info
outOpt=opt; % copy the optics from the micrograph.star
nOpt=numel(outOpt.rlnOpticsGroup);
    outOpt.rlnImageSize=boxSize*ones(nOpt,1);
    outOpt.rlnImageDimensionality=2*ones(nOpt,1);
maxOpt=max(outOpt.rlnOpticsGroup);

boxSize=256; % nominal starting size
FlagRange=[16 32]; % flags for valid particles

% for assigning group numbers
globalGroupIndex=1; % if we're not reading from mi.ok
groupIndex=zeros(maxOpt,1);  % label of this group
groupParts=zeros(maxOpt,1); % number of particles in the group

nTotal=0; % particle counter
pSkip=0; % counter of micrographs with no particles
zSkip=0; % counter of micrographs with group=0
nSkip=0; % total micrographs skipped.
miSkip=0; % no. mi files skipped.

disp('Accumulating the structures:')
disp(' star line    micrograph    single, total particles.');
micInd=0; % output micrograph star file line
newMic=cell(0,1);
for ind=1:nmi
    mi=allMis{ind};
    %         Get the micrograph names
    if ~isfield(mi,'imagePath')
        disp(['bad mi: ' num2str(micInd)]);
        continue;
    end;
    micInd=micInd+1; % We'll make an entry into the output mic files.

    % Match the name to find the line in the input file
    fullImageName=[mi.imagePath mi.imageFilenames{1}];
    match=strcmp(fullImageName,mic.rlnMicrographName);
    micStarLine=find(match);
    if numel(micStarLine)<1
        disp(['Image name couldn''t be matched. mi: ' fullImageName ' typical Star name: ' mic.rlnMicrographName{micInd}]);
        nSkip=nSkip+1;
        continue
    elseif numel(micStarLine)>1
        disp(['?duplicate micrograph names in star file? ' fullImageName]);
    end;
    micStarLine=micStarLine(1); % This is the index into the micrographs.star file.
    % Pick up parameters from the mic star file.
    opticsGroup=mic.rlnOpticsGroup(micStarLine);
    ctfMaxRes=mic.rlnCtfMaxResolution(micStarLine);
    ctfFOM=mic.rlnCtfFigureOfMerit(micStarLine);

    % copy the entire line from the original mic structure.
    newMic=structCopyFields(mic,micStarLine,newMic,micInd);

    if useMergedUnsubMicrograph
        newUnsubMicName=[mi.procPath mi.baseFilename '_u.mrc'];
    else
        newUnsubMicName=[mi.imagePath mi.imageFilenames{1}];
    end;
    if usePaddedSubMicrograph
        disp('Not yet implemented, using padded sub micrographs.');
        return
    else
        newSubMicName=[mi.procPath mi.baseFilename '_v.mrc'];
    end;
    vMicNames{micInd}=newSubMicName; % replace the micrograph name.
    uMicNames{micInd}=newUnsubMicName;

    %         % We might have new files missing.
    %
    %     [oldMicPath, oldMicBasename]=fileparts(mic.rlnMicrographName{j});
    %     nmLength=numel(oldMicBasename);
    %     [~,newVMicBasename]=fileparts(newSubMicName);
    %     [~,newUMicBasename]=fileparts(newUnsubMicName);
    %     if ~strncmp(oldMicBasename,newVMicBasename,nmLength) ...
    %           || ~strncmp(newUMicBasename,newVMicBasename,nmLength)% should match up to the end
    %       disp(['Discrepancy: ' oldMicBasename '  ' newVMicBasename '  ' newUMicBasename]);
    %       return
    %     end;
    % Store the new micrograph names, which we'll put in later.

    if ~doWriteParticleStars && ~doWriteVesicleStars % skip all the particle code.
        continue;
    end;

    if useGroupsFromMi
        thisGroupIndex=mi.ok(20); % a zero groupIndex means a bad micrograph
        if thisGroupIndex==0
            nSkip=nSkip+1;
            continue;
        end;
    end;

    % Now starts code that is conditional on particle number.
    if isfield(mi.particle,'picks') && numel(mi.particle.picks)>0
        % ----- Accumulate the particle star data -----
        if size(mi.particle.picks,2)<10 || setParticlesActive % don't have the flag field
            flags=mi.particle.picks(:,3);
            mi.particle.picks(:,10)=(flags>=FlagRange(1)) & (flags <=FlagRange(2)); % all valid particles are active
        end;
        if setMisActive
            mi.active=true;
        end;
        active=(mi.particle.picks(:,10)>0) & mi.active;
        % ignore all particles when mi is not active.
        nParts=sum(active);

        if nParts<1
            pSkip=pSkip+1;
            nSkip=nSkip+1;
            continue;
        end;

        xs=mi.particle.picks(active,1);
        ys=mi.particle.picks(active,2);
        amps=mi.particle.picks(active,5);
        spects=mi.particle.picks(active,8);

        if mod(micInd,1000)==0
            disp(sprintf('%7d  %s %4d %8d',micInd,mi.baseFilename,nParts,nParts+nTotal));
        end;
        if checkForMicrographs
            if ~exist(newUnsubMicName,'file')
                disp([newUnsubMicName ' not found.']);
            end;
            if ~exist(newSubMicName,'file')
                disp([newSubMicName ' not found.']);
            end;
        end;


        %     Accumulate the particles star
        istart=nTotal+1;
        iend=nTotal+nParts;
        pts.rlnCoordinateX(istart:iend,1)=xs;
        pts.rlnCoordinateY(istart:iend,1)=ys;
        pts.rlnClassNumber(istart:iend,1)=1;
        pts.rlnAutopickFigureOfMerit(istart:iend,1)=amps;
        % %
        pts.rlnAnglePsi(istart:iend,1)=-999; % We could assign these...
        pts.rlnOpticsGroup(istart:iend,1)=opticsGroup;
        % no image name, just micrograph name...
        partUnsubMicName(istart:iend,1)={newUnsubMicName}; % The only fields that differ.
        partSubMicName(istart:iend,1)={newSubMicName};
        %
        if ~useGroupsFromMi  % --assigning groups--
            % we keep optics groups together.
            if groupParts(opticsGroup)==0 % starting a new group
                groupIndex(opticsGroup)=globalGroupIndex;
                globalGroupIndex=globalGroupIndex+1;
            end;

            groupParts(opticsGroup)=groupParts(opticsGroup)+nParts;
            thisGroupIndex=groupIndex(opticsGroup);

            if groupParts(opticsGroup)>=minGroupParts % We have enough particles
                groupParts(opticsGroup)=0; % Next time we'll use another group number
                groupIndex(opticsGroup)=globalGroupIndex;
                globalGroupIndex=globalGroupIndex+1;
            end;
        end;

        pts.rlnGroupName(istart:iend,1)={['group_' num2str(thisGroupIndex)]};

        % For reference, this is how we got the mi.ctf parameters from the original star files:
        % mi.ctf.defocus=(mic.rlnDefocusU(iLine)+mic.rlnDefocusV(iLine))/2e4;
        % mi.ctf.deltadef=(mic.rlnDefocusU(iLine)-mic.rlnDefocusV(iLine))/2e4;
        % mi.ctf.theta=mic.rlnDefocusAngle(iLine)*pi/180;
        %         pts.rlnAstigmatism(istart:iend,1)=-mi.ctf.deltadef*1e4;

        pts.rlnDefocusU(istart:iend,1)=(mi.ctf.defocus+mi.ctf.deltadef)*1e4;
        pts.rlnDefocusV(istart:iend,1)=(mi.ctf.defocus-mi.ctf.deltadef)*1e4;
        % not assigned: CtfBfactor, CtfMaxResolution, CtffigureOfMerit
        pts.rlnDefocusAngle(istart:iend,1)=mi.ctf.theta*180/pi;%         pts.rlnOpticsGroup(istart:iend,1)=mi.opticsGroup;
        pts.rlnCtfScalefactor(istart:iend,1)=1;
        pts.rlnPhaseShift(istart:iend,1)=0;
        pts.rlnCtfMaxResolution(istart:iend,1)=ctfMaxRes;
        pts.rlnCtfFigureOfMerit(istart:iend,1)=ctfFOM;
        % ----- Accumulate the vesicle star -----
        rsos=mi.particle.picks(active,7); % rso flags
        vInds=mi.particle.picks(active,4); %vesicle indices
        % handle particles with no vesicle index
        vesOk=vInds>0;
        if any(~vesOk)
            disp(['Bad vesicle in image ' num2str(micInd) '  ' mi.baseFilename])
        end;
        vIndsOk=vInds(vesOk);
        vxs=zeros(nParts,1,'single');
        vxs(vesOk)=mi.vesicle.x(vIndsOk);
        vys=zeros(nParts,1,'single');
        vys(vesOk)=mi.vesicle.y(vIndsOk);
        vrs=zeros(nParts,1,'single');
        vrs(vesOk)=real(mi.vesicle.r(vIndsOk,1));
        vpsis=atan2d(ys-vys,xs-vxs);
        %         ves.vesMicrographName(istart:iend,1)={micName};
        ves.vesCenterX(istart:iend,1)=vxs;
        ves.vesCenterY(istart:iend,1)=vys;
        ves.vesR(istart:iend,1)=vrs;
        ves.vesPsi(istart:iend,1)=vpsis;
        ves.vesRsos(istart:iend,1)=rsos;
        ves.vesInds(istart:iend,1)=vInds;
        ves.ptlX(istart:iend,1)=xs;
        ves.ptlY(istart:iend,1)=ys;

        % If desired we add these extra fields to the particle struct
        if writeVesiclePsi
            pts.rsVesiclePsi(istart:iend,1)=vpsis;
        end;
        if writeAutopickNoiseVar
            pts.rspAutopickNoiseVar(istart:iend,1)=spects;
        end;
        % %


        nTotal=iend;
    else
        nSkip=nSkip+1;
    end; % if particles

end; % for loop over micrograph mi files

disp([num2str(nTotal) ' particles.']);

sdisp([num2str(nSkip) ' micrographs with no particles, of ' num2str(nmi)]);
disp(['Micrographs skipped with unassigned group: ' num2str(zSkip)]);
disp(['Micrographs skipped with group but no particles: ' num2str(pSkip)]);

% if ~useGroupsFromMi
%     % Make sure the last group has enough particles
%     if groupParts<=minGroupParts && groupIndex>1
%         groupNameCell=pts.rlnGroupName(groupLastParticle);
%         pts.rlnGroupName(groupLastParticle+1:end)=groupNameCell;
%     end;
% end;

% Insert the filenames into the output micrograph structs
uMics=newMic;
uMics.rlnMicrographName=uMicNames(1:micInd);
vMics=newMic;
vMics.rlnMicrographName=vMicNames(1:micInd);

% --Prepare the particles.star structure
% Fill in the constant fields
% pts.rlnClassNumber(1:nTotal,1)=1;
% pts.rlnAnglePsi(1:nTotal,1)=-999; % Alas!! this field causes Extract to hang.

uPts=pts;
uPts.rlnMicrographName=partUnsubMicName;
vPts=pts;
vPts.rlnMicrographName=partSubMicName;
ves.vesMicrographName=partSubMicName;

if writeExtendedVesicleStar
    extVes=vPts;
    %     extVes.vesCenterX=ves
    extVes.vesCenterX=ves.vesCenterX;
    extVes.vesCenterY=ves.vesCenterY;
    extVes.vesR=ves.vesR;
    extVes.vesPsi=ves.vesPsi;
    extVes.vesRsos=ves.vesRsos;
    extVes.vesInds=ves.vesInds;
end;

%%
% Write the micrograph star files
if writeMicrographStarU
    % ----Write the sub micrographs star file----
    fullStarName=[outStarDir outMicrographStarBasename '_u.star'];
    disp(['Writing ' fullStarName]);
    fStar=fopen(fullStarName,'wt');
    fprintf(fStar,'\n# version 30001\n');
    % We just use the optics block from the input micrograph star file.
    WriteStarFileStruct(opt,'optics',fStar);
    WriteStarFileStruct(uMics,'micrographs',fStar);
    fprintf(fStar,'\n');
    fclose(fStar);
end;

if writeMicrographStarV
    % ----Write the sub micrographs star file----
    fullStarName=[outStarDir outMicrographStarBasename '_v.star'];
    disp(['Writing ' fullStarName]);
    fStar=fopen(fullStarName,'wt');
    fprintf(fStar,'\n# version 30001\n');
    WriteStarFileStruct(opt,'optics',fStar);
    WriteStarFileStruct(vMics,'micrographs',fStar);
    fprintf(fStar,'\n'); % somehow, prevent a partial last line.
    fclose(fStar);
end;

% Write the particles star files
if writeParticleStarU
    outName=[outStarDir outParticleStarBasename '_u.star'];
    disp(['Writing ' outName]);
    fStar=fopen(outName,'wt');
    fprintf(fStar,'\n# version 30001\n');
    WriteStarFileStruct(outOpt,'optics',fStar);
    WriteStarFileStruct(uPts,'particles',fStar);
    fclose(fStar);
end;
%
if writeParticleStarV
    outName=[outStarDir outParticleStarBasename '_v.star'];
    disp(['Writing ' outName]);
    fStar=fopen(outName,'wt');
    fprintf(fStar,'\n# version 30001\n');
    WriteStarFileStruct(outOpt,'optics',fStar);
    WriteStarFileStruct(vPts,'particles',fStar);
    fclose(fStar);
end;

% % --these are no longer used--
% % Write the vesicle star files
% if writeVesicleStar
%     outName=[outStarDir outVesicleStarNameV];
%     disp(['Writing ' outName]);
%     fStar=fopen(outName,'wt');
%     fprintf(fStar,'\n# version 30001\n');
%     WriteStarFileStruct(outOpt,'optics',fStar);
%     WriteStarFileStruct(ves,'vesicles',fStar);
%     fclose(fStar);
% end;
%
% % Write the extended vesicle star file
% if writeExtendedVesicleStar
%     outName=[outStarDir 'ext' outVesicleStarNameV];
%     disp(['Writing ' outName]);
%     fStar=fopen(outName,'wt');
%     fprintf(fStar,'\n# version 30001\n');
%     WriteStarFileStruct(outOpt,'optics',fStar);
%     WriteStarFileStruct(extVes,'vesicles',fStar);
%     fclose(fStar);
% end;
%
% if writeVesicleMat
%     [~,vnm]=fileparts(outVesicleStarNameV);
%     outName=[outStarDir vnm '.mat'];
%     disp(['Writing ' outName '...']);
%     save(outName,'ves');
%     disp(' ');
% end;

disp('Done.');

