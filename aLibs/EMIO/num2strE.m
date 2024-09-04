function str=num2strE(x,unitString, sigFigs)
% str=num2strE(x,unitString,sigFigs)
% Convert the numeric value x to engineering units. 
% unitString (default '') is the string to follow the 'k', 'M' etc.
% if unitString has a leading space, the space is moved before the 'k', 'M' 
% etc. instead.
% sigFigs is the number of significant figures, default 4, min value 3.
% Examples: 
% num2strE(1e5*pi,' V')    returns 314.2 kV
% num2strE(1e5*pi,'V',3)   returns 314kV
% num2strE(1e4*pi,'V',3)   returns 31.4kV

if nargin<2
    unitString='';
end;
if nargin<3
    sigFigs=4;
end;
sigFigs=max(3,sigFigs); % don't allow values less than 3 cuz can result in strange
% results, such as 3.1e+02kV !
[c,mantissa]=ExponentToChar(x);
if unitString(1)==' ' % a space
    c=[' ' c];
    unitString(1)=[];
end;
str=[num2str(mantissa,sigFigs) c unitString];
