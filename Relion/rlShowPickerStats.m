% rlShowPickerStats.m

%  starName='Class2D/job022/run_it025_data.star';
% disp(['Loading ' starName]);
%  [nms,das]=ReadStarFile(starName);
%%
% for selecting half datasets:
dat=das{2};
amps=dat.rlnAutopickFigureOfMerit;
% selecting half datasets.
h=false(numel(amps),1);
h(1:496096)=true;
%h(496096:end)=true;
amps=amps(h);
spects=dat.rspAutopickNoiseVar(h);
classes=dat.rlnClassNumber(h);
defs=(dat.rlnDefocusU(h)+dat.rlnDefocusV(h))/2e4;



ampCs=[-.06 -.06];
dds=defs-2;
ampCorrs=1./(1+ampCs(1)*dds+ampCs(2)*dds.^2);

spectCs=[.344 -.0856];
spectCorrs=1./(1+spectCs(1)*dds+spectCs(2)*dds.^2);


mysubplot(221);
histogram(classes);
sum(classes==1)

mysubplot(222);
% histogram(defs);

modAmps=amps.*ampCorrs;
modSpects=spects.*spectCorrs;

% plot(defs,modSpects,'b.');

[minDefs,maxDefs]=Percentile(defs,.01);
[minModSpects,maxModSpects]=Percentile(modSpects,01);
[minModAmps,maxModAmps]=Percentile(modAmps,.01);
modAmps(modAmps<minModAmps | modAmps>maxModAmps)=NaN;
% modSpects(modSpects<minModSpects | modSpects>maxModSpects)=NaN;

img=Hist2D(64,[modAmps modSpects],[minModAmps minModSpects],[maxModAmps,maxModSpects]);
imacs(img);
title('x=Amps y=Spects');

[minAmp,maxAmp]=Percentile(modAmps,.01)
[minSpect,maxSpect]=Percentile(modSpects,.01)

mysubplot(223);
hist(modAmps,100);
mysubplot(224);
hist(modSpects,100);

%
% Sort according to class number
nCls=max(classes);
q=false(numel(modAmps),nCls);
for i=1:nCls
    sel=classes==i;
    q(1:numel(sel),i)=sel;
end;
classNums=sum(q,1);
nEntries=max(classNums);
[~,sortCls]=sort(classNums,"descend");
bestN=25;
bestCls=sortCls(1:bestN);

modAmpsCls=NaN(nEntries,bestN);
modSpectsCls=NaN(nEntries,bestN);
defsCls=NaN(nEntries,bestN);
for i=1:bestN
    flags=q(:,sortCls(i));
    lims=1:sum(flags);
    modAmpsCls(lims,i)=modAmps(flags);
    modSpectsCls(lims,i)=modSpects(flags);
    defsCls(lims,i)=defs(flags);
end;
mysubplot(221);
[hs,bins]=hist(defsCls,50);
bar(bins,hs,'stacked');
xlabel('defocus');
title('defocus');
legend;


mysubplot(223);
[hs,bins]=hist(modAmpsCls,50);
bar(bins,hs,'stacked');
xlabel('Amps');

mysubplot(224);
[hs,bins]=hist(modSpectsCls,50);
bar(bins,hs,'stacked');
xlabel('Spects');

nRSOs=sum(q(:,sortCls(1:5)))

return


