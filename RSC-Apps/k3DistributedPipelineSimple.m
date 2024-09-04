% k3DistributedPipelineSimple.m
% Run the processing pipeline for K2 or K3 movies.
% Simplified version does vesicle finding, refinement and picking
% preprocessor.

% NOTE this version is NOT called by any scripts yet. k3pRung or another
% one has to be modified to call ths instead of k3DistributedPipeline
% itself. Once set up the call would be:
%  sbatch --array=1-50 k3pRung (general)
%  or using k3pRuns (sigworth) or k3pRunv (scavenge)
%

doFindVesicles        =1;
doPrelimInverseFilter =0;
doRefineVesicles      =0;
doInverseFilter       =0;
doPickingPreprocessor =0;
doPicking             =0;

dontRedo=0; %%% don't overwrite Vesicle finding, refinement etc.

% Directories must be set up
workingDir='/gpfs/gibbs/pi/tomography/sigworth/20230524/';
cd(workingDir);

 infoDir='Info/';

pars=struct;
pars.loadFilenames=1; % pick up allNames.mat in base directory
pars.filenameFile='allNames.mat'; % in the working directory

% for picking preprocessor
pars.mapMode='Kv';

% ---for rsRefineVesicleFits----
rpars=struct;
%  rpars.doPreSubtraction=1;  % rsRefineVesicleFits: pre-subtract old vesicle fit.
%  rpars.rTerms=[100 150 200 300  inf];
%  rpars.rTerms=[90 100 120 150 200 250 300 inf];
rpars.peakPositionA=[];
% rpars.dsSmall=4; % downsampling of 'small' merged image
rpars.skipFitting=0;
rpars.writeSubMRC=1;
rpars.writeSmallMRC=0;
rpars.writeSmallSubMRC=1;

% Figure out who we are
host=getenv('HOSTNAME');
disp(['host: ' host]);
bEnv=getenv('BATCH_ENVIRONMENT');
disp(['environment: ' bEnv]);
isInteractive=~( strcmp(bEnv,'BATCH'));
disp(['isInteractive = ' num2str(isInteractive)]);
pars.showGraphics=isInteractive;  % show graphics anyway if simulating.


if isInteractive
    disp('Batch simulation:');
    numJobs=MyInput('numJobs',1);
    jobIndex=MyInput('jobIndex',1);

else

    numJobs=str2double(getenv('NUM_JOBS'));
    disp(['numJobs: ' num2str(numJobs)]);
    jobIndex=str2double(getenv('JOB_ID')) % one-based index
    disp(['jobIndex: ' num2str(jobIndex)]);
end;

    if isnan(numJobs)
        disp('Undefined number of jobs. Exiting');
        return
    end;
    if isnan(jobIndex)
        disp('Undefined job index. Exiting');
        return;
    end;

numJobs
jobIndex

% Get the mi file names

if pars.loadFilenames
    disp('loading filenames');
    if exist('allNames.mat','file')
        load allNames.mat
    else
    disp('allNames.mat not found. Finding the mi files');
    allNames=f2FindInfoFiles(infoDir);
    end;
else
    disp('Finding the mi files');
    allNames=f2FindInfoFiles(infoDir);
end;

nNames=numel(allNames);

if nNames<1
    msg=['No mi files found in ' pwd filesep infoDir];
    disp(msg);
    error(msg);
end;

% Figure out what we will do
blockSize=nNames/numJobs;
ourBlockStart=round(jobIndex-1)*blockSize+1;
ourBlockEnd=min(nNames,round(jobIndex*blockSize));
fprintf('Working on files %d to %d\n',ourBlockStart,ourBlockEnd);

ourNames=allNames(ourBlockStart:ourBlockEnd);

numNames=numel(ourNames);
if numNames<1  % nothing to do
    error(['No mi files found: ' pwd]);
end;


logSeqs=zeros(numNames,8);
nParticles=zeros(numNames,1);
if dontRedo
    disp('Checking mi logs')
    for i=1:numNames
        mi=ReadMiFile(ourNames{i});
        logSeqs(i,:)=miDecodeLog(mi);
        nParticles(i)=numel(mi.particle.picks);
    end;
end;

    % inverse filter (sequence 6)
    if doPrelimInverseFilter
        active=logSeqs(:,6)==0;
        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for vesicle finding.'])
        if any(active)
        fpars=struct;
        fpars.useUnsubImage=1;
            meInverseFilterAuto(activeNames,fpars);
        end;
    end;

    if doFindVesicles
        active=logSeqs(:,4)==0;
        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for vesicle finding.'])
        if any(active)
            Vesicle_finding_GUI(activeNames);
        end; 
     end;

        % refine vesicles (sequence 5)
    if doRefineVesicles
        active=logSeqs(:,5)==0;
        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for vesicle refinement.'])
        if any(active)
            rsRefineVesicleFitsA(activeNames,rpars);
        end;
    end;
            % inverse filter (sequence 6)
    if doInverseFilter 
        active=logSeqs(:,6)==0;
        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for vesicle finding.'])
        if any(active)
            meInverseFilterAuto(activeNames);
        end;
    end;

    % picking preprocessor (sequence 8)
    if doPickingPreprocessor
        active=logSeqs(:,8)==0;
        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for preprocessor.'])
        if any(active)
            rsPickingPreprocessor4(activeNames,pars);
        end;
    end;
    
    if doPicking
        ready=logSeqs(:,8)~=0;
        unpicked=nParticles==0;
        active = ready & (unpicked | ~ dontRedo);
        activeNames=ourNames(active);
                    disp([num2str(sum(active)) ' micrographs to pick.'])
        if any(active)
            BatchRSPicker(ourNames);
        else
            disp('No preprocessed images available.')
        end
    end;
    