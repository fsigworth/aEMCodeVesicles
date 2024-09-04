function WriteMiText(mi,filename,writeExtendedFile)
% function WriteMiText(mi,filename,writeExtendedFile)
% Write out an mi structure as a text file.
% By default (no 3rd argument) an extended data file (*mie.mat) is written of parts of the
% mi structure that take lots of room (parts of the vesicle field, the mask
% field).

if nargin<3
    writeExtendedFile=1;
end;

mi.timestamp={TimeStamp};  % mark the date and time of writing the file.

% Set up the extended-file fields
if writeExtendedFile
    extFields={'vesicle'; 'mask'; 'noiseSpectrum'};
    copyFields={'baseFilename'; 'identifier'; 'timestamp' };
else
    extFields={};
end;

mie=struct;
mie.identifier=mi.identifier;
mie.baseFilename=mi.baseFilename;
if writeExtendedFile
%     We copy identifying fields
    for i=1:numel(copyFields)
        if isfield(mi,copyFields{i})
            mie.(copyFields{i})=mi.(copyFields{i});
        end;
    end;
    j=0;
    mieFields={};
    for i=1:numel(extFields)
        f=extFields{i};
        if isfield(mi,f)
            mie.(f)=mi.(f);
            j=j+1;
            mieFields{j,1}=f;
            %    Truncate long fields
            switch f
                case 'vesicle'
                    if numel(mi.vesicle.r)>0
                        mi.vesicle.s=mi.vesicle.s(:,1,1);
                        mi.vesicle.r=mi.vesicle.r(:,1);
                    end;
                case 'noiseSpectrum'
                mi.noiseSpectrum=mi.noiseSpectrum(1:min(32,end));
            end;
        end;
    end;
    mi.mieFields=mieFields;
    [pa,nm]=fileparts(filename);
    extName=[AddSlash(pa) nm 'e.mat'];
    save(extName,'mie');
else
    mi.mieFields={};
end;
    
% Reorder the fields in the mi structure    
names0=fieldnames(mi);
nf0=numel(names0);

% Give the field order, and label the types.
% 0: string; 1: cell array of strings;  2: numeric; 3: ctf;
% 4: vesicle; 5: particle; 6: mask
orderedNames={
    'version' 0; 'baseFilename' 0;'originalBasePath' 0;
    'basePath' 0; 'moviePath' 0;'imagePath' 0; 'procPath' 0; 'infoPath' 0;
    'stackPath' 0; 'tempPath' 0; 'movieFilename' 0;'gainRefName' 0;
    'imageFilenames' 1;'imageSize' 2;'pixA' 2;'kV' 2; 'cpe' 2; 'camera' 2;
    'tiltAngles' 2;'tiltAxis' 2;
    'frameDose' 2;'frameSets' 2; 'doses' 2;'weights' 2;
    'ctf' 3;'mergeMatrix' 2; 'mergeSNR' 2; 'particle' 5; 'ppVals' 7; 
    'boxSize' 2; 'vesicleModel' 2;'vesicle' 4;'quality' 0; 'noiseModelPars' 2;
    'noiseModelCode' 1; 'damageModelCode' 1; 'frameShifts' 2;
    'mask' 6; 'identifier' 2; 'notes' 1; 'log' 1; 'mieFields' 1};

nOrderedNames=size(orderedNames,1);
nameOrder=zeros(nOrderedNames,1);
for j=1:nOrderedNames
    q=strcmp(orderedNames{j,1},names0);
    pto=find(q,1);
    if numel(pto)<1
        pto=0;
    end;
    nameOrder(j)=pto;
end;

% Any fields that are missing from orderedNames are deleted
nameOrder(nameOrder==0)=[];

% Any leftover fields are put at the end
j=numel(nameOrder);
for k=1:nf0
    if ~any(nameOrder==k)
        j=j+1;
        nameOrder(j)=k;
    end;
end;

% Clean up the mi structure
mi=orderfields(mi,nameOrder);
if isfield(mi,'vesicle') && isfield(mi.vesicle,'ok')
    mi.vesicle.ok=logical(mi.vesicle.ok);
end;
if isfield(mi,'ctf')
mi.ctf=RemoveFields(mi.ctf,{'res' 'pixA'});
end;

Ex=struct;
Ex.fieldNames={'identifier' 'mergeMatrix' 'picks' 'frameSets' 'data'};
Ex.rowSize=[       1             9            0         0        60 ];
Ex.writeClass={'double'          ''           ''        ''     'hex'};


% -------- Actually do the writing here ----------

WriteStructText(mi,filename,Ex)


    function s=RemoveFields(s,fields)
        nf=numel(fields);
        for i1=1:nf
            if isfield(s,fields{i1})
                s=rmfield(s,fields{i1});
            end;
        end;
    end

end
