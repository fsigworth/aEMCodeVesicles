
% rlLinkCSMicrographs.m
%
% From CS micrograph directories, make links with shortened names to the
% '*_patch_aligned_doseweighted.mrc' files.
%
% Names are shortened by extracting the charactgers between the first and
% 5th underscores, then adding '.mrc' at the end.


cd '~/tomo/sigworth/20240829_prestin/micrographs'
CheckAndMakeDir('links');

system('rm links/*') % get rid of any previous links.

prefixes={'J3' 'J4' 'J5' 'J6' 'J32' 'J33' 'J50'};
for ip=1:numel(prefixes)
    prefix=prefixes{ip};
    disp(prefix);
    d=dir([prefix '_mics/']);

    origNames={};
    shortNames={};
    j=0;
    fprintf('\n');
    for i=1:numel(d)
        [shortName,tail]=rlShortenCSName(d(i).name);
        if strcmp(tail,'patch_aligned_doseweighted.mrc')
            j=j+1;
            origNames{j}=d(i).name;
            shortNames{j}=[prefix shortName '.mrc'];
            % if j<10
            %     disp(shortName);
            % end;
            execString=['ln -s ' d(i).folder '/' d(i).name ' links/' shortNames{j}];
            % disp(execString);
            system(execString);
            if mod(j,100)==0
                fprintf('.');
            end;

        end;
    end;
    fprintf('\n');
    disp(j);
end;




function [shortName,tail]=rlShortenCSName(baseName)
    usLast=5;
    usPtrs=find(baseName=='_');
    if numel(usPtrs)>=usLast
        shortName=baseName(usPtrs(1)+1:usPtrs(usLast)-1);
        tail=baseName(usPtrs(usLast)+1:end);
    else
        shortName='';
        tail='';
    end;
end
