% k3DistGatherMis.m
% Gather the allMis files created by k3DistributedPipeline: updateAllMis
% and write one big allMis.mat file into the Info directory.

infoDir='Info2/';

tempDir=[infoDir 'tmp_k3p/'];  % now inside the info directory

allNames=f2FindInfoFiles(infoDir);
save([infoDir 'allNames.mat'],'allNames');

d=dir(tempDir);
j=0;
ourNames=cell(0,1);
for i=1:numel(d)
    nm=d(i).name;
    if strncmp(nm,'allMis',6) && numel(nm)==13
        j=j+1;
        ourNames{j}=[tempDir nm];
    end;
end;
disp([num2str(j) ' mat files found.'])
if j<1
    disp('quitting.');
    return
end;

ourNames=sort(ourNames);
accum=struct;
disp('accumulating allMis files...');
for i=1:numel(ourNames)
    str=load(ourNames{i});
    disp([ourNames{i} '  ' num2str(numel(str.allMis))]);
    if i==1
        accum=str;
    else
        accum.allMis=[accum.allMis ; str.allMis];
    end;
end;
allMis=accum.allMis;
disp(['Saving ' num2str(numel(allMis)) ' total mi structures...'])
save([infoDir 'allMis.mat'],'allMis');


%% Make histogram of defocus values, plots of vesicle, particle numbers

nmis=numel(allMis);

disp('Making figures');
defs=zeros(nmis,1);
nVes=zeros(nmis,1);
nParts=zeros(nmis,1);
for i=1:nmis
    mi=allMis{i};
    defs(i)=mi.ctf(1).defocus;
    nVes(i)=numel(mi.vesicle.x);
    nParts(i)=size(mi.particle.picks,1);
end;


figure(1);
clf;
hist(defs,100);
xlabel('Defocus, \mum');
ylabel('Frequency');

iStart=1;
iEnd=nmis;
iStart=0001;
iEnd=4000;

figure(2)
subplot(311);
plot(nVes(iStart:iEnd));
ylabel('vesicles');
subplot(312);
plot(nParts(iStart:iEnd));
ylabel('particles');
grid on;
subplot(313);
plot(defs(iStart:iEnd));
ylabel('defocus');
xlabel('mi file index');
grid on;


%str=['rm ' tempDir '*']; % clear
if exist(tempDir)
    xDir=[infoDir 'txx_k3p/'];  % now inside the info directory
    str=['mv ' tempDir ' ' xDir]; % change 'tmp... to 'txx...'
    disp(str);
    system(str);
end;
disp('Done.');
return

%%
allMis1=allMis; % Make a backup.
% Make modifications to the allMis elements.
for i=1:nmis
    mi=allMis{i};
    mi.infoPath='Info2/';
    mi.procPath='Merged2/';
    mi.procPath_sm='Merged2_sm/';
    allMis{i}=mi;
end;
save Info2/allMis.mat allMis
%
% get ready to unpack the mi files
disp(['Info path is ' allMis{1}.infoPath]);
disp('done.');
%%
for i=1:nmis
    WriteMiFile(allMis{i});
    if mod(i,1000)==0
        fprintf('.');
    end;
end;
disp(' ');
