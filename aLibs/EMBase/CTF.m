function h = CTF(n, pixA, lambda, defocus, Cs, B, alpha, deltadef, theta)
% f = CTF(n, pixA, lambda, defocus, Cs, B, alpha, deltadef, theta)
% f = CTF(n, pixA, Pars);  % Pick up the CTF parameters from the struct Pars
% f = CTF(n, Pars);  % use the Pars.pixA field too.
% Compute the contrast transfer function corresponding an n x n image with
% the sampling interval pixA in A/pixel.  Lambda is in A, Cs is in mm,
% B in A^2 and alpha is in radians.  Defocus is in microns.  The last two
% arguments are optional.
% Alternatively, a struct Pars containing each of these fields is passed:
% pixA (optional); lambda, defocus, Cs, B, alpha, deltadef, theta.
%
% The CTF is computed with astigmatism if the struct (or argument list) has
% two additional fields, deltadef (in microns) and theta (in radians).
%
% The result is returned in an nxn matrix with h(n/2+1,n/2+1) giving
% the zero-frequency amplitude.  Thus you must use ifftshift() on
% the result before performing a Fourier transform.  For example,
% to simulate the effect of the CTF on an image m, do this:
% fm=fftshift(fft2(m));
% cm=ifft2(ifftshift(fm.*ctf()));
%
% The first zero occurs at lambda*defocus*f0^2=1.
% e.g. when lambda=.025A, defocus=1um, then f0=1/16�A.

% Cs term fixed.  fs 4 Apr 04
% Struct option added fs 6 Jul 09
% Astig option added fs 18 Aug 09
% Changed B factor to include 1/4, i.e. exp(-Bf^2/4)

astig=0;
cuton=0;
if isstruct(pixA)  % 2nd argument is a structure
    lambda=pixA;
    pixA=lambda.pixA;
end;
if isstruct(lambda) % 3rd argument is a structure
    P=lambda;
    lambda=P.lambda;
    defocus=P.defocus;
    Cs=P.Cs;
    B=P.B;
    alpha=P.alpha;
    if isfield(P,'deltadef')  % we are handling astigmatism
        deltadef=P.deltadef;
        theta=P.theta;
        if deltadef ~= 0
            astig=1;
        end;
    end;
        if isfield(P,'cuton')
            cuton=P.cuton;
        end;
        if isfield(P,'phi')
            alpha=max(alpha, P.phi);
        end;

elseif nargin>7 % we have astig parameters
        astig=1;
end;

if astig
    [r1, ang]=RadiusNorm(n,fctr(n));
    % we use the defocus formula from Henderson '86:
    df=defocus+deltadef*cos(2*(ang-theta));
else
    r1=RadiusNorm(n,fctr(n));
    df=defocus;
end;
r2=r1.^2;
f0 = 1./pixA;  % Spatial frequency unit (inverse �)

k2=-df*pi*lambda*1e4*f0.^2;  % this may be a matrix
k4= pi/2*Cs*lambda^3*1e7*f0.^4;  % this is a scalar.
kr=f0^2*B/4;  % B-factor

if Cs==0
    h=sin(k2.*r2-alpha).*exp(-kr*r2);
else
    h=sin(k2.*r2+k4*r2.*r2-alpha).*exp(-kr*r2);
end

if cuton  % handle sharp cut-on of a phase plate.
    h=h.*(0.5+0.5*erf((r1*f0-cuton)*10/cuton));
end;
