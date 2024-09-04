function mb=ImageArray2(m,pars)
% function mb=ImageArray(m, pars)
% Create a big array mb into which the stack of images m is tiled.
% 
% Set doNorm=1 if you want each image to have its pixel variance normalized to 1.
% borderWidth is the border width between tiles;
% nxi and nyi are the number of tiles in the x and y directions.
% borderVal is the value in the border between tiles (default max(m(:))).
% flipX and flipY control the arrangement of tiles.

if nargin<2
    pars=struct;
end

defPars=struct;
defPars.doNorm=0;
if ndims(m)>3 % already sorted into rows and columns
    [nx ny nxi nyi]=size(m);
    defPars.nxi=nxi;
    defPars.nyi=nyi;
    nim=nxi*nyi;
else
    defPars.nxi=0;
    defPars.nyi=0;
    [nx ny nim]=size(m);
end;
defPars.borderValue=inf;
defPars.borderWidth=1;

defPars.flipX=0;
defPars.flipY=0;

pars=SetOptionValues(defPars,pars,1);


if pars.borderValue == inf % i.e. not set
    if pars.doNorm
        pars.borderValue=2;
    else
        pars.borderValue=max(m(:));
    end;
end;
if pars.nxi==0
    pars.nxi=max(1,ceil(sqrt(nim)));
    end;
if pars.nyi==0
    pars.nyi=ceil(nim/pars.nxi);
end;


% Big array to receive the values
mb=ones(pars.nxi*nx+(pars.nxi-1)*pars.borderWidth,...
        pars.nyi*ny+(pars.nyi-1)*pars.borderWidth,'single')*pars.borderValue;

for iy=1:pars.nyi % 
    if pars.flipY
        y0=(pars.nyi-iy)*(ny+pars.borderWidth); % scan down from the top
    else
        y0=(iy-1)*(ny+pars.borderWidth); % we scan up from the bottom
    for ix=1:pars.nxi
        index=ix+pars.nxi*(iy-1); % index into the stack
        if index > nim
            continue;
        end;
            if pars.flipX
                x0=(pars.nxi-ix)*(nx+pars.borderWidth);
            else
                x0=(ix-1)*(nx+pars.borderWidth); % we scan left to right
            end;
            mp=m(:,:,index);
            if pars.doNorm
                mp=normalize(mp);
            end;
                mb(x0+1:x0+nx,y0+1:y0+ny)=mp;
        end;
    end;
end;
% pars
end

function out=normalize(in)
me=mean(mean(in));
in=in-me;
var=sum(sum(in.^2))/numel(in);
out=in/sqrt(var);
end
