% Gordon Bean, March 2011, February 2012

function [freq_out, bin_out] = comp_hist( x, nbins, varargin )
    nbins_ = 20;
    
    if (nargin == 1)
        nbins = nbins_;
    else
        if (ischar(nbins))
            varargin = [nbins varargin];
            nbins = nbins_;
        end
    end
    
    params = get_params( varargin{:} );
    if (~isfield( params, 'style' ))
        params.style = 'histogram';
    end
    if (~isfield( params, 'linewidth'))
        params.linewidth = 2;
    end
    
    switch lower(params.style)
        case 'histogram'
            % Get bins over whole range
            [~, bins] = hist(vect(x{:}),nbins);

            % Get counts in each bin for each data set
            counts = zeros(length(bins),length(x));
            for b = 1 : length(x)
                counts(:,b) = hist(x{b}, bins);
            end

            % Plot frequencies for each data set
            freqs = bsxfun(@rdivide, counts, sum(counts,1));
            bar( bins, freqs, 1 );

            if( nargout > 0)
                freq_out = freqs;
                bin_out = bins;
            end

        case 'density'
            % Get full domain
            [~, xx] = hist(vect(x{:}),nbins);
            
            % Get y-values
            yy = cell(length(x),1);
            for ii = 1 : length(x)
                yy{ii} = ksdensity( x{ii}, xx );
            end
            
            % Plot densities
            newplot; hold all;
            for ii = 1 : length(x)
                plot(xx, yy{ii}, 'linewidth', params.linewidth);
            end
            hold off;
            
            if (nargout > 0)
                freq_out = yy;
                bin_out = xx;
            end
            
        otherwise
            error('Unsupported style: %s', params.style);
            
    end
    
    %% Extra sub-routine
    function out = vect (varargin)
        for a = 1 : length(varargin)
            varargin{a} = varargin{a}(:);
        end
        out = cat(1, varargin{:});
        if (iscell(out)), out = out{:}; end
    end
end
