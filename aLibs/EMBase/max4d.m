function [val,i,j,k,l]=max4d(m)
% find the maximum value and its indices in a 4-dimensional array.
%
[x,i0]=max(m);
[y,j0]=max(x);
[z,k0]=max(y);
[val,l]=max(z);
k=k0(1,1,1,l);
j=j0(1,1,k,l);
i=i0(1,j,k,l);
