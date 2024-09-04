function shortName=rlShortenEPUName(baseName)
    strs=split(baseName,'_');
    ns=numel(strs);
    isNum=zeros(ns,1);
    for k=1:ns
%        isNum(k) = numel(str2num(strs{k}))>0;
        ch=strs{k}(1);
        isNum(k) = ch>='0' && ch<='9'; % first character is numeric.
    end;
    p=find(isNum,2,'last');
    if numel(p)<2
        disp(['Not enough numerics in ' baseName]);
        shortName=baseName;
    else
    shortName=[strs{p(1)} '_' strs{p(2)}];
    end;
end
