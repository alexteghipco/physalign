function listing = dir2(varargin)

if nargin == 0
    name = '.';
elseif nargin == 1
    name = varargin{1};
else
    error('Too many input arguments.')
end

listing = dir(name);

inds = [];
n    = 0;
k    = 1;

while n < length(listing) && k <= length(listing)
    if any(strcmp(listing(k).name, {'.', '..','.DS_Store','99.PhoenixZIPReport','1.localizer_LR','Phsyio','LOG.txt'}))
        inds(end + 1) = k;
        n = n + 1;
    end
    k = k + 1;
end

listing(inds) = [];