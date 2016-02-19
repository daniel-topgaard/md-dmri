function [o_fn, tpm_fn] = mio_coreg(i_fn, r_fn, p_fn, o_path, opt)
% function [o_fn, tpm_fn] = mio_coreg(i_fn, r_fn, p_fn, o_path, opt)
%
% Coregisters input file 'i_fn' to reference 'r_fn' using elastix parameters
% 'p_fn'. Saves the files to 'o_path' as 'o_fn'

if (nargin < 5), opt.present = 1; end
opt = mio_opt(opt);

% General preparation
assert(exist(o_path, 'dir')>0, ['output path does not exist: ' o_path]);

[~,name] = msf_fileparts(i_fn);
o_fn   = fullfile(o_path, [name '_mc' opt.nii_ext]);
tpm_fn = fullfile(o_path, [name '_tp.txt']);

if (exist(o_fn, 'file') && ~opt.do_overwrite)
    disp(['Output file already exists, skipping: ' o_fn]); return;
end

% Read images and headers, check headers
[I_mov, h_mov] = mdm_nii_read(i_fn);
[I_ref, h_ref] = mdm_nii_read(r_fn);

assert(all(h_mov.dim(2:4) == h_ref.dim(2:4)), 'files are not equal in size');

if (size(I_ref,4) ~= size(I_mov,4)) && (size(I_ref,4) ~= 1)
    error('Unexpected size of reference in fourth dimension');
end

datatype = mdm_nii_datatype(h_mov.datatype, 1);

if (opt.mio.coreg.clear_header) % needed to get interpretable tps
    h_ref = clear_ref_header(h_ref);
    h_mov = clear_ref_header(h_mov);
end

% Start registration
I = zeros(size(I_ref,1), size(I_ref,2), size(I_ref,3), size(I_mov,4), datatype);
P = zeros(12, size(I_mov,4));
for c = 1:size(I_mov, 4)
    fprintf('mio_coreg, registering vol %i of %i\n', c, size(I_mov,4));
    
    % Build filenames
    ref_fn = fullfile(o_path, ['f_' num2str(c) '.nii']);
    mov_fn = fullfile(o_path, ['m_' num2str(c) '.nii']);
    
    % Write outputs
    I_tmp = mio_pad(I_ref(:,:,:,min(size(I_ref, 4), c)), opt.mio.coreg.pad_xyz);
    mdm_nii_write(I_tmp, ref_fn, h_ref);
    
    I_tmp = mio_pad(I_mov(:,:,:,c), opt.mio.coreg.pad_xyz);
    mdm_nii_write(I_tmp, mov_fn, h_mov);
    
    % Run ElastiX, Read image volume and transform parameters
    [res_fn, tp_fn] = elastix_perform(mov_fn, ref_fn, p_fn, o_path);
    I_tmp = mdm_nii_read(res_fn);
    tp = elastix_tp_read(tp_fn);
    msf_delete({res_fn, tp_fn, ref_fn, mov_fn});
    
    % Adjust before storing
    I_tmp = mio_pad(cast(I_tmp, datatype), -opt.mio.coreg.pad_xyz);
    
    if (opt.mio.coreg.adjust_intensity)
        I_tmp = I_tm / tp(2,3); % Intensity scaling by y-scale
    end
    
    % Store
    I(:,:,:,c) = I_tmp;
    P(:,c)     = tp(:);
end

% Write output
mdm_nii_write(I, o_fn, h_ref);
elastix_tpm_write(P, tp_fn);



% Header setting connected to correctness of gradient rotations
% It is a pain to get it right.
% Restrict to LAS for now.
    function h_ref = clear_ref_header(h_ref)
        h_tmp = mdm_nii_h_empty;
        h_tmp.pixdim(1:4) = h_ref.pixdim(1:4);
        
        if (opt.mio.coreg.assume_las)
            
            if (~all(mdm_nii_oricode(h_ref) == 'LAS'))
                error('MC: Rotate gradients only for LAS data (fix deviated)');
            end
            if (~all(mdm_nii_oricode(h_mov) == 'LAS'))
                error('MC: Rotate gradients only for LAS data (mov deviated)');
            end
            
            h_tmp.sform_code = 1;
            h_tmp.srow_x = [-h_ref.pixdim(2) 0 0 +h_ref.dim(2) * h_ref.pixdim(2) / 2];
            h_tmp.srow_y = [0 +h_ref.pixdim(3) 0 -h_ref.dim(3) * h_ref.pixdim(3) / 2];
            h_tmp.srow_z = [0 0 +h_ref.pixdim(4) -h_ref.dim(4) * h_ref.pixdim(4) / 2];
        end
        h_ref = h_tmp;
    end

end
