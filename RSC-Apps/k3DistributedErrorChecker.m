% k3DistributedErrorChecker
% Discover which job array jobs have errors.
% We scan all the job array .err files to see if any have more than the
% usual number of bytes, i.e. an error has occurred.


lastJobInd=192;
byteThreshold=300;
upperThreshold=inf;

d=dir('k*.err');
nd=numel(d);
disp([num2str(nd) ' files.']);

% Decode the job numbers
names=cell(nd,i);
arrayNum=zeros(nd,1);
jobNum=zeros(nd,1);
bytes=zeros(nd,1);
for i=1:nd
    name=d(i).name;
    ptr1=strfind(name,'_');
    if numel(ptr1)<1
        disp(['No _ in name ' name]);
        return
    end;
    arrayText=name(2:ptr1(1)-1);
    ptr2=strfind(name,'.');
    jobText=name(ptr1(1)+1:ptr2(1)-1);
    arrayNum(i)=str2num(arrayText);
    jobNum(i)=str2num(jobText);
    bytes(i)=d(i).bytes;
    names{i}=name;
end;

[uJobNums,ijoA,ijoC]=unique(jobNum);
[uArrayNums,iarA,iarC]=unique(arrayNum);

% find all the entries with excessiv byte counts
aboveThresh=find(bytes>byteThreshold & bytes<upperThreshold);
nAbove=numel(aboveThresh);

uJobInds=zeros(nAbove,1);
%find all unique job numbers corresponding to each aboveThresh entry.
for i=1:nAbove
    uJobInds(i)=find(uJobNums==jobNum(aboveThresh(i)));
end;

%%% some logic problem around here-----

% uJobInds=unique(jobInds); % pick an index to each bad job
% 
% nuj=numel(uJobInds);
% 
% badJobNums=uJobNums(uJobInds);

% Identify the set of jobs where the last file has the number of bytes outside the limit.
j=0;
newJobs=zeros(0,1);
for i=1:nuj
    q=find(ijoC==uJobInds(i));
    if (bytes(q(end))>byteThreshold )%n& bytes(q(end))<upperThreshold)
        j=j+1;
        newJobs(j)=UJobNums(i); % job to resubmit
    end;
end;
badJobs=unique(newJobs);


if numel(newJobs)<1
    disp('Nothing to do.')
    return
end;s
S

%%
% look up the lastJobInd job name
%  So we can cancel and restart it along with the lower-numbered jobs.

ind1=find(uJobNums==lastJobInd);
inds2=find(ijoC==ind1);
% bytes(inds2)
% jobNum(inds2)
% arrayNum(inds2)
% names(inds2)
last=inds2(end);
% names(last)
str0=sprintf('%s %d_%d','scancel',arrayNum(last),jobNum(last));
disp(['exec this string st0: ' str0]);
%
% Start all the stalled jobs

str1=sprintf('%d,',newJobs);
str2=['sbatch --array=' str1 num2str(lastJobInd) ' k3pRunv'];

disp(['exec this str2: ' str2]);

return


% 
% 
% for i=1:10 %numel(lines)
%     q=find(iC==lines(i));
% disp([uJobNums(lines(i)) q']);
% end;