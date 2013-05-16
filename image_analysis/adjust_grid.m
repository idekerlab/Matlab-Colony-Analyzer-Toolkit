%% Adjust Grid
% Gordon Bean, December 2012

function grid = adjust_grid( plate, grid, varargin )
    params = default_param( varargin, ...
        'adjustmentWindow', round(grid.dims(1)/8), ...
        'fitfunction', @(r,c) [ones(numel(r),1) r(:) c(:)], ...
        'numMiddleAdjusts', 1, ...
        'numFullAdjusts', 1 );
    aw = params.adjustmentwindow;
    
    if isfield(params, 'rowcoords') && isfield(params, 'colcoords')
        grid = minor_adjust_grid( plate, grid, ...
            params.rowcoords, params.colcoords );
    else
        for iter = 1 : params.nummiddleadjusts
            %% Adjust internal spots

            rrr = grid.dims(1)/2 - aw : grid.dims(1)/2 + aw + 1;
            ccc = grid.dims(2)/2 - aw : grid.dims(2)/2 + aw + 1;

            grid = minor_adjust_grid( plate, grid, rrr, ccc );

        end

        %% Final adjustment
        for iter = 1 : params.numfulladjusts
            rrr = round( linspace( 1, grid.dims(1), 2*aw ) );
            ccc = round( linspace( 1, grid.dims(2), 2*aw ) );

            grid = minor_adjust_grid( plate, grid, rrr, ccc );
        end
    end
    
    %% Extras
    grid.win = round(median(diff(grid.c( grid.dims(1)/2, :))));
    
    grid.info.theta = pi/2 - atan2 ...
        ( grid.factors.row(2), grid.factors.row(3) );
    
    grid.info.fitfunction = params.fitfunction;
    
    %% ---- Subroutines ---- %%
    function [grid fitfact] = minor_adjust_grid( plate, grid, rrr, ccc )
        grid0 = grid;
        dims = grid.dims;
        win = grid.win;
        
        [rtmp ctmp] = deal( nan(size(grid.r)) );

        for rr = rrr(:)'
            for cc = ccc(:)'
                [rtmp(rr,cc) ctmp(rr,cc) ] = adjust_spot ...
                    (plate, grid.r(rr,cc), grid.c(rr,cc), win);
            end
        end

        %% Estimate grid parameters
        iii = in(~isnan(rtmp) & ~isnan(ctmp));
        [cc, rr] = meshgrid( 1 : dims(2), 1 : dims(1) );
        Afun = params.fitfunction;
        
        rfact = Afun(rr(iii),cc(iii)) \ rtmp(iii);
        cfact = Afun(rr(iii),cc(iii)) \ ctmp(iii);

        grid.factors.row = rfact;
        grid.factors.col = cfact;
    
        %% Compute grid position
        grid.r = reshape(Afun(rr(:),cc(:)) * rfact, size(grid.r));
        grid.c = reshape(Afun(rr(:),cc(:)) * cfact, size(grid.r));
        
        %% Estimate convergence
        fitfact = abs(grid.r(1,1) - grid0.r(1,1));
        
    end
    
    function [rpos cpos] = adjust_spot( plate, rpos, cpos, win )
        
        box = get_box( plate, rpos, cpos, win );
%         [~, off] = measure_size_and_offset( box );
        off = measure_colony_offset( box );
%         off = round(off);
        
        if (any(off > win/2))
            error('Offset too large - %s', ...
                'the adjustment window may need to be smaller.');
        end
        if (isnan(off))
            rpos = nan;
            cpos = nan;
        else
%             rpos = rpos + off(2);
%             cpos = cpos + off(1);
            rpos = rpos + off(1);
            cpos = cpos + off(2);
        end        
    end

end