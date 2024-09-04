function m=RotMatrix2(theta)
% function m=RotMatrix2(theta)
% Compute m such that m*v1 takes the vector v1 into a vector rotated ccw 
% by theta, in radians.

c=cos(theta);
s=sin(theta);
m=[c -s; s c];
%
% %%%% New coordinate system [x';y']=m*[x;y] ccw rot of coordinates
% m=[c s -s c]
