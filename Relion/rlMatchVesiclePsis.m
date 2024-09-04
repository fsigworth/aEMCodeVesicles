% rlMatchVesiclePsis.m
% Simpified version of rlMatchVesicleAngles, where the vesicle psi angles
% are found in the particle.star file (preserved by Relion3.1 ff)

suffix='';
minTilt=20;


% Load a particles.star file, may contsain a selected subset from Refine3D etc.

% pStarPath='Select/job177/';
% pStarPath='Refine3D/job255/';
pStarPath='Class3D/job027/';
suffix='_unsub';
pStarName=[pStarPath 'run_it020_data' suffix '.star'];
% pStarName=[pStarPath 'particles.star'];
% pStarName=[pStarPath 'run_data.star'];

outPath=pStarPath;
disp(['Reading ' pStarName]);

[pnm,pdat]=ReadStarFile(pStarName);
pts=pdat{2};
nParticles=numel(pts.rlnMicrographName);

%%
psis=pts.rlnAnglePsi;
vesPsi=pts.rsVesiclePsi;
tilts=pts.rlnAngleTilt;
tiltOk=tilts>minTilt & tilts<180-minTilt;
psiDiff=mod(-vesPsi-psis+90,360);
iso=psiDiff<180 & tiltOk;
rso=psiDiff>180 & tiltOk;

% figure(5);
% hist(tilts,bins(1:4:round(nBins/2)));
% xlabel('Tilt angle');
%
figure(4);
PlotHistograms(pts,1:max(pts.rlnClassNumber),rso,iso,psiDiff,pStarName);

ok=true;
while ok
    ok=MyInput('Write star files? ',0);
    if ok
        path=input(['output file path [''' outPath ''']?']);
        if numel(path)>0
            outPath=AddSlash(path);
            CheckAndMakeDir(outPath,1);
        end;
        classSel=MyInput('Classes or 0 (=all)?',0);

        for selRSO=0:1
            if selRSO
                orString='rso';
                orFlags=rso;
            else
                orString='iso';
                orFlags=iso;
            end;
            if all(classSel)==0
                clsString='all';
                flags=true(nParticles,1) & orFlags;
            else
                clsString=sprintf('%u',classSel);
                flags=any(pts.rlnClassNumber==classSel,2) & orFlags;
            end;

            numParticles=sum(flags);
            outStarName=['particles_' orString '_t' num2str(minTilt) '_' clsString suffix '.star'];
            figure(5);
            PlotHistograms(pts,classSel,rso,iso,psiDiff,outStarName);

            outName=outStarName;
            hdrText=['# version 30001, ' orString ' particles, class ' clsString ' from ' pStarName];
            totalParticles=sum(flags);
            disp(['Header text: ' hdrText]);
            disp([num2str(totalParticles) ' particles']);
            fullOutName=[outPath outName];
            disp(['Writing ' fullOutName]);
            WriteStarFile(pnm,pdat,fullOutName,hdrText,{[] flags});
        end;
    end;
end;
disp('done.');


function PlotHistograms(pts,classes,rso,iso,psiDiff,figName)
bins=0:4:359; % histo bins
nBins=numel(bins);
nParticles=numel(pts.rlnMicrographName);
nClasses=numel(classes);
h=zeros(nBins,nClasses);
fStr=sprintf('%%%uu',floor(log10(nParticles)+1)); % format string
clsSelections=cell(nClasses,1);
clsStrings=cell(nClasses,1);
allSel=false(nParticles,1);
for icls=1:nClasses
    clsNum=classes(icls);
    clsString=['Class ' num2str(clsNum)];
    % if nClasses>1
    sel=pts.rlnClassNumber==clsNum;
    allSel=allSel | sel;
    clsSelections{icls}=sel;
    clsStrings{icls}=clsString;
    % else;
    %     clsStrings{1}=clsString;
    %     sel=true(size(pts.rlnMicrographName)); % select everything
    % end;

    %      psis=pts.rlnAnglePsi(sel);
    %      vesPsi=pts.rsVesiclePsi(sel);
    %      psiDiff=mod(-vesPsi-psis+90,360);
    h(:,icls)=hist(psiDiff(sel),bins);
    fprintf(['%s ' fStr ' iso ' fStr ' rso, fraction %.3f \n'],clsString,sum(iso(sel)),sum(rso(sel)),sum(rso(sel))/sum(sel));
end;

bar(bins,h,'stacked');
% legend;
ylabel('Frequency')
xlabel('Psi angle difference');
title([num2str(sum(iso(allSel))) ' ISO     ' num2str(sum(rso(allSel))) ' RSO']);
legend(clsStrings);
set(gcf,'name',figName);
drawnow;

end



