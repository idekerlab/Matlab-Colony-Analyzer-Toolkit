%% Border Median - a colony size border correction
% Matlab Colony Analyzer Toolkit
% Gordon Bean, July 2013
% Erica Silva, April 2019

% Syntax
% BM = BorderMedian();
% BM = BorderMedian('Name', Value, ...);
% border = BM(plate);
% border = BM.filter(plate);
% border = BorderMedian(...).filter(plate);
%
% Description
% BM = BorderMedian() returns a BorderMedian object that may be used as a
% regular object (BORDER = BM.filter(PLATE)) or like a function handle
% (BORDER = BM(PLATE)). 
%
% PLATE should be a 2D matrix. If PLATE is a vector, SpatialMedian will
% attempt to reshape it into a standard microbial assay format (96-, 384-,
% 1536-, 6144-, etc., well format) and will throw an error if it fails. If
% PLATE is already 2D, no reshaping is done, and it does not have to have
% standard dimensions.
%
% BM = BorderMedian('Name', Value, ...) accepts parameters from the
% following list (defaults in {}):
%  'depth' {4} - a scalar indicating the number of rows and columns
%  bordering the perimiter of the matrix to be evaluated.
%
% Algorithm
% The BorderMedian algorithm estimates the background intensity for rows
% and columns that are adjacent to the perimeter of the matrix. The
% background is estimated as the median of the repsective row or column. 
%
% The values for corner positions (where a value from the row and from the
% column are available) are assigned based on which row or column value is
% closest to the actual value in the cell. In other words, the row or
% column median that is closest to the value at a corner position is
% selected for that position.
% 
% See also spatial_correction_tutorial.m

classdef BorderMedian < Closure
    properties
        depth
        acceptzeros % Added by ES
        windowfun % Added by ES
        filterzeros % Added by es
    end
    
    methods
        function this = BorderMedian(varargin)
            this = this@Closure();
            this = default_param(this, ...
                'depth', 4, ...
                'acceptZeros', false, ...
                'windowfun', @nanmedian, ...
                'filterzeros', false,...
                varargin{:});
        end
        
        function fit = closure_method(this, varargin)
            fit = this.filter(varargin{:});
        end
        
        function fit = filter(this, colsizes)
            % Make sure colsizes is rectangular
            if max(size(colsizes)) == numel(colsizes)
                n = numel(colsizes);
                dims = [8 12] .* sqrt( n / 96 );
                colsizes = reshape(colsizes, dims);
            else
                dims = size(colsizes);
            end
            
            % Filter Zeros
            if this.filterzeros
                colsizes = fil(colsizes, @(x) x<=0);
            end
            
            % Plate median
            med = this.windowfun(colsizes(:));
            
            % Allocate borders
            [border1, border2] = deal(nan(dims));
            
            % Compute border medians
            d = this.depth;
            fun = this.windowfun;
            
            % Bottom Border
            bottomval = fun(colsizes(end-d+1:end, :),2);
            if ~this.acceptzeros && any(bottomval ==0)
                % find nearest nonzero number
                while any(bottomval==0)  
                    l = find(bottomval==0, 1);
                    sizes = colsizes(end-d+l,:);
                    sz = min(sizes(sizes>0));
                    % else replace with nan
                    if isempty(sz); sz = nan; end
                    bottomval(l) = sz;
                end
            end
            border1(end-d+1:end,:) = ...
                repmat(bottomval,[1 dims(2)]);
            
            % Upper Border
            topval = fun(colsizes(1:d, :),2);
            if ~this.acceptzeros && any(topval==0)
                % find nearest nonzero number               
                while any(topval==0) 
                    l = find(topval==0, 1);
                    sizes = colsizes(l,:);
                    sz = min(sizes(sizes>0));
                     % else replace with nan
                    if isempty(sz); sz = nan; end
                    topval(l) = sz;
                end
            end
            border1(1:d,:) = ...
                repmat(topval,[1 dims(2)]);
            
            % Right Border
            rightval = fun(colsizes(:,end-d+1:end),1);
            if ~this.acceptzeros && any(rightval==0)
                % find nearest nonzero number
                while any(rightval==0)  
                    l = find(rightval==0, 1);
                    sizes = colsizes(:,end-d+l);
                    sz = min(sizes(sizes>0));
                    % else replace with nan
                    if isempty(sz); sz = nan; end
                    rightval(l) = sz;
                end
            end
            border2(:,end-d+1:end) = ...
                repmat(rightval,[dims(1) 1]);
            
            % Left Border
            leftval = fun(colsizes(:,1:d),1);
            % find nearest nonzero number
            if ~this.acceptzeros && any(leftval==0)
                while any(leftval==0)  
                    l = find(leftval==0, 1);
                    sizes = colsizes(:,l);
                    sz = min(sizes(sizes>0));
                    % else replace with nan
                    if isempty(sz); sz = nan; end
                    leftval(l) = sz;
                end
            end
            border2(:,1:d) = ...
                repmat(leftval,[dims(1) 1]);

%             % Compute border medians
%             d = this.depth;
%             fun = @nanmedian;
%             border1(end-d+1:end,:) = ...
%                 repmat(fun(colsizes(end-d+1:end,d+1:end-d),2),[1 dims(2)]);
%             border1(1:d,:) = ...
%                 repmat(fun(colsizes(1:d,d+1:end-d),2),[1 dims(2)]);
% 
%             border2(:,end-d+1:end) = ...
%                 repmat(fun(colsizes(d+1:end-d,end-d+1:end),1),[dims(1) 1]);
%             border2(:,1:d) = ...
%                 repmat(fun(colsizes(d+1:end-d,1:d),1),[dims(1) 1]);
            
            % Pick the border value in the intersecting regions
            fit = border1;
            iii = abs(border2-colsizes) < abs(border1-colsizes) ...
                | isnan(border1);
            fit(iii) = border2(iii);
            fit(isnan(fit)) = med;
        end
        
    end
    
end
