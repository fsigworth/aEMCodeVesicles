function [val,i,j]=max2d(m)
% function [val,i,j]=max2d(m)
% find the maximum value and its indices in a 2-dimensional array.
%
[x,i0]=max(m);
[val,j]=max(x);
i=i0(1,j);
