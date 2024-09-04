% k3DistributedPipeline.m
% Run the processing pipeline for K2 or K3 movies.
% Simplified version does vesicle finding, refinement and picking
% preprocessor.

% Run this with
%  sbatch --array=1-50 k3pRung (general)
%  or using k3pRuns (sigworth) or k3pRunv (scavenge)
%

% execute 1/nRuns of the entire dataset
runIndex=1;
nRuns=1;

doFindVesicles        =1;
doPrelimInverseFilter =0;
doRefineVesicles      =1;
doInverseFilter       =0;
doPickingPreprocessor =0;
doPicking             =0;
updateAllMis          =0;

skipAlreadyDone=0; % If true, don't overwrite Vesicle finding, refinement etc.

jobStart=1;

jobEnd=inf;

% Directories must be set up
%workingDir='/gpfs/gibbs/pi/sigworth/20240703/';
cd(workingDir);

 infoDir='Info/';
 logDir='Log/';

pars=struct;
pars.loadFilenames=1; % pick up allNames.mat
pars.filenameFile=[infoDir 'allNames.mat']; % in the working directory

% for picking preprocessor
%%pars.mapMode='KvAlpha';
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
isCluster=any(strncmpi(host,{'m' 'r'},2));  % mccleary nodes are like r103u17n01
disp(['isCluster = ' num2str(isCluster)])
sb=getenv('BATCH_ENVIRONMENT');
isInteractive=~( strcmp(sb,'BATCH'));
disp(['isInteractive = ' num2str(isInteractive)]);
pars.showGraphics=isInteractive;  % show graphics anyway if simulating.

numJobs=str2double(getenv('NUM_JOBS'))
jobIndex=str2double(getenv('JOB_ID')) % one-based index

if isInteractive
    disp('Batch simulation:');
    numJobs=MyInput('numJobs',1);
    jobIndex=MyInput('jobIndex',1);

else
    if isnan(numJobs)
        disp('undefined number of jobs');
        numJobs=1;
    end;
    if isnan(jobIndex)
        disp('undefined job index');
        jobIndex=1;
    end;
end;

% Set up the log file
CheckAndMakeDir('Log',1);

% Create a log file.
logName=[logDir sprintf('%02d',jobIndex) 'log.txt'];
logFile=fopen(logName,'a');
logs=struct;
logs.handles=[1 logFile];
logs.idString='';
pars.logs=logs;
mdisp(pars.logs,' ');
mdisp(pars.logs,'======================================================================-');
mprintf(pars.logs.handles,'%s%s%d\n',datestr(now),' Startup: group ',jobIndex);
mdisp(pars.logs,pwd);

% Get the mi file names

if pars.loadFilenames
    disp(['loading ' pars.filenameFile]);
    if exist(pars.filenameFile,'file')
        load(pars.filenameFile);
    else
    disp('The filenames file wasnt found. Getting the mi file names');
    allNames=f2FindInfoFiles(infoDir);
    end;
else
    disp('Finding the mi files');
    allNames=f2FindInfoFiles(infoDir);
end;

% First divide the whole dataset into a Run
totalNames=numel(allNames);
nNames=ceil(totalNames/nRuns);
runOffset=nNames*(runIndex-1);

disp([num2str(nNames) ' files total in this run.']);

if nNames<1
    msg=['No mi files found in ' pwd filesep infoDir];
    mdisp(pars.logs,msg);
    error(msg);
end;

% Figure out what we will do
% jobOffset tells how many files to skip at beginning or at end
jobStart=max(1,min(nNames,jobStart));
jobEnd=min(nNames, jobEnd)
mprintf(pars.logs.handles,'Whole job: %d to %d\n',jobStart,jobEnd);

blockSize=(jobEnd-jobStart+1)/numJobs;
ourBlockStart=round(jobStart+(jobIndex-1)*blockSize)+runOffset;
ourBlockEnd=min(jobEnd,round(jobIndex*blockSize+jobStart-1))+runOffset;
ourBlockEnd=min(totalNames,ourBlockEnd);
mprintf(pars.logs.handles,'Our files %d to %d\n',ourBlockStart,ourBlockEnd);

ourNames=allNames(ourBlockStart:ourBlockEnd);

% %% loading the redoNames to operate on.
% load redoNames.mat
% ourNames=redoNames;
numNames=numel(ourNames);
disp([num2str(numNames) ' to process.']);


numNames=numel(ourNames);
if numNames<1  % nothing to do

    error(['No mi files found: ' pwd]);
end;

% turn off the warning message we get when mi contains huge strings.
warning('off','MATLAB:namelengthmaxexceeded');

% initializations
logSeqs=zeros(numNames,8);
nParticles=zeros(numNames,1);
nVesicles=zeros(numNames,1);
defs=zeros(numNames,1);

if skipAlreadyDone
    disp('Checking mi logs')
    miOk=true(numNames,1);
    for i=1:numNames
        mi=ReadMiFile(ourNames{i});
        logSeqs(i,:)=miDecodeLog(mi);
%         if any(isnan(logSeqs(i,:)))
%             disp(['Bad mi file ' ourNames{i}]);
%             miOk(i)=false;
%             str=['rm ' ourNames{i}];
%             disp(str);
%             ourNames{i}='';
%             continue;
%         end;
        nParticles(i)=size(mi.particle.picks,1);
        nVesicles(i)=numel(mi.vesicle.x);
        defs(i)=mi.ctf.defocus;
    end;
%     ourNames(~miOk)=[]; % remove bad names
%     logSeqs(~miOk,:)=[];
% %     miOk=true(numNames,1);
%     numNames=numel(ourNames);

end;

    % inverse filter (sequence 6)
    if doPrelimInverseFilter
        active=miOk(i) && logSeqs(:,6)==0;
        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for inverse filtero0'])
        if any(active)
        fpars=struct;
        fpars.useUnsubImage=1;
            meInverseFilterAuto(activeNames,fpars);
        end;
    end;

    if doFindVesicles
        active= logSeqs(:,4)==0;
        disp(['Number active: ' num2str(sum(active))]);
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
        if skipAlreadyDone
            disp('Picking preprocessor: checking mi logs')
            for i=1:numNames
                mi=ReadMiFile(ourNames{i});
                logSeqs(i,:)=miDecodeLog(mi);
            end;
            active=(logSeqs(:,8)==0 & logSeqs(:,5)>0); % refined and not already done.
        else
            active=true(numNames,1);
            disp('Forcing preprocessing.')
        end;

        activeNames=ourNames(active);
        disp([num2str(sum(active)) ' mi files for preprocessor.'])
        if any(active)
            rsPickingPreprocessor4(activeNames,pars);
        end;
    end;


    if doPicking

            disp('Picking: checking mi logs')
            nLParticles=zeros(numNames,1);
            for i=1:numNames
                mi=ReadMiFile(ourNames{i});
                logSeqs(i,:)=miDecodeLog(mi);
                nParticles(i)=size(mi.particle.picks,1);
            end;

        active=logSeqs(:,8)~=0;
        unpicked=nParticles==0;
        if skipAlreadyDone
            active=active & unpicked;
        else
            disp('Pick all.');
            if sum(active) < numNames
                disp('But not all preprocesssed.')
            end;
        end;
        disp([num2str(sum(active)) ' micrographs to pick.'])
        if any(active)
            BatchRSPicker(ourNames(active));
        else
            disp('No preprocessed images available.')
        end
    end;
    
    tempDir=[infoDir 'tmp_k3p/']
    CheckAndMakeDir(tempDir);
    if updateAllMis
        amName=[tempDir 'allMis' num2str(jobIndex,'%03d')];
        allMis=cell(numNames,1);
        disp('Loading mi files');
        for i=1:numNames
            mi=ReadMiFile(ourNames{i});
            mi.infoPath=infoDir;
            allMis{i}=mi;
        end;
        disp(['saving ' num2str(numNames) ' mi files to ' amName]);
        save(amName,'allMis');
    end;

    disp('Done.')
    