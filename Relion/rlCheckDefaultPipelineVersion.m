function rlCheckDefaultPipelineVersion(theDir)
% recurse through a directory tree, looking at jobs to find the version
% numbers. List all jobs having default_pipeline.star with version 3. This
% way we can find which copy of default_pipeline.star to copy back to the
% working directory, to allow Version 3 to be used in a directory where
% version 4 or 5 had been run.
% Call this for example with rlCheckDefaultPipelineVersion(pwd)
% 
workDir='/gpfs/gibbs/pi/sigworth/20240321BNL_r3/';
archDir=[workDir 'V5Archive/'];

% Alternative code:
% To move or copy to the _r3 archive directory all jobs greater than 088.
% Note that we are attempting, but should not
% move the .Nodes or archive directory!!
%
% workDir1=workDir;
% workDir='/gpfs/gibbs/pi/sigworth/20240321BNL/';
% archDir=[workDir1 'V5Archive/'];
% 
% d=dir(theDir);
% for i=3:numel(d)
%     if d(i).isdir
%         dirName=d(i).name;
%         [~,lastDir]=ParsePath(theDir);
%         newDir=[AddSlash(theDir) dirName];
% 
%         % disp(dirName);
%         if strncmp(dirName,'job',3)
%             jobnum=str2double(dirName(4:end));
%             % disp(jobnum)
%             %% Code to move v5 jobs to the arch folder
%             if jobnum>88
%                 CheckAndMakeDir([archDir lastDir]);
%                 % str=['mv ' newDir ' ' archDir lastDir];
%                 str=['cp -r ' newDir ' ' archDir lastDir];
%                 disp(str);
%                 system(str);
%             end;
%         else
%             disp(newDir);
%            rlCheckDefaultPipelineVersion(newDir);
%         end;
%     end;
% end;


% __________
% 
% 
d=dir(theDir);
for i=3:numel(d)
    if d(i).isdir
        dirName=d(i).name;
        [~,lastDir]=ParsePath(theDir);
        newDir=[AddSlash(theDir) dirName];

        % disp(dirName);
        if strncmp(dirName,'job',3)

            d1=dir(newDir);
            for j=3:numel(d1)
                if ~d1(j).isdir && strcmp(d1(j).name,'default_pipeline.star')
                    f=fopen([AddSlash(newDir) d1(j).name]);
                    if f>0 && ~feof(f)
                        l1=fgetl(f);
                        if ~feof(f)
                            l2=fgetl(f);
                            % if strndcmp(l2,'30001',5)
                            if strndcmp(l2,'0001',4)
                                str=[lastDir ' ' dirName ' ' d1(j).name ' ' l2 ' ' d1(j).date];
                                disp(str);
                            end;
                        end;
                    end;
                    if f>0 
                        fclose(f);
                    end;
                    break;
                end;
            end;
        else
            % disp(newDir);
            rlCheckDefaultPipelineVersion(newDir);
        end;
    end;
end;