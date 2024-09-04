function s=structCopyFields(ref,refIndex,s,sIndex)
% Copy one element from each field of ref to the target struct s.

% ref.a=rand(10,1);
% ref.b=1:10;
% refIndex=2;
% s=struct;
% sIndex=2;

names=fieldnames(ref);
for i=1:numel(names)
    s.(names{i})(sIndex)=ref.(names{i})(refIndex);
end
