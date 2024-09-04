function [c,mantissa]=ExponentToChar(x)
% function [c,mantissa]=ExponentToChar(x)
% From a real value x, e.g. 2.8e-8 amperes, determine the ISO character to
% construct a string such as 28nA as [num2str(mantissa) c 'A']
chars='afpnum kMGT';
startExponent=-6; % minimum value is 1e-18 = atto
p=floor(log10(x)/3)+1;
ind=min(max(1,p-startExponent),numel(chars));
c=chars(ind);
if c==' '
    c='';
end;
mantissa=x*10^(3*(1-ind-startExponent));
% disp([num2str(mantissa) c]);
