function [m,frac]=FractionOverlaps(mi);
% Compute the total overlapped fraction of vesicles in a micrograph, based
% on information in an mi structure. The returned image m
% shows discs for vesicles, with pixel values >1 indicating overlaps.
% m is 1/8 the size of the original micrograph.
    thk=4; % nominal membrane thickness
    minRadius=100;
    maxRadius=400;
    ds=8;  % downsampling from original image
    
    n=mi.padImageSize/ds;
% Set the default return values
    frac=0;
    m=zeros(n,'single');
    
    nv=numel(mi.vesicle.x); % number of vesicles
    if nv<1
        return
    end;
    
     mi.vesicle.ok(:,2)=mi.vesicle.ok(:,2) & ...
         mi.vesicle.s(:,1)>0.5*median(mi.vesicle.s(:,1)) & ...
        mi.vesicle.r(:,1)>minRadius & mi.vesicle.r(:,1)<maxRadius;
    goodVes=(mi.vesicle.ok(:,2));
    goodVesInds=find(goodVes);
    if numel(goodVesInds)>0
        m=meMakeModelVesicleDiscs(mi,n,goodVesInds,thk);
        m=m.*meGetMask(mi,n);
        frac=sum(m(:)>1)/sum(m(:)>0.5);
    else
        m=zeros(n,'single');
        frac=0;
    end;
end
%         imags(v1);
%         drawnow;
        
