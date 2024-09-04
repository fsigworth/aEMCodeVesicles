% rlShortenEPUFieldNames.m
% Rename all the files in selected star file fields, in the same way we've
% shortened the movie or micrograph filenames in a directory using rlShortenEPUMovieNames.
% For example
%  'micrographs/FoilHole_16987437_Data_16986952_16986954_20240517_114243_fractions_patch_aligned_doseweighted.mrc'
% is replaced with
%  'micrographs/20240517_114243.mrc'

starName='micrographs_all_gctf.star';
outStarName='micrographs_short_ctf.star';
theFields={'rlnMicrographName'; 'rlnCtfImage'};

[nms,da]=ReadStarFile(starName);

for i=1:numel(da)
    d=da{i};
    fields=fieldnames(d);
    for k=1:numel(theFields)
        theField=theFields{k};
        q=strcmp(theField,fields);
        if ~any(q)
            skips=skips+1;
            disp([nms{i} ' ' theField ' skipped.']);
            continue;
        end;
        names=d.(theField);
        nn=numel(names);
        newNames=cell(nn,1);
        for j=1:nn
            [pa,nm,ex]=fileparts(names{j});
            newNames{j}=[AddSlash(pa) rlShortenEPUName(names{j}) ex];
        end;
        da{i}.(theField)=newNames;
        disp([nms{i} ' ' theField ' updated.']);
    end;
end;

WriteStarFile(nms,da,outStarName);

return

