function res = mdm_bruker_acqus2mat(data_path)% function res = mdm_bruker_acqus2mat(data_path)% % Read Bruker acquisition parameters in directory data_path% Includes acqus, acqu2s, and (if defined) vd, vc, vp, and fq1 lists.% Save experimental parameter structures NMRacqus and NMRacqu2s in% data_path.if (isstruct(data_path))    warning('update script to use data_path directly, this is legacy code');    data_path = data_path.data;enddata_fn = [data_path '/acqusconv'];mdm_unix2txt([data_path '/acqus'], data_fn); fid = fopen(data_fn,'rt');structnam = 'NMRacqus';templine = fgetl(fid);while ischar(templine),if length(templine) > 4   if strcmp('$$ 20',templine(1:5)) == 1         value = templine(4:7);         paranam = 'yearstr';         eval([structnam '.' paranam ' = value;'])         value = templine(9:10);         paranam = 'monthstr';         eval([structnam '.' paranam ' = value;'])         value = templine(12:13);         paranam = 'daystr';         eval([structnam '.' paranam ' = value;'])         value = templine(15:16);         paranam = 'hourstr';         eval([structnam '.' paranam ' = value;'])         value = templine(18:19);         paranam = 'minutestr';         eval([structnam '.' paranam ' = value;'])         value = templine(21:22);         paranam = 'secondstr';         eval([structnam '.' paranam ' = value;'])         value = str2num(templine(4:7));         paranam = 'year';         eval([structnam '.' paranam ' = value;'])         value = str2num(templine(9:10));         paranam = 'month';         eval([structnam '.' paranam ' = value;'])         value = str2num(templine(12:13));         paranam = 'day';         eval([structnam '.' paranam ' = value;'])         value = str2num(templine(15:16));         paranam = 'hour';         eval([structnam '.' paranam ' = value;'])         value = str2num(templine(18:19));         paranam = 'minute';         eval([structnam '.' paranam ' = value;'])         value = str2num(templine(21:22));         paranam = 'second';         eval([structnam '.' paranam ' = value;'])         value = templine(35:length(templine));         paranam = 'user';         eval([structnam '.' paranam ' = value;'])   endendif length(templine) > 3   if strcmp('$$ /',templine(1:4)) == 1       indxslash = find(templine == '/');       value = templine(4:indxslash(length(indxslash)-1));       paranam = 'datapath';       eval([structnam '.' paranam ' = value;'])   elseif strcmp('$$ C',templine(1:4)) == 1       indxslash = find(templine == '/');       value = templine(14:indxslash(length(indxslash)-1));       paranam = 'datapath';       eval([structnam '.' paranam ' = value;'])   endendindxeq = find(templine == '=');if ~isempty(indxeq)    if strcmp('##$',templine(1:3)) == 1        paranam = lower(templine(4:indxeq(1)-1));        tempval = templine(indxeq+1:length(templine));        indxs = find((tempval == '<') | (tempval == '>'));  % Find string         indxv = find((tempval == '(') | (tempval == ')'));  % Find vector        if ~isempty(indxs)            % Value is a string            if numel(indxs) == 1                value = tempval(indxs(1)+1:length(tempval));            else                value = tempval(indxs(1)+1:indxs(2)-1);            end            eval([structnam '.' paranam ' = value;'])        elseif ~isempty(indxv)                               % Value is a vector at next line(s)            indxd = find(tempval == '.');            indxv = str2num(tempval(indxd(2)+1:indxv(2)-1))+1;  % Length of vector            value = ['[' num2str(fscanf(fid,'%f',indxv)') ']'];            eval([structnam '.' paranam ' = ' value ';'])        else            % Value is a scalar            value = tempval;            if strcmp(value,' no') == 1                assignin('base',paranam,'no')            elseif strcmp(value,' yes') == 1                assignin('base', paranam,'yes')            else                eval([structnam '.' paranam ' = ' value ';'])            end        end    endendtempline = fgetl(fid);endfclose(fid);% ArraysVarNam = {'p','d','pl','l','cnst','in','inp'};for nVar = 1:length(VarNam)    for m = 1:length(eval([structnam '.' VarNam{nVar}]))        eval([structnam '.' VarNam{nVar} num2str(m-1) ' = ' structnam '.' VarNam{nVar} '(' num2str(m) ');']);    endend% Lists, if existingif exist([data_path '/vdlist']) == 2    fidvd = fopen([data_path '/vdlist']);    NMRacqus.vd = fscanf(fidvd,'%f');    fclose(fidvd);endif exist([data_path '/vclist']) == 2    fidvc = fopen([data_path '/vclist']);    NMRacqus.vc = fscanf(fidvc,'%f');    fclose(fidvc);endif exist([data_path '/vplist']) == 2    fidvp = fopen([data_path '/vplist']);    NMRacqus.vp = fscanf(fidvp,'%f');    fclose(fidvp);endif exist([data_path '/fq1list']) == 2    fidfq1 = fopen([data_path '/fq1list']);    templine = fgetl(fidfq1);    NMRacqus.fq1 = fscanf(fidfq1,'%f');    fclose(fidfq1);endNMRacqus.dw = .5/NMRacqus.sw_h;NMRacqus.aq = NMRacqus.dw*NMRacqus.td;save([data_path '/NMRacqus'],'NMRacqus')delete([data_path '/acqusconv'])% Repeat the procedure for acqu2s (if defined)if exist([data_path '/acqu2s']) == 2    structnam = 'NMRacqu2s';    res = mdm_unix2txt([data_path '/acqu2s'],[data_path '/acqu2sconv']);    fid = fopen([data_path '/acqu2sconv'],'rt');    templine = fgetl(fid);    while ischar(templine),       if length(templine) > 4           if strcmp('$$ 20',templine(1:5)) == 1                 value = templine(4:length(templine));                 paranam = 'datetimeuser';                 eval([structnam '.' paranam ' = value;'])           end       end       if length(templine) > 3           if strcmp('$$ /',templine(1:4)) == 1                 value = templine(4:length(templine));                 paranam = 'datapath';                 eval([structnam '.' paranam ' = value;'])           end       end       indxeq = find(templine == '=');       if ~isempty(indxeq)            if strcmp('##$',templine(1:3)) == 1                paranam = lower(templine(4:indxeq(1)-1));                tempval = templine(indxeq+1:length(templine));                indxs = find((tempval == '<') | (tempval == '>'));  % Find string                 indxv = find((tempval == '(') | (tempval == ')'));  % Find vector                if ~isempty(indxs)                    % Value is a string                    if numel(indxs) == 1                        value = tempval(indxs(1)+1:length(tempval));                    else                        value = tempval(indxs(1)+1:indxs(2)-1);                    end                    eval([structnam '.' paranam ' = value;'])                elseif ~isempty(indxv)                                       % Value is a vector at next line(s)                    indxd = find(tempval == '.');                    indxv = str2num(tempval(indxd(2)+1:indxv(2)-1))+1;  % Length of vector                    value = ['[' num2str(fscanf(fid,'%f',indxv)') ']'];                    eval([structnam '.' paranam ' = ' value ';'])                else                    % Value is a scalar                    value = tempval;                    if strcmp(value,' no') == 1                        assignin('base',paranam,'no')                    elseif strcmp(value,' yes') == 1                        assignin('base',[structnam '.' paranam],'yes')                    else                        eval([structnam '.' paranam ' = ' value ';'])                    end                end            end       end       templine = fgetl(fid);    end    save([data_path '/NMRacqu2s'],'NMRacqu2s')    delete([data_path '/acqu2sconv'])    fclose(fid);end    res = 1;