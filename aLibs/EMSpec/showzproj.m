function showzproj(map);
% Show the z-projection of the 3D map.

p=squeeze(sum(shiftdim(map,2)));
imacs(p)
