% rlFindStarDuplicates.m

% Search for repeated micrograph names in a micrographs or particle star
% file. Writes out xxxx_nodup.star

% starNames={'../20240205BNL/CtfFind/job011/micrographs_ctf.star';
%             'CtfFind/job006/micrographs_ctf.star';
%             'CtfFind/job016/micrographs_ctf.star';
%             'CtfFind/job044/micrographs_ctf.star'
%starNames={'RSC2/particles2_v.star'};

starNames={'RSC2/micrograph_ctf2_u.star'}

micNames=cell(0,1);
numStars=numel(starNames);
starStarts=zeros(numStars+1,1);
starStarts(1)=1;
for i=1:numStars
    disp(starNames{i});
    [nm,da]=ReadStarFile(starNames{i});
    dat=da{2};
    nmn=numel(dat.rlnMicrographName);
    micNames(starStarts(i):starStarts(i)+nmn-1)=dat.rlnMicrographName;
    starStarts(i+1)=starStarts(i)+nmn;
end;
numNames=starStarts(numStars+1)-1;

% %% Remove bad lines from particle file ??

% totalFound=0;
% numBadNames=numel(badNames);
% for j=1:numBadNames
%     bools=strcmp(micNames,badNames{j});
%     totalFound=totalFound+sum(bools);
% end;
% disp(['total bad names matched ' num2str(totalFound)]);
% return
%% brute-force name search
% internal name search
matches=cell(numNames,1);
k=0;
dups=cell(0,2);
active=true(numNames,1);

for j=1:numNames
    bools=strcmp(micNames,micNames{j});
    ptrs=find(bools);
    matches{j}=ptrs;

    if numel(ptrs)>1
        k=k+1;
        dups{k}=[j ptrs'];
        for ip=2:numel(ptrs)
            active(ptrs(ip))=false;
        end;
    end;
end;
numDups=k
%%


if k>0
    badNames=micNames(~active);
    save('BadMicNames.mat','badNames');
    disp('Wrote BadMicNames.mat');
end;

%
% disp(matches(1:10));
disp(['nActive, nDisabled, total: ' num2str([sum(active) sum(~active) numel(active)])]);
% numActive=sum(active)
% numDisabled=sum(~active)

% Write the selected parts of the final file.
[pa,nam,ext]=fileparts(starNames{i});
outName=[AddSlash(pa) nam '_nodup' ext];
actives=cell(2,1);
actives{2}=active;
disp(['Writing ' outName])




WriteStarFile(nm,da,outName,'# v3',actives);
disp('done.');
