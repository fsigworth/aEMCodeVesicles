


% rlShortenEPUMovieNames
% Rename all the names of all movie or micrograph files in directory to make 
% names of reasonable length. 


movieDir='micrographs';

movieDir=AddSlash(movieDir);
% disp('rlShortenEPUMovieNames');
disp(['Working on ' movieDir]);
if exist([movieDir 'nameList.mat'],'file')
    disp([movieDir 'nameList.mat exists, no translations to do.'])
    return
end;
extensions={'.tiff' '.mrc'};
d=dir(movieDir);
nd=numel(d);
inNames=cell(nd,1);
outNames=cell(nd,1);
j=0;
for i=1:nd
    name=[movieDir d(i).name];
    [~,nm,ex]=fileparts(name);
    if d(i).isdir || ~any(strcmp(ex,extensions))
        continue;
    end;
    j=j+1;

    outName=[movieDir rlShortenEPUName(nm) ex];
    inNames{j,1}=name;
    outNames{j,1}=outName;
end;
totalNames=j;
disp([num2str(totalNames) ' names found.'])
% truncate the lists.
inNames(j+1:end)=[];
outNames(j+1:end)=[];
uoNames=unique(outNames);
numRepeats=numel(outNames)-numel(uoNames);
disp(['There are ' num2str(numRepeats) ' repeated short names.']);
if numRepeats ~=0
     disp('Quitting.')
     return
end;

changed=false(nd,1);
for j=1:totalNames
    name=inNames{j};
    outName=outNames{j};
    changed(j) = ~strcmp(name,outName);

    str=['mv ' name ' ' outName];
    if j<10
        if doExec && changed(j)
            disp(str);
        else
            disp([str ' --not moved']);
        end;
    end;
    if mod(j,100)==0
        fprintf('.');
    end;
    if mod(j,5000)==0
        fprintf('\n');
    end;
    if doExec && changed(j)
        system(str);
    end;
end;
fprintf('\n');
disp([num2str(sum(changed)) ' files renamed.'])

% save the translation
if doExec && any(changed)
    save([movieDir 'nameList'],'inNames','outNames');
    disp(['Translation saved in ' movieDir 'nameList.mat'])
end;
disp('done.');

