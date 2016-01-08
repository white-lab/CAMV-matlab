%%% Safe version of MATLAB's system() that allows for spaces in file names.
function [a,b] = systemsafe(varargin)
    cmd = '';
    
    for i=1:nargin
        if i > 1
            cmd = [cmd, ' '];
        end

        if ~isempty(strfind(varargin{i}, ' '))
            cmd = [cmd, sprintf('"%s"', strrep(varargin{i}, '\', '\\'))];
        else
            cmd = [cmd, sprintf('%s', strrep(varargin{i}, '\', '\\'))];
        end
    end
    
    disp(cmd);
    [a,b] = system(cmd, '-echo');
end
