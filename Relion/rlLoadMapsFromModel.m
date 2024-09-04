
function [maps,nParticles,mapProbs,mapNames]=rlLoadMapsFromModel(modelFilename)
% Given a model.star file or a multi-references star file, find and load 
% the 3D maps into the 4D maps
% array. mapProbs shows the probability distribution among the maps. If the
% modelFilename is for an .mrc file we simply read that file.


[pa,nm,ex]=fileparts(modelFilename);
if ~strcmp(ex,'.mrc')
    p=strfind(modelFilename,'_');
    if numel(p)<2
        p(2)=numel(nm);
    end;
    baseName=modelFilename(1:p(2));
    disp(['Reading ' modelFilename])
    [blocks,dat,ok]=ReadStarFile(modelFilename);
    if ~ok
        error('No data in Star file.');
    end;

    % In the star file, look for model entries.
    q1=strcmp('data_model_classes',blocks);
    classesIndex=1; % default
    if any(q1)
        classesIndex=find(q1,1);
        q1=strcmp('data_model_general',blocks);
        if ~any(q1)
            error('No model_general block found');
        end;
        generalIndex=find(q1,1);
%         n=dat{generalIndex}.rlnOriginalImageSize;
%         pixA=dat{generalIndex}.rlnPixelSize;
    else
        q2=strcmp('data_references',blocks); % alternative, look for references.
        if any(q2)
            classesIndex=find(q2,1);
        end;
    end;
    q3=strcmp('data_model_groups',blocks);
    if any(q3)
        gpDat=dat{find(q3,1)};
        nParticles=sum(gpDat.rlnGroupNrParticles);
    else
        nParticles=1;
    end;
    %%
    mapNames=dat{classesIndex}.rlnReferenceImage;
        if ischar(mapNames)
        nim=1;
        mapNames={mapNames};
    else
        nim=numel(mapNames);
    end;

    if isfield(dat{classesIndex},'rlnClassDistribution')
        mapProbs=dat{classesIndex}.rlnClassDistribution;
    else
        mapProbs=ones(nim,1);
    end;
        
else
    nim=1;
    mapNames={modelFilename};
    mapProbs=1;
end;

[maps,s]=ReadMRC(mapNames{1});
pixA=s.pixA;

for i=2:nim
    mp=ReadMRC(mapNames{i});
    maps(:,:,:,i)=mp;
end;
