%% RawPlateLoader Class
% Matlab Colony Analyzer Toolkit
% Gordon Bean, May 2013
%
% This object is used to load plate images from RAW files that have been
% converted to TIFF format using convert_raw_to_tiff.
%
% Syntax
% PL = RawPlateLoader();
% PL = RawPlateLoader('Name', Value, ...);
% plate = PL(img);
% plate = PL.load(img);
% plate = RawPlateLoader(...).load(img);
%
% Description
% PL = RawPlateLoader() returns a RawPlateLoader object with the default
% parameters. PL = RawPlateLoader('Name', Value, ...) accepts name-value 
% pairs from following list (defaults in <>):
%  'black' - a scalar indicating the lower bound pixel intensity for
%  linearizing the data. If not specified, RawPlateLoader will look for a
%  .MAT file containing this information. If not found, RawPlateLoader will
%  assume this value is the min pixel value of the image.
%
%  'saturation' - a scalar indicating the upper bound pixel intensity for
%  linearizing the data. If not specified, RawPlateLoader will look for a
%  .MAT file containing this information. If not found, RawPlateLoader will
%  assume this value is the max pixel value of the image.
%
%  'warnings' <true> - a logical indicating whether warnings will be
%  displayed. 
%
% RawPlateLoader also accepts all parameters from PlateLoader.
%
% See PlateLoader, convert_raw_to_tiff

classdef RawPlateLoader < PlateLoader
    properties
       black
       saturation
       warnings
       gray_scale
    end
    
    methods
        function this = RawPlateLoader(varargin)
            this = this@PlateLoader( varargin{:} );
            params = default_param( varargin, ...
                'black', nan, ...
                'saturation', nan, ...
                'warnings', true, ...
                'gray_scale', false);
            
            for prop = setdiff(properties('RawPlateLoader'), ...
                    properties('PlateLoader'))'
                this.(prop{:}) = params.(prop{:});
            end
            
        end
        
        function out = closure_method(this, varargin)
            out = this.load(varargin{:});
        end
        
        function img = load_image(this, filename)
            % Read file
            img = double(imread(filename)); 
            
            % Linearize
            has_specs = false;
            if exist([filename '.mat'], 'file')
                load([filename '.mat'], 'black', 'saturation');
                has_specs = true;
            elseif exist([filename '.txt'], 'file')
                fid = fopen([filename '.txt']);
                tmp = textscan(fgetl(fid), '%f');
                fclose(fid);
                
                this.black = tmp{1}(1);
                this.saturation = tmp{1}(2);    
            end
            
            if isnan(this.black)
                if has_specs
                    this.black = black;
                else
                    if this.warnings
                        warning('Assuming black level is min value'); 
                    end
                    this.black = min(img(:));
                end
            end
            if isnan(this.saturation)
                if has_specs
                    this.saturation = saturation;
                else
                    if this.warnings
                        warning('Assuming saturation level is max value'); 
                    end
                    this.saturation = max(img(:));
                end
            end
            
            lin_bayer = (img-this.black)/(this.saturation-this.black);
            lin_bayer = max(0, min(lin_bayer,1));

            % Demosaic
            foo = uint16( lin_bayer / max(lin_bayer(:)) * 2^16 );
            try
                lin_rgb = double(demosaic(foo,'rggb'))/2^16;
            catch e
                fprintf(2, ['\nDemosaic failed.\n\nIs %s\n a TIFF file '...
                    'obtained using convert_raw_to_tiff?\n\n'], filename);
                rethrow(e);
            end
            
            % Average across channels
            if this.gray_scale == true %% Added by Erica Silva 191028
                img = rgb2gray(lin_rgb);
            else
                img = mean(lin_rgb(:,:,this.channel),3) * 2^8;
            end
        end
    end
end