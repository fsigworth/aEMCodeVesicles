% rlGetStackStats.m

% Scan the particle images, compusting statistics on each.
fcs=[0 .1 .02];
nFreqs=numel(fcs);
nStats=3;

inPath='Extract/job008/'; % 0205 particles;
%inPath='Select/job174/'; % 0321 from joined particles, 113k
%inName='particles_redir';
inName='particles';
starName=[inPath inName '.star'];
disp(['Reading ' starName]);
[nams,dats]=ReadStarFile(starName);
d=dats{2};
pNames=d.rlnImageName;
np=numel(pNames);
[slice,fName]=rlDecodeImageName(pNames{1});
[m,s]=ReadMRC(fName,slice,1);
n=size(m,1);
pixA=s.pixA

spectra=zeros(np,n/2,'single');
stats=zeros(np,nFreqs,nStats,'single');
imgSum=zeros(n,n,'single');
disp(['scanning ' num2str(np) ' particles; 20k per line']);

for i=1:np
    [slice,fName]=rlDecodeImageName(pNames{i});
    m=ReadMRC(fName,slice,1);
    imgSum=imgSum+m;
    % spectra(i,:)=RadialPowerSpectrum(m);
    for j=1:nFreqs
        if j>1
            mf=GaussFilt(m,fcs(j));
        else
            mf=m;
        end;
        stats(i,j,1)=max(mf(:));
        stats(i,j,2)=min(mf(:));
        stats(i,j,3)=std(mf(:));
    end;
    if mod(i,250)==0
        fprintf('.');
        if mod(i,20000)==0
            fprintf('\n');
        end;
    end
end;
%
fprintf('\n');
save([inPath inName 'stats.mat'],'stats','spectra');

%%
load([inPath inName 'stats.mat']);

thresholds=[5 2 .58
            -5.5 -1.8 -.45];
doWrite=0;

statCopy=stats;
fprintf('\n');

figure(1);
bads=false(np,1);
statCopy=stats;
for j=1:nStats
    mysubplot(nStats,1,j);
    plot(squeeze(stats(:,j,:)));

    thr1=thresholds(1,j);
    thr2=thresholds(2,j);

    highs=stats(:,j,1)>thr1;
    statCopy(highs,j,1)=thr1;
    lows=stats(:,j,2)<thr2;
    statCopy(lows,j,2)=thr2;

    bads=bads|highs|lows;

end;
inds=find(bads);
ni=numel(inds);
disp([num2str(ni) ' bad images.']);

% now show the truncated data.
for j=1:nStats
    mysubplot(nStats,1,j);
    plot(squeeze(statCopy(:,j,:)));
end;

% %% Show the bad images.
% figure(2);
% for ind=1:ni
%     showImage(inds(ind),pNames);
%     % pause(0.05);
%     drawnow;
% end;
% 

[pa,nm,ext]=fileparts(inName);
outName=[inPath nm '_pr' num2str(ni) '.star'];
disp(outName);


if doWrite
    WriteStarFile(nams,dats,outName,'',{[] ~bads});
end;
disp('done.')
%%
