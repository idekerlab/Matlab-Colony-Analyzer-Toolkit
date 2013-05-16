%% Auto Grid
% Gordon Bean, May 2013

function grid = auto_grid( plate, varargin )
    params = default_param( varargin, ...
        'midRows', [0.4 0.6], ...
        'midCols', [0.4 0.6], ...
        'midGridDims', [8 8], ...
        'minSpotSize', 10, ...
        'thresholdMethod', fast_local_fitted('fdr',0.01));
    
    %% Grid properties
    if isfield(params, 'gridspacing')
        grid.win = params.gridspacing;
    else
        grid.win = estimate_grid_spacing(plate);
    end
    
    if isfield(params, 'dimensions')
        grid.dims = params.dimensions;
    else
        grid.dims = estimate_dimensions( plate, grid.win );
    end
    
    [grid.r, grid.c] = deal(nan(grid.dims));
    
    %% Initial placement of grid
    range = @(a) fix(a(1)):fix(a(2));
    mid = plate( range(size(plate,1)*params.midrows), ...
        range(size(plate,2)*params.midcols) );

    itmid = params.thresholdmethod.determine_threshold(mid);

    stats = regionprops( imclearborder(mid > itmid), 'area', 'centroid' );
    cents = cat(1, stats.Centroid);
    areas = cat(1, stats.Area);
    cents = cents(areas > params.minspotsize,:);
    
    [~,mi] = min(sqrt(sum(cents.^2,2)));
    r0 = cents(mi,2);
    c0 = cents(mi,1);

    [cc0 rr0] = meshgrid(c0 + (1:params.midgriddims(2))*grid.win, ...
        r0 + (1:params.midgriddims(1))*grid.win);

    ri = (1 : size(rr0,1)) + 0;
    ci = (1 : size(cc0,2)) + 0;

    grid.r(ri,ci) = rr0 + size(plate,1)*0.4 ;
    grid.c(ri,ci) = cc0 + size(plate,2)*0.4 ;
    
    %% Adjustment and Extrapolation
    % I give it two rounds of fitting to improve accuracy
    rie = find(max(grid.r,[],2)+grid.win < size(plate,1),1,'last');
    cie = find(max(grid.c,[],1)+grid.win < size(plate,2),1,'last');
    
    grid = adjust_grid( plate, grid, 'rowcoords', 1 : min(ri(end),rie),...
        'colcoords', 1:min(ci(end),cie) );
    
    rie = find(max(grid.r,[],2)+grid.win < size(plate,1),1,'last');
    cie = find(max(grid.c,[],1)+grid.win < size(plate,2),1,'last');
    
    if rie > ri(end)*2 && cie > ci(end)*2
        grid = adjust_grid( plate, grid, ...
            'rowcoords', 1 : 2 : min(ri(end)*2,rie), ...
            'colcoords', 1 : 2 : min(ci(end)*2,cie) );
    end
    
    %% Determine grid/colony overlap
    eplate = nan(grid.dims);
    gbox = fspecial('gaussian',(2*round(grid.win/2)+1)*[1 1], grid.win/3);
    rmax = find( max(grid.r,[],2) < size(plate,1)-grid.win, 1, 'last' );
    cmax = find( max(grid.c,[],1) < size(plate,2)-grid.win, 1, 'last' );
    
    for rr = 1 : rmax
        for cc = 1 : cmax
            box = get_box(plate, ...
                grid.r(rr,cc), grid.c(rr,cc), grid.win/2);
            eplate(rr,cc) = corr(box(:), gbox(:));
        end
    end

    %% Determine offsets
    roff = find(nanmean(eplate,2) < 0.1, 1)-1;
    if isempty(roff)
        roff = find(nanmean(eplate,2)>0.1, 1, 'last');
    end
    coff = find(nanmean(eplate,1) < 0.1, 1)-1;
    if isempty(coff)
        coff = find(nanmean(eplate,1)>0.1, 1, 'last');
    end
    
    tmpr = grid.r;
    tmpc = grid.c;
    grid.r = nan(grid.dims);
    grid.c = nan(grid.dims);

    grid.r(end-roff+1:end,end-coff+1:end) = tmpr(1:roff,1:coff);
    grid.c(end-roff+1:end,end-coff+1:end) = tmpc(1:roff,1:coff);
    
    %% Final adjustments
%     grid = adjust_grid( plate, grid, ...
%         'rowcoords', grid.dims(1)-roff+1:3:grid.dims(1), ...
%         'colcoords', grid.dims(2)-coff+1:3:grid.dims(2));
    ii = find( ~isnan(grid.r) );
    [ris, cis] = ind2sub( grid.dims, ii );
    grid = adjust_grid( plate, grid, ...
        'rowcoords', ris : 2 : grid.dims(1), ...
        'colcoords', cis : 2 : grid.dims(2) );
    grid = adjust_grid( plate, grid, 'numMiddleAdjusts', 0 );
    
end