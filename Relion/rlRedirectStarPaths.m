% rlRedirectStarPaths.m
% When importing a micrographs_ctf.star or particles.star file from a
% directory other than the project directory, you use this program to
% insert a prefix into the rlnMicrographName and the rlnImageName fields,
% and write out a 'redirected' star file.

%inPath='CtfFind/job011/';
% inPath='RSC1/';
% outPath=inPath;
% inNames={'micrograph_ctf1_u.star'
%     'micrograph_ctf1_v.star'
%     'particles1_u.star'
%     'particles1_v.star'};

% inPath='Select/job139';
% outPath=inPath;
% in
inPath='0205/RSC1/'
outPath=inPath;
inNames={'particles1_u_orgA.star'
            'particles1_v_orgA.star'
            'micrograph_ctf1_u.star'
            'micrograph_ctf1_v.star'};
partsToo=0;


for iFile=1:numel(inNames)
    inName=inNames{iFile};
    [nm,pa,ex]=fileparts(inName);
    %outName='micrograph_ctf1_redir.star';
    outName=[pa nm '_re0205' ex]; % insert the redir part.

    % not currently implemented:
    % opticsGroupOffset=2;
    % opticsGroupNamePattern='og%d'

    %
    % inPath='Extract/job017/';
    % inName='particles.star';
    % outPath=inPath;
    % outName='particles_redir.star';
    micPrefix='0205/';
    partPrefix='';

    disp(['Reading ' inPath inName]);
    [inNm,inDa]=ReadStarFile([inPath inName]);
    %%
    inDat=inDa{2};
    fieldNames=fieldnames(inDat);
    % disp(' field names:');
    % disp(fieldNames);

    % modify micrograph names
    disp('rlnMicrographName:')
    % micPrefix='../20240205BNL/';
    oldMicNames=inDat.rlnMicrographName;
    disp(oldMicNames{1});
    nmn=numel(oldMicNames);
    newMicNames=cell(nmn,1);
    for i=1:nmn
        newMicNames{i}=[micPrefix oldMicNames{i}];
    end;
    disp(newMicNames{1});
    disp(' ');

    %
    % modify particle micrograph names

    if numel(partPrefix)>0 && any(strcmp(fieldNames,'rlnImageName'))
        partsToo=1;
        oldPartNames=inDat.rlnImageName;
        disp('rlnImageNames:')
        disp(oldPartNames{1});
        npn=numel(oldPartNames);
        newPartNames=oldPartNames; % by default, no changes.

        disp(oldPartNames{1});
        % partMicNames=strsplit(inPartNames,'@');
        atPtrs=strfind(oldPartNames,'@');
        for i=1:npn
            pt=atPtrs{i}(1);
            name=oldPartNames{i};
            newName=[name(1:pt) partPrefix name(pt+1:end)];
            newPartNames{i}=newName;
        end;
        disp(newPartNames{1});
    end;

    %%

    disp(['Writing ' outPath outName]);

    outDat=inDat;
    outDat.rlnMicrographName=newMicNames;
    if partsToo
        outDat.rlnImageName=newPartNames;
    end;
    outDa{1}=inDa{1};
    outDa{2}=outDat;
    WriteStarFile(inNm,outDa,[outPath outName]);

end; % for iFile
disp('done.');


% if we're working on particle images, we'll have to decode the particle
% names.




