
function out=GaussInverseFilt(in, pixA, B, fc)
% Filter function is
% h=exp(B*f^2/4) * (1-erf((f-fc)/w);


m=size(in);
numDims=sum(m>1);

f0=fc*pixA; % normalized frequency
k=1.782./(f0/10); % fw is f0/10

switch numDims
    case 1
        disp('GaussInverseFilt: dimension 1 is not supported.')
        return;
    case 2
        r=fftshift(RadiusNorm(m));
    case 3
        m1=m(1); % assume it's cubic
        r=fftshift(Radius3(m1)/m1);
    otherwise
        disp(['GaussInverseFilt: dimension ' num2str(numDims) ' is not supported.']);
end;
hg=exp(B/4*(r/pixA).^2) ;
h=0.5*hg.*(1-erf(k*(r-f0)));
fq=h.*fftn(in);
if isreal(in)
    out=real(ifftn(fq));
else
    out=ifftn(fq);
end;

