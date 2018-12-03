function txt = mdm_xps_info(xps, method, opt)% function txt = mdm_xps_info(xps, method, opt)%% Print protocol informationif (nargin < 2), method = ''; endif (nargin < 3), opt = []; endf = @(m,v,txt) cat(1, txt, sprintf(m, v));    function abbreviation = b_delta_to_abbreviation(b_delta)        if (abs(b_delta) < 0.05)            abbreviation = 'STE';        elseif (b_delta > 0.95)            abbreviation = 'LTE';        elseif (b_delta < -0.45)            abbreviation = 'PTE';        elseif (b_delta > 0)            abbreviation = 'xTE';        elseif (b_delta < 0)            abbreviation = 'xTE';        end            endtxt{1} = 'Summary of the eXperimental Parameter Structure (xps)';txt = f('Number of measurements: %i\n', xps.n, txt);if (isfield(xps, 'b'))    txt = f('Maximal b-value: %1.2f um^2/ms\n', max(xps.b) * 1e-9, txt);endswitch (method)    case 'dtd_covariance'                xps_pa = mdm_xps_pa(xps, opt);                for c = 1:xps_pa.n            txt = cat(1, txt, ...                sprintf('b = %1.2f um^2/ms, b_delta = %1.1f (%s), #dirs = %i', ...                xps_pa.b(c) * 1e-9, ...                xps_pa.b_delta(c), ...                b_delta_to_abbreviation(xps_pa.b_delta(c)), ...                xps_pa.pa_w(c)));        end            case ''        txt = f('No method specific information requested', [], txt);            otherwise        endif (nargout == 0)    disp(' ');    disp('---------------------------------------------------------------');    cellfun(@(x) disp(x), txt);    disp('---------------------------------------------------------------');    clear txt;endend