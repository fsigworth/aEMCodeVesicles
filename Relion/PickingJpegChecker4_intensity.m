% PickingJpegChecker4_intensity
% Assign peak intensities to mi.ok(2:6)
% being percentiles x/3 to x, with x=10^y, y=[-3 -2.5 -2 -1.5 -1]
jpegDir='Picker_jpegs/';
inMisName='Picking_9/allMis_holemasked_i+f_7505.mat';
outMisName='Picking_9/allMis_holemasked_i2+f.mat';
imgPath='Merged_sms/';

outMis=allMis;

ds1=8; % downsampled from 4x downsamlpled small image
ds2=16;
pcExponents=[-3 -2.5 -2 -1.5 -1];
npc=numel(pcExponents);
boostVal=30;

mMul=200; % image display scale

%  assume we've loaded fracs, to look at fractional overlaps.
% % disp(['Loading ' inMisName]);
% % load(inMisName); % allMis
% % nmi=numel(allMis);

figure(1);
set(1,'color',[.4 .4 .4]);
set(1,'menu','none');
set(1,'toolbar','none');
% inds=find(rej);
% inds=1:numel(fracs);
inds=1:numel(allMis);
nin=numel(inds);
disp([num2str(nin) ' indices']);
iptr=1;
b='0';
    intens=zeros(nin,npc);
    defoci=zeros(nin,1);
    nParts=zeros(nin,1);
while iptr<nin
    
    ind=inds(iptr);
    mi=allMis{ind};
    defoci(ind)=mi.ctf.defocus;
    if isfield(mi,'particle') && isfield(mi.particle,'picks')
        nParts(ind)=size(mi.particle.picks,1);
    end;
    %     allMis{ind}.active=true;
    
    %     jpegName=[jpegDir mi.baseFilename '_i0.jpg'];
    %     %         tstr=sprintf('%04d file: %05d   def: %5.2f   res: %6.2f   FOM: %6.3f',...
    %     %             iptr,ind,mi.ctf.defocus, mi.ctf.resLimit,mi.ctf.ccc);
    %     if exist(jpegName,'file')
    %         im=imread(jpegName);
    %         subplot(121);
    %         image(im);
    %     else
    % %         disp([num2str(ind) ' not found: ' jpegName]);
    % %         imags(zeros(768));
    %         tstr='';
    %     end;
    pcs=zeros(2,npc);
    spcs=pcs;
    micName=[imgPath mi.baseFilename 'ms.mrc'];
    if exist(micName,'file')
        m0=ReadMRC(micName)/mi.imageNormScale+mi.imageMedian;
        msk=meGetMask(mi,size(m0));
        fracUnmasked=sum(msk(:))/numel(msk);

        m0=m0.*msk+mi.imageMedian*(1-msk);
        n0=mi.padImageSize;
        n1=n0/ds1;
        n2=n0/ds2;
        %         m0c=Crop(m0,mi.padImageSize,0,mean(m0(:)));
        m1=GaussFilt(Downsample(m0,n1),.1);
        m2=GaussFilt(Downsample(m1,n2),.1);
        subplot(221);
        imaga((m1-mi.imageMedian)*mMul+128);
        title(ind);
        mx=m2(:);
        k=1;
        subplot(222);
        [mSort,iSort]=sort(mx,'descend');
        nmx=numel(mx);
        for j=1:npc
            pct=(10^pcExponents(j))/fracUnmasked;
            if pct>1 % Fewer pixels than the percentage.
                break
            end;
            range=round(nmx*pct/3.1):round(nmx*pct);
            pcs(k,j)=mean(mSort(range));
            
            spcs(k,j)=std(mSort(range));
            mxMarked=mx;
            mxMarked(iSort(range))=mxMarked(iSort(range))+boostVal;
            
            mx2=reshape(mxMarked,sqrt(nmx)*[1 1]);
            if j==3 && k==1
                imags(mx2);
                title(num2str([k pct*100 pcs(k,j)]));
            end;
        end;
        intens(ind,:)=pcs(1,:);
        mi.ok(11:10+npc)=pcs(1,:)';
        outMis{ind}=mi;
        subplot(223);
        plot(defoci);
        subplot(224);
        plot(nParts);
        drawnow;
        
    end; % if exist
    iptr=iptr+1;
    %     else
    %         cla;
end;

oldAllMis=allMis;
%%
allMis=outMis;
disp(['Writing ' outMisName '...']);
save(outMisName,'allMis');
disp('done.');
allMis=oldAllMis;

return


% % 
% % tstr=sprintf('%04d %4d %4d',iptr,round(pcs(1,1)*100), round(spcs(1,1)*100));
% % allMis{ind}.ok(11:numel(pcs)+10)=pcs(:);
% % subplot(121);
% % title(tstr,'fontsize',16,'fontweight','normal','color','w');
% % drawnow;
% % disp(tstr);
% % 
% % if b~='R'
% %     [x,y,b]=ginput(1);
% % end;
% % switch char(b)
% %     case 'i'
% %         tptr=MyInput('Pointer value ',iptr);
% %         iptr=tptr-1;
% %     case 'j' % junk
% %         allMis{ind}.active=false;
% %         fprintf(' X\n');
% %     case 'p' % go to previous
% %         iptr=iptr-2;
% %     case 'q' % quit (and set active=1...)
% %         break;
% % end;
% % iptr=iptr+1;
% % if iptr<1
% %     beep
% %     ind=1;
% % end;
% % % end;
% % 
% % disp('Done.');
% % return
% % %%
% % 
% % % Set the active flags
% % for i=1:nmi
% %     mi=allMis{i};
% %     mi.active=~rej(i);
% %     allMis{i}=mi;
% % end;
% % 
% % % save the allMisSel.mat
% % disp('Saving allMis8_sel.mat');
% % save allMis8_sel.m allMis
% % 
% % %%
% % % save the individual mi files
% % infoDir='Info8_sel/';
% % CheckAndMakeDir(infoDir,1);
% % for i=1:nmi
% %     mi=allMis{i};
% %     miName=[infoDir mi.baseFilename 'mi.txt'];
% %     WriteMiFile(mi,miName);
% %     if mod(i,1000)==0
% %         disp([num2str(i) ' ' miName]);
% %     end;
% % end;
% % 
% % % store all the mi files
