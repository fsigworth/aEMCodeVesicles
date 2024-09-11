% ModifyMembraneDensityPrestin.m
% Model to map of Prestin, then reduce the TM density to about half.
pdbName='~/Structures/Prestin/7sun.pdb';
miName='~/Structures/kv1.2/KvMembraneModel_mi.txt';
[coords, types]=ReadPDBAtoms(pdbName);
mi=ReadMiFile(miName);
tic
[totalDens, protDens]=SolventAndProteinDensity(coords, types);
toc
solDens=(totalDens-protDens-totalDens(1))/totalDens(1); % subtract the background water dens.
%  protein will be at -1.

%%

n=size(totalDens,1);  % it's 136
n1=200; % final box size
pixA1=1.068; % final pixel size

md0=Crop(mi.vesicleModel,n);
md0f=GaussFilt(md0,.04);
figure(2);
clf;
plot([md0,md0f]);

figure(3);
md=DownsampleGeneral(md0f,n,mi.pixA); % expand to 1 A/pixel
mbn=shiftdim(repmat(md,[1 n n]),1);
mbns=circshift(mbn,[0 0 -13]); % shift the membrane center down
modDens=protDens.*(1-0.45*mbns.*(-solDens));
%%
m=DownsampleGeneral(modDens,200,1/pixA1);
figure(1);
ShowSections(m);
fc=.1*pixA1;
dfc=fc*1.5;
mf=SharpFilt(m,fc,dfc); % filter at 10 Å
figure(3);
ShowSections(mf);
mfx=Crop(mf,256);
%%
WriteMRC(m,pixA1,'PrMapSub1A3A.mrc');
WriteMRC(mf,pixA1,'PrMapSub1.068A10A.mrc');
WriteMRC(mfx,pixA1,'PrMapSub1.068A10A256p.mrc');
