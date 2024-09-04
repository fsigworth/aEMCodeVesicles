% rlShowClass3D2.m
% Given a model.star file, display 3D classes from relion refinement or 3D classification.
% The 3D models are shown using our ShowSections function.
% If you cancel the model.star file selection, the file selector then comes
% up for choosing one or more .mrc files.
%
% Note that you have to be in the appropriate Relion directory for it to
% work reliably.

displayAngle=45;
%displayAngle=90
zFraction=.68; % relative Z-height of slice
showToolbar=0;
skipLoading=0;
rotY=0; % rotate 180 degrees about Y
cropSize=112;
%cropSize=inf;
if ~(skipLoading && exist('maps','var'))
    [modelName,modelPath]=uigetfile('*.star','Select model.star');
    if isa(modelPath,'char') % we gpt a model
        modelFilename=[modelPath modelName];
        disp(modelFilename);
        [maps,nParticles,mapProbs,mapNames]=rlLoadMapsFromModel(modelFilename);
    else % load mrc file(s)
        [mapNames,modelPath]=uigetfile('*.mrc','MultiSelect','on','Select mrc files');
        if ~isa(modelPath,'char')
            return
        end;
        if ~isa(mapNames,'cell')
            mapNames={mapNames};
        end;
        nm=numel(mapNames);
        modelFilename=[modelPath mapNames{1}];
        [maps,s]=ReadMRC(modelFilename);

        for i=2:nm
            maps(:,:,:,i)=ReadMRC([modelPath mapNames{i}]);
        end;
        mapProbs=ones(nm,1);
        nParticles=1;

    end;
% cd(modelPath);
%%

% 
% [pa,nm,ex]=fileparts(modelFilename);
% if ~strcmp(ex,'.mrc')
%     p=strfind(modelFilename,'_');
%     if numel(p)<2
%         p(2)=numel(nm);
%     end;
%     baseName=modelFilename(1:p(2));
% 
%     [blocks,dat,ok]=ReadStarFile(modelFilename);
%     if ~ok
%         error('No data in Star file.');
%     end;
% 
%     q1=strcmp('data_model_classes',blocks);
%         if ~any(q1)
%             error('No model_classes block found'); 
%         end;
%         classesIndex=find(q1,1);
%         q1=strcmp('data_model_general',blocks);
%         if ~any(q1)
%             error('No model_general block found');
%         end;
%         generalIndex=find(q1,1);
% 
%     n=dat{generalIndex}.rlnOriginalImageSize;
%     pixA=dat{generalIndex}.rlnPixelSize;
%     %%
%     mapNames=dat{classesIndex}.rlnReferenceImage;
%     mapProbs=dat{classesIndex}.rlnClassDistribution;
%     if ischar(mapNames)
%         nim=1;
%         mapNames={mapNames};
%     else
%         nim=numel(mapNames);
%     end;
% else
%     nim=1;
%     mapNames={modelFilename};
%     mapProbs=1;
% end;
% %%
% maps=zeros(n,n,n,nim,'single');
% %
% opts=struct;
% opts.rowLabels=cell(nim,1);
% for i=1:nim
%     probString=num2str(mapProbs(i),3);
%     disp([mapNames{i} '  ' probString]);
%     opts.rowLabels{i}=probString;
%     mp=ReadMRC(mapNames{i});
%     if rotY
%         mp=shiftdim(rot90(shiftdim(mp,1),2),2);
%     end
%     maps(:,:,:,i)=mp;
% end;
maps0=maps;
end; % if ~skipLoading
%%
disp(' ');
disp('cls  prob    file');
npr=numel(mapProbs);
probStrings=cell(npr,1);
for i=1:npr
    [pa nm ex]=fileparts(mapNames{i});
    probStrings{i}=[num2str(mapProbs(i),'%.3g')];
    if nParticles>1
        probStrings{i}=[probStrings{i} '  ' num2str(nParticles*mapProbs(i)/1000,'%.3g') 'k'];
    end;
    disp([num2str(i) '  ' num2str(mapProbs(i)) '  ' nm ex ]);
end;
n0=size(maps0,1);
n=n0;
if n>cropSize % we'll crop down only.
    maps=Crop(maps0,cropSize,ndims(maps)>3); % it's a stack only if 4D array
    n=cropSize;
else
    n=n0;
    maps=maps0;
end;
nctr=ceil((n+1)/2);
nz=round(n0*zFraction-ceil((n0+1)/2)+nctr);
%
% %     msks=repmat(discMask,[1 1 1 nim]); %%%%
%ShowSections(map
% 
ops=struct;
opts.rowLabels=probStrings;
ShowSections(maps,[nctr,nctr,nz],displayAngle,opts); % not using opts because ShowSections can't make labels.
%ShowSections(maps,[n2,n2,nz],displayAngle,opts); % not using opts because ShowSections can't make labels.
%ShowSections(maps,[n2,n2,nz],displayAngle); % not using opts because ShowSections can't make labels.
% % ShowSections(maps.*msks,[n2,n2,nz],displayAngle); % not using opts because ShowSections can't make labels.

% put up the filename and make the figure plain.
set(gcf,'name',modelFilename);
set(gcf,'MenuBar','none');
if ~showToolbar
    set(gcf,'ToolBar','none');
end;


return;
