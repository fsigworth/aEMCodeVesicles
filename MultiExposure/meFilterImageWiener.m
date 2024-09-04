function [mf mfc]=meFilterImageWiener (mc, effctf, pixA, kWiener, fc)
% [mf mfc]=meFilterImageWiener(mc,effctf,mcpixA,kWiener,fc)

% function [mf mfc]=rsFiltering(mc,effctf,pixA,kWiener,fc)
% Perform Wiener filtering, and if desired low-pass filtering, to the
% composite image mc having the given effective ctf.  pixA is the pixel
% size of mc.  kWiener is the Wiener filter constant; a typical value is
% .04 (5x maximum magnification).  fc is the low-pass filter frequency in
% A^-1.

if nargin<5
    fc=0;
end;

n=size(mc,1);

% Wiener filter
fmc=fftshift(fftn(mc));
% mcw=real(ifftn(fftshift(fmc.*effctf./(kWiener+effctf.^2))));
fmc=fmc.*effctf./(kWiener+effctf.^2);

if fc>0  % Make the low-pass filter
    fw=1/5;  % relative width of sharp-filter transition
    [x,y]=ndgrid(-n/2:n/2-1);
    r=sqrt(x.^2+y.^2)/(fc*pixA*n);
    fmc=fmc.*(1-erf((r-1)/fw))/2;
end;
mf=real(ifftn(fftshift(fmc)));

if nargout>1  % We want the crystal pattern removed too.
    fmax=.1;  % maximum spatial frequency of interest, in A^-1
    ds0=1/(fmax*pixa);
    ds=NextNiceNumber(ds0/2,2,-1);  % downsample factor, a power of 2.
    ds
    ns=n/ds;
    
    sp=abs(Crop(fmc,ns)).^2;  % zero-centered spectrum
    [spc pmask]=RemoveSpots(sp,.8*n*pixA/58,5,1);
    %
    gmask=1-Crop(1-pmask,n);  % expand the spot mask
    % msk=(fuzzymask(n,2,n/ds0,n/ds0*.1));  % inverse overall Fourier mask
    % pmaskc=msk.*pmask+(1-msk);  % place the spot mask into the overall mask.
    % % imacs(pmaskc); drawnow;
    % fmask=1-Crop(1-pmaskc,ns);  % fourier mask for image.
    mfc=real(ifftn(fftshift(fmc.*gmask)));
end;
