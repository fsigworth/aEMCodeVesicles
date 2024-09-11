% startup.m
% vesicle-fitting version
% Put this script somewhere where Matlab will look on startup, e.g. in home
% folder or in ~/Documents/MATLAB
% It loads the library paths.

host=getenv('HOSTNAME');
homePath='~/';
basePath='~/aEMCodeVesicles/'; % We asssume that the code is here.

disp([which('startup') ' on ' host]);
disp(['  from the library ' basePath]);

cd(homePath);
folders={['aLibs' filesep 'EMBase']
         ['aLibs' filesep 'EMCCD']
         ['aLibs' filesep 'EMIO']
         ['aLibs' filesep 'EMIOUtils']
         ['aLibs' filesep 'EMSpec']
         ['aLibs' filesep 'GriddingLib']
         'MultiExposure'
         'Relion'
         'RSC'
         'RSC-Apps'
         'RSC-utilities'
         'RSCPicking'
         'RSCVesicleFinder'
         'RSCAnalysis'
        };

for i=1:numel(folders)
    addpath([basePath folders{i}]);
end;

% skipped modules
         % 'RSCReconstruct'
         % 'RSCSimulate'
         % 'Realtime'
         % 'AMPAR'
         % 'Kv'
         % ['aLibs' filesep 'Others']
         % 'EMClass'
         % 'FourierReconstruction'
%         ['aLibs' filesep 'Others' filesep 'bfmatlab']
%          'RSCAdaptiveBasis'
%          'RSCAdaptiveBasis/utils'
%          'K2Camera'
%         ['aLibs' filesep 'MEX'   ]   
         
