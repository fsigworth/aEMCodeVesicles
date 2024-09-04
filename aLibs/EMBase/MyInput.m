function val=MyInput(text,val)
% function val=MyInput(text,val)
% Input a numeric value.
% Returns val if nothing was typed.
% Example: x=MyInput('What value',0); % gives the prompt
%  What value [0]?
% This function can accept any numeric Matlab expression as it uses the 
% str2num function. Examples of allowable entries are
% 1:3
% [1:3]
% cos(1)
% exp(1i*pi/2)

str=input([text ' [' num2str(val) ']? '],'s');
if numel(str)==0
    return
else
    newVal=str2num(str);
    if numel(newVal)>0
        val=newVal;
    end;
end;
