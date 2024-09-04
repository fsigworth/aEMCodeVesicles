
function ShowPartImage(ind,pNames)
fc=.2;
[slice,fName]=rlDecodeImageName(pNames{ind});
m=ReadMRC(fName,slice,1);
imags(GaussFilt(m,fc));
title(ind);

end


