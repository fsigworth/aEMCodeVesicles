function [hist, norm]=WeightedHisto(indices, weights, nbins)
% function [hist norm]=WeightedHisto(indices, weights, nbins)
% Uses all elements of 'indices' to direct the summing of all elements of
% all dimensions of 'weights' into bins.
% The returned 'norm' array gives the number of entries summed into
% each bin, which can be used for normalization. 'norm' is therefore a
% histogram of the 'indices'.  Indices out of bounds (<1, >nbins) are not used
% at all.
% This function calls the lower-level mex function WtHist.
% 
% -Maybe this function is redundant; the operations can be done with accumarray()
%  i.e. hist=accumarray(indices,weights,nbins);
%       norm=accumarray(indices,1,nbins);

if numel(weights) ~= numel(indices)
    error('indices and weights must have the same number of elements.');
end;

nb=int32(nbins);
ind=int32(indices);
ok=ind>0 & ind<nb; % ignore out-of-bounds indices
ind=ind(ok);

% code for calling the .mex function
% if isreal(weights)
    % [hist, inorm]=WtHist(ind, double(weights(:)), nb);
    % if nargout>1
    %     norm=double(inorm);
    % end;
%else  

  % m-code for WtHist. This runs almost as fast as the C-code .mex function
    hist=zeros(nb,1);
    norm=zeros(nb,1);
    if nbins < 1
        return
    end;
    
    for i=1:numel(ind)
        k=ind(i);
        hist(k)=hist(k)+weights(i);
        norm(k)=norm(k)+1;
    end;
% end;

