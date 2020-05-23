%% Find colony borders
% Matlab Colony Analyzer Toolkit
% Erica Silva, April 2019
%
% Returns the row and column values of the bounding box surrounding the
% colony in the center of the given 2D window.
%
% Usage
% ------------------------------------------------------------------------
% mins = find_colony_borders_threshed( tmp, threshed )
%  - TMP is the 2D window
%  - THRESHED is the thresholded version of tmp
%  - MINS is north, south, west, and east positions of the bounding box
%  (i.e. [rmin rmax cmin cmax]).
%% Updated Code (190515)
function mins = find_colony_borders_threshed( tmp, threshed )
    if (nargin < 2)
        threshed = nan;
    end
    
    % To reduce the contribution of background artifacts in finding colony
    % borders... 
    tmp_ = imgaussfilt(tmp,1);
    
    % Where is the middle of the image?
    midr = floor( size(tmp,1)/2 );
    midc = floor( size(tmp,2)/2 );
    w = floor(midr/2);
    
    % What are max bounds?
    mx = size(threshed,1);
    mn = 1;
    
    %% To account for empty boxes and save time... 
    % get small window
    sw = floor(size(tmp,1)/5);
    % define subsetted box center
    smbox = threshed(midr+[-sw:sw],midc+[-sw:sw]);
    if all(~smbox(:))
        [rmin, rmax, cmin, cmax] = deal(midr);
    else
        %% Find the bounds
        % Get the properties for reach thresholded region in the box
        % BoundingBox specifies [x,y,xwidth,ywidth], with (x,y) denoting the
        % upper left corner of the boundingbox for the region
        stats = regionprops(threshed, 'Centroid', 'BoundingBox');
        % Find distance from center of box to center of each region
        dists = nan(length(stats),1);
        for i = 1:length(stats)
            dists(i) = sqrt(sum(([midr,midc] - stats(i).Centroid).^2));
        end

        % Region of interest
        [~, coi] = min(dists);        
        % As long as COI not empty: 
        if ~isempty(coi)
            
            % Set initial bounds
            rmin = floor(stats(coi).BoundingBox(2));
            rmin(rmin<mn) = mn;
            rmax = ceil(stats(coi).BoundingBox(2) + stats(coi).BoundingBox(4));
            rmax(rmax>mx) = mx;
            cmin = floor(stats(coi).BoundingBox(1));
            cmin(cmin<mn) = mn;
            cmax = ceil(stats(coi).BoundingBox(1) + stats(coi).BoundingBox(3));
            cmax(cmax>mx) = mx;
            
            % North (y)               
            if (~isnan(threshed))

%                   rmin_ = find( islocalmin( smooth( nanmean( ...
%                     tmp_(midr : -1 : rmin, cmin:cmax) ,2) ) ) ,1) -1;
                  rmin_ = find( islocalmin( smooth( max( ...
                    tmp_(midr : -1 : rmin, cmin:cmax),[] ,2) ) ) ,1) -1;

                if (~isempty(rmin_))
                    rmin = midr - rmin_;
                end
            end

            % South (y + ywidth)           
            if (~isnan(threshed))
                
%                 rmax_ = find( islocalmin( smooth( nanmean( ...
%                     tmp_(1+midr:rmax,cmin:cmax) ,2) ) ) ,1) -1;
                rmax_ = find( islocalmin( smooth( max( ...
                    tmp_(1+midr:rmax,cmin:cmax),[] ,2) ) ) ,1) -1;

                if (~isempty(rmax_))
                    rmax = midr + rmax_;
                end
            end

            % West (x)
            if (~isnan(threshed))

%                 cmin_ = find( islocalmin( smooth( nanmean(...
%                     tmp_(rmin:rmax,midc:-1:cmin) ,1) ) ) ,1) -1;
                cmin_ = find( islocalmin( smooth( max(...
                    tmp_(rmin:rmax,midc:-1:cmin),[] ,1) ) ) ,1) -1;

                if (~isempty(cmin_))
                    cmin = midc - cmin_;
                end
            end

            % East (x + xwidth)
            if (~isnan(threshed))

%                 cmax_ = find( islocalmin( smooth( nanmean( ...
%                     tmp_(rmin:rmax,1+midc:cmax) ,1) ) ) ,1) -1;
                cmax_ = find( islocalmin( smooth( max( ...
                    tmp_(rmin:rmax,1+midc:cmax),[] ,1) ) ) ,1) -1;

                if (~isempty(cmax_))
                    cmax = midc + cmax_; 
                end
            end
        else
            % There is no colony that meets these requirements
            [rmin, rmax, cmin, cmax] = deal(midr);
        end
        
    end
    
    mins = [rmin rmax cmin cmax];
    
end

% %% Updated Code
% % Erica Silva
% function mins = find_colony_borders_threshed( tmp, threshed )
%     if (nargin < 2)
%         threshed = nan;
%     end
%     
%     % To reduce the contribution of background artifacts in finding colony
%     % borders... 
%     tmp_ = imgaussfilt(tmp,1);
%     
%     % Where is the middle of the image?
%     midr = floor( size(tmp,1)/2 );
%     midc = floor( size(tmp,2)/2 );
% 
%     w = floor(midr/3);
%     
%     % Workflow:
%         % Section each image by region: 
%             % North (top 1/2)
%             % South (bottom 1/2),
%             % East (right 1/2)
%             % West (left 1/2)
%         % In each region, find the location of the minimum row (north/south) or
%         % column (east/west) average. Set this as the initial boundary
%         
%         % Subset the region using the initial boundary. Look for local minima,
%         % which can indicate colonies touching one another. Subtract 1 from
%         % local minima to avoid including boundary region in colony.
%         
%         % If no local minima is found, find the first row nearest the center of
%         % the image where all values are false. 
%         
%         % Calculate the final boundary value. 
%     
%     % North
%     mi = nanmean(tmp_(1:midr-1, midc +(-w:w)),2);
%     [~,rmin] = min(mi);
%     if (~isnan(threshed))
%         
%         rmin_ = find( islocalmin( smooth( nanmean( ...
%             tmp_(midr : -1 : rmin, midc+(-w:w)) ,2) ) ) ,1) -1;
%         
%         if isempty(rmin_)
%             rmin_ = find(all(~threshed(midr-1:-1: rmin, midc+(-w:w)),2),1);
%         end
%         if (~isempty(rmin_))
%             rmin = midr - rmin_;
%         end
%     end
%     
%     % South
%     mi = nanmean(tmp_(1+midr:end,midc+(-w:w)),2);
%     [~,rmax] = min(mi); rmax = rmax + midr;
%     if (~isnan(threshed))
%         
%         rmax_ = find( islocalmin( smooth( nanmean( ...
%             tmp_(1+midr:rmax,midc+(-w:w)) ,2) ) ) ,1) -1;
%         
%         if isempty(rmax_)
%             rmax_ = find(all(~threshed(1+midr:rmax,midc+(-w:w)),2),1);
%         end
%         if (~isempty(rmax_))
%             rmax = midr + rmax_;
%         end
%     end
%     
%     % West
%     mi = nanmean(tmp_(midr+(-w:w),1:midc-1),1)';
%     [~,cmin] = min(mi);
%     
%     if (~isnan(threshed))
%         
%         cmin_ = find( islocalmin( smooth( nanmean(...
%             tmp_(midr+(-w:w),midc:-1:cmin) ,1) ) ) ,1) -1;
%         
%         if isempty(cmin_)
%             cmin_ = find(all(~threshed(midr+(-w:w),midc-1:-1:cmin),1),1);
%         end
%         if (~isempty(cmin_))
%             cmin = midc - cmin_;
%         end
%     end
%     
%     % East 
%     mi = nanmean(tmp_(midr+(-w:w),1+midc:end),1);
%     [~,cmax] = min(mi); cmax = cmax + midc;
%     if (~isnan(threshed))
%         
%         cmax_ = find( islocalmin( smooth( nanmean( ...
%             tmp_(midr+(-w:w),1+midc:cmax) ,1) ) ) ,1) -1;
%         
%         if isempty(cmax_)
%             cmax_ = find(all(~threshed(midr+(-w:w),1+midc:cmax),1),1);
%         end
%         if (~isempty(cmax_))
%             cmax = midc + cmax_; 
%         end
%     end
%     
%     mins = [rmin rmax cmin cmax];
% end

% %% Old Code
% % Gordon Bean, December 2012
% function mins = find_colony_borders_threshed( tmp, threshed )
%     if (nargin < 2)
%         threshed = nan;
%     end
%     
%     midr = floor( size(tmp,1)/2 );
%     midc = floor( size(tmp,2)/2 );
% 
%     w = floor(midr/3);
%     
%     % North
%     [~,mi] = min(tmp(1:midr,midc +(-w:w)));
%     rmin = median(mi);
%     if (~isnan(threshed))
%         rmin_ = find(all(~threshed(midr : -1 : rmin, midc+(-w:w)),2),1);
%         if (~isempty(rmin_))
%             rmin = midr - rmin_ + 1;
%         end
%     end
%     
%     % South
%     [~,mi] = min(tmp(1+midr:end,midc+(-w:w)));
%     rmax = median(mi) + midr;
%     if (~isnan(threshed))
%         rmax_ = find(all(~threshed(1+midr:rmax,midc+(-w:w)),2),1);
%         if (~isempty(rmax_))
%             rmax = midr + rmax_;% - 1;
%         end
%     end
%     
%     % West
%     [~,mi] = min(tmp(midr+(-w:w),1:midc),[],2);
%     cmin = median(mi);
%     if (~isnan(threshed))
%         cmin_ = find(all(~threshed(midr+(-w:w),midc:-1:cmin),1),1);
%         if (~isempty(cmin_))
%             cmin = midc - cmin_ + 1;
%         end
%     end
%     
%     % East
%     [~,mi] = min(tmp(midr+(-w:w),1+midc:end),[],2);
%     cmax = median(mi) + midc;
%     if (~isnan(threshed))
%         cmax_ = find(all(~threshed(midr+(-w:w),1+midc:cmax),1),1);
%         if (~isempty(cmax_))
%             cmax = midc + cmax_; % - 1;
%         end
%     end
%     
%     mins = [rmin rmax cmin cmax];
% end

% function mins = find_colony_borders_threshed(tmp, threshed)
%     if nargin<2
%         threshed=nan;
%     end
%     
%     midr = floor( size(tmp,1)/2 )+1;
%     midc = floor( size(tmp,2)/2 )+1;
% 
%     w = floor(midr/2);
%     
%     %% North
%     % Inset of thresholded box, which rows are all false?
%     mi = all(~threshed(1:midr,midc +(-w:w)),2); 
%     % What is the lowest row that is all false? The next row is where col
%     % starts
%     rmin = find(mi,1,'last');
%     % If a boundary wasn't found
%     if isempty(rmin)
%         threshed_ = imfill(threshed, 8, 'holes');
%         % if this resulted in whole box being full...
%         if all(threshed_(:))
%             rmin = [];
%         else
%             % Degrade image until boundary found
%             while ~any(all(~threshed_(1:midr,midc +(-w:w)),2))
%                 threshed_ = imerode(threshed_, strel('disk', 1));
%             end
%             % Now get boundary
%             mi = all(~threshed_(1:midr,midc +(-w:w)),2);
%             rmin = find(mi, 1, 'last' ); 
%         end
%     end
%     
%     if isempty(rmin)
%         [~,mi] = min(tmp(1:midr,midc +(-w:w)));
%         rmin = median(mi);
%     end     
%     %% South
%     % Inset of thresholded box, which rows are all false?
%     mi = all(~threshed(midr:end,midc+(-w:w)),2);
%     % What is the lowest row that is all false? The next row is where col
%     % starts
%     rmax = midr + find(mi, 1,'first')-1;
%     % If a boundary wasn't found
%     if isempty(rmax)
%         threshed_ = imfill(threshed, 8, 'holes');
%         if all(threshed_(:)) 
%            rmax = [];
%         else
%             % Degrade image until boundary found
%             while ~any(all(~threshed_(midr:end,midc+(-w:w)),2))
%                 threshed_ = imerode(threshed_, strel('disk', 1));
%             end
%             % Now get boundary
%             mi = all(~threshed_(midr:end,midc+(-w:w)),2);
%             rmax = midr + find(mi, 1, 'first') - 1;
%         end
%     end
%     
%     if isempty(rmax)
%         [~,mi] = min(tmp(1+midr:end,midc+(-w:w)));
%         rmax = median(mi) + midr;
%     end
%     %% West
%     mi = all(~threshed(rmin:rmax,1:midc),1)';
%     % What is the lowest row that is all false? The next row is where col
%     % starts
%     cmin = find(mi, 1,'last');
%     % If a boundary wasn't found
%     if isempty(cmin)
%         threshed_ = imfill(threshed, 8, 'holes');
%         if all(threshed_(:))
%             cmin = [];
%         else
%         % Degrade image until boundary found
%             while ~any(all(~threshed_(rmin:rmax,1:midc),1))
%                 threshed_ = imerode(threshed_, strel('disk', 1));
%             end
%             % Now get boundary
%             mi = all(~threshed_(rmin:rmax,1:midc),1);
%             cmin = find(mi, 1, 'last');
%         end
%     end
%     
%     if isempty(cmin)
%         [~,mi] = min(tmp(midr+(-w:w),1:midc),[],2);
%         cmin = median(mi);
%     end
%     %% East
%     mi = all(~threshed(rmin:rmax,midc:end),1)';
%     % What is the lowest row that is all false? The next row is where col
%     % starts
%     cmax = midc + find(mi, 1, 'first') - 1;
%     if isempty(cmax)
%         threshed_ = imfill(threshed, 8, 'holes');
%         if all(threshed_(:))
%             cmax = [];
%         else
%             % Degrade image until boundary found
%             while ~any(all(~threshed_(rmin:rmax,midc:end),1))
%                 threshed_ = imerode(threshed_, strel('disk', 1));
%             end
%             % Now get boundary
%             mi = all(~threshed_(rmin:rmax,midc:end),1);
%             cmax = midc + find(mi, 1, 'first') - 1 ;
%         end
%     end
%     
%     if isempty(cmax)
%         [~,mi] = min(tmp(midr+(-w:w),1+midc:end),[],2);
%         cmax = median(mi) + midc;
%     end
%     %% Update All
%     % Row Min
%     rmin_ = find(all(~threshed(rmin:midr, cmin:cmax),2),1,'last');
%     if ~isempty(rmin_)
%         rmin = rmin + rmin_ - 1;
%     end
%     % Row Max
%     rmax_ = find(all(~threshed(midr:rmax, cmin:cmax),2),1,'first');
%     if ~isempty(rmax_)
%         rmax = midr + rmax_ - 1;
%     end
%     % Col Min
%     cmin_ = find(all(~threshed(rmin:rmax, cmin:midc),1),1,'last');
%     if ~isempty(cmin_)
%         cmin = cmin + cmin_ -1;
%     end
%     % Col Max
%     cmax_ = find(all(~threshed(rmin:rmax, midc:cmax),1),1,'first');
%     if ~isempty(cmax_)
%         cmax = midc + cmax_ - 1;
%     end
%     
%     mins = [rmin rmax cmin cmax];
%     
% end