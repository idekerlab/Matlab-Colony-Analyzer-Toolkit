%% Threshold Method Parent Class
% Phil Jaeger Sep 2016
% modified from Gordon Bean, March 2013
%
% ThresholdMethod is intended as an abstract class and is not useful for
% instantiation. 
%
%
% See also BackgroundOffset, BackgroundOffsetRGB, MaxMinMean, MinFrequency,
%  LocalFitted, HalfModeMax

classdef ThresholdMethod < Closure
   
    properties
%none
    end
    
    methods
        function this = ThresholdMethod(varargin)
            this = this@Closure();
            % Initialize object 'this'
        end
        
        function out = closure_method(this, varargin)
            out = this.determine_threshold(varargin{:});
        end
        
        function box = get_colony_box(~, plate, grid, row, col)
%             % Default is to use grid.win.
            box = get_box(plate, ...
                grid.r(row, col), grid.c(row, col), grid.win);
         
        end
        
        function it = determine_threshold(~, box )
            % To be implemented by subclasses
            it = nan;
        end
        
        function thrplate = apply_threshold( this, plate, grid )
            % Default 
            % - iterate through each position
            % - get box
            % - estimate threshold
            % - save thresholded box
            
%             thrplate = false(size(plate)); % Commented by ES
            thrplate = NaN(grid.dims); % Uncommented by ES
            
%             % COMMENT AS NEEDED
%             [rr cc] = meshgrid(1:length(round(grid.c(1,1))-...
%                 grid.win:round(grid.c(1,1))+grid.win)); %this is for the circular mask
%             C = sqrt((rr-grid.win).^2+(cc-grid.win).^2)<=grid.win/3;
%             %
                    
            for r = 1 : grid.dims(1)
                for c = 1 : grid.dims(2)
                    box = this.get_colony_box(plate, grid, r, c);
                        
                    it = this.determine_threshold( box );
                    thrplate(r,c) = it; % uncommented by ES
%                     %Commented by ES
%                     thrplate = set_box(thrplate, box>it, ...
%                         grid.r(r,c), grid.c(r,c));  
                    
%                     % COMMENT AS NEEDEDS
%                     thrplate = set_box(thrplate, C, ...
%                         grid.r(r,c), grid.c(r,c));
                    
                end
            end
        end
    end
    
end
% %% Threshold Method Parent Class
% % Gordon Bean, March 2013
% %
% % ThresholdMethod is intended as an abstract class and is not useful for
% % instantiation. 
% %
% % See also BackgroundOffset, BackgroundOffsetRGB, MaxMinMean, MinFrequency,
% %  LocalFitted, HalfModeMax
% 
% classdef ThresholdMethod < Closure
%    
%     properties
%         % None
%     end
%     
%     methods
%         function this = ThresholdMethod()
%             this = this@Closure();
%             % Initialize object 'this'
%         end
%         
%         function out = closure_method(this, varargin)
%             out = this.determine_threshold(varargin{:});
%         end
%         
%         function box = get_colony_box(~, plate, grid, row, col)
%             % Default is to use grid.win.
%             box = get_box(plate, ...
%                 grid.r(row, col), grid.c(row, col), grid.win);
%         end
%         
%         function it = determine_threshold(~, box )
%             % To be implemented by subclasses
%             it = nan;
%         end
%         
%         function thrplate = apply_threshold( this, plate, grid )
%             % Default 
%             % - iterate through each position
%             % - get box
%             % - estimate threshold
%             % - save thresholded box
%             thrplate = false(size(plate));
%             for r = 1 : grid.dims(1)
%                 for c = 1 : grid.dims(2)
%                     box = this.get_colony_box(plate, grid, r, c);
%                     it = this.determine_threshold( box );
%                     thrplate = set_box(thrplate, box>it, ...
%                         grid.r(r,c), grid.c(r,c));
%                 end
%             end
%         end
%     end
%     
% end