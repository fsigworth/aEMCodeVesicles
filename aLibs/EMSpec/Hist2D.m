function img=Hist2D(n,zs,minz,maxz)
% lims=(xmin ymin; xmax ymas];)


ix=round((zs(:,1)-minz(1))*n/(maxz(1)-minz(1))+.5);
ix=max(1,min(ix,n));
iy=round((zs(:,2)-minz(2))*n/(maxz(2)-minz(2))+.5);
iy=max(1,min(iy,n));

img=zeros(n,n);
for i=1:numel(ix)
    img(ix(i),iy(i))=img(ix(i),iy(i))+1;
end;
