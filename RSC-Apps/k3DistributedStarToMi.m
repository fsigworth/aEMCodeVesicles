% k3DistributedStarToMi.m

runIndex=1;
nRuns=1;

jobStart=1;
jobEnd=inf;

% Directories must be set up
%workingDir='/gpfs/ysm/scratch60/sigworth/fjs2/20220920/';
% workingDir='/gpfs/gibbs/pi/tomography/sigworth/20220920/';
% workingDir='/gpfs/gibbs/pi/tomography/sigworth/20240116/';
workingDir='/gpfs/gibbs/pi/sigworth/20240703/'
workingDir='~/EMWork/'SYP_kO_testmicrograph/';

starName='JoinStar/job017/join_mics.star'
pathNameSuffix=''; % we now construct the filenames using this suffix

cd(workingDir)
[names,dat]=ReadStarFile(starName);
starData={names dat};

totalNames=numel(dat{2}.rlnMicrographName);
nNames=ceil(totalNames/nRuns);
runOffset=ceil((runIndex-1)*nNames);

rpars.writeSubMRC=1;
rpars.writeSmallMRC=0;
rpars.writeSmallSubMRC=1;

% Figure out who we are
host=getenv('HOSTNAME');
isCluster=any(strncmpi(host,{'n'},1));  % mccleary nodes are like 'r103u17n01'
disp(['isCluster = ' num2str(isCluster)]);
sb=getenv('BATCH_ENVIRONMENT');
isInteractive=~( strcmp(sb,'BATCH'));
disp(['isInteractive = ' num2str(isInteractive)]);
pars.showGraphics=isInteractive;  % show graphics anyway if simulating.

numJobs=str2double(getenv('NUM_JOBS'));
jobIndex=str2double(getenv('JOB_ID')); % one-based index

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

% Figure out what we will do
% jobStart tells how many files to skip at beginning
jobStart=max(1,min(nNames,jobStart));
jobEnd=min(nNames, jobEnd);
blockSize=(jobEnd-jobStart+1)/numJobs;
ourBlockStart=round(jobStart+(jobIndex-1)*blockSize)+runOffset;
ourBlockEnd=min(jobEnd,round(jobIndex*blockSize+jobStart-1)+runOffset);
ourBlockEnd=min(ourBlockEnd,totalNames);

pars=struct; % parameters for rlStarToMiFiles

pars.firstLine=ourBlockStart;
pars.lastLine=ourBlockEnd;
pars.pathNameSuffix=pathNameSuffix; % we now construct all the directory names using this suffix.
pars.replaceCorruptedMiFiles=0;
pars.writeMergedImage=0;
pars.writeMergedSmall=1;
pars.writeJpeg=1;
pars.writeJpegInv=0;  % Make -1 to reverse the contrast.

rlStarToMiFiles(starData,pars);

disp('k3DistributedStarToMi done.')
