%% Analyze Directory of Images
%  Matlab Colony Analyzer Toolkit
%  Gordon Bean, December 2012
%
% Parameters
% ------------------------------------------------------------------------
% extension <'.JPG'>
%  - only files with this extension will be processed
% verbose <false>
%  - if true, the filename is printed as the file is processed
% parallel <false>
%  - if true, uses matlabpool to process directory on multiple cores
%z
% All parameters are passed to analyze_image.
%
% See also matlab_colony_analyzer_tutorial, full_analysis_workflow_tutorial

% (c) Gordon Bean, August 2013

function analyze_directory_of_images( imagedir, varargin )
    params = default_param( varargin, ...
        'extension', '.JPG', ...
        'verbose', false, ...
        'parallel', false, ...
        'recordfailed', false );
    
    %% Get Image Files
    if ischar(imagedir)
        if imagedir(end) ~= filesep
            imagedir = [imagedir filesep];
        end
        files = dirfiles( imagedir, ['*' params.extension] );
        
    elseif iscell(imagedir)
        % An array of files was passed - analyze them.
        files = imagedir;
        
    else
        % I don't know what they gave me.
        error('Unrecognize option for imagedir.');
    end
    
    %% Scan each file
    if (params.parallel)
%         if (parpool('size') == 0)
%             parpool
%         end
        verb = params.verbose;
        parfor ff = 1 : length(files)
            try
                verbose( verb, ' Analyzing: %s %s\n', files{ff}, params.plate_ext);
                analyze_image( files{ff}, varargin{:} );
            catch e
                warning('\nImage %s failed: \n%s\n\n', ...
                    files{ff}, getReport(e));
                if params.recordfailed
                    systemf('touch %s.cs.txt', files{ff});
                end
            end
        end

    else
        for ff = 1 : length(files)
            try
                verbose( params.verbose, ' Analyzing: %s\n', files{ff});
                analyze_image( files{ff}, varargin{:} );
            catch e
                warning('\nImage failed:\n %s\n  %s\n\n', ...
                    files{ff}, getReport(e) );
                if params.recordfailed
                    systemf('touch %s.cs.txt', files{ff});
                end
            end
        end
    end
end