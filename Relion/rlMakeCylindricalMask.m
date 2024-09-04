% rlMakeCylindricalMask
% Make a cylindrical mask e.g. for TM region

% cd '/Users/fred/Documents/Documents - Katz/EMWorkOnDocs/20230915/';
referenceMap='Refine3D/job077/run_class001.mrc'
% referenceMap='Import/job065/KvRef_2.136p128+micelle.mrc'
outputDir = 'MskTM/';
CheckAndMakeDir(outputDir,1);

outBaseName='Cyl'
note='_For_TM_looser'
doWrite=1;


% volume size
n=128;
ctr=ceil((n+1)/2);
msk=zeros(n,n,n,'single');

% Kv TM region
% "radii" in the z and xy directions:
rz=11;
rxy=35;
zCtr=128-45;
cone=0;

% % Kv T1 and beta subunits
% rz=24;
% rxy=24;
% zCtr=46;
% 
% cone=-.4;


rise=8; % feathering
pad=rise/2; % padding

% Make the z function and xy function
fz=fuzzymask(n,1,rz+pad,rise,zCtr);
fxy=fuzzymask(n,2,rxy+pad,rise); % take the default origin in the center.

for iz=1:n
    if cone ~=0
        fxy=fuzzymask(n,2,rxy+pad+cone*(iz-ctr),rise);
    end;
    msk(:,:,iz)=fxy*fz(iz);
end;

%outName=sprintf('%s%sn%gr%gzc%gz%gco%gp%gf%g%s%s',outputDir,outBaseName,n,rxy,zCtr,rz,cone,pad,rise,note,'.mrc');
outName=sprintf('%s%sn%gr%gzc%gs%s%s',outputDir,outBaseName,n,rxy,zCtr,note,'.mrc');
disp(outName);

pixA=2.136

if doWrite
    WriteMRC(msk,pixA,outName);
else
    disp('  not written.');
end;

% m=ReadMRC('Refine3D/job035/run_class001.mrc');
m=ReadMRC(referenceMap);
figure(10);

ShowSections(m,[],45);
%%
dc=.01;
% dc=.01;
figure(3);
ShowSections((m+dc).*(msk+.5),[ctr,ctr,zCtr],45);