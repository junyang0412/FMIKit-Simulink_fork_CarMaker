function grtfmi_make_rtw_hook(hookMethod, modelName, rtwRoot, templateMakefile, buildOpts, buildArgs, buildInfo)

    if ~strcmp(hookMethod, 'after_make')
        return
    end

    current_dir = pwd;

    % remove FMU build directory from previous build
    if exist('FMUArchive', 'dir')
        rmdir('FMUArchive', 's');
    end

    % create the archive directory (uncompressed FMU)
    mkdir('FMUArchive');

    template_dir = get_param(modelName, 'FMUTemplateDir');

    % copy template files
    if ~isempty(template_dir)
        copyfile(template_dir, 'FMUArchive');
    end

    % remove fmiwrapper.inc for referenced models
    if ~strcmp(current_dir(end-11:end), '_grt_fmi_rtw')
        delete('fmiwrapper.inc');
        return
    end

    if strcmp(get_param(modelName, 'GenCodeOnly'), 'on')
        return
    end

    pathstr = which('grtfmi.tlc');
    [grtfmi_dir, ~, ~] = fileparts(pathstr);

    % add model.png
    if strcmp(get_param(modelName, 'AddModelImage'), 'on')
        % create an image of the model
        print(['-s' modelName], '-dpng', fullfile('FMUArchive', 'model.png'));
    else
        % use the generic Simulink logo
        copyfile(fullfile(grtfmi_dir, 'model.png'), fullfile('FMUArchive', 'model.png'));
    end

    target              = get_param(modelName, 'CMakeTarget');

    if(strcmp(target, 'Windows'))
        grtfmi_target_windows(grtfmi_dir, modelName);
    elseif(strcmp(target, 'Linux'))
        grtfmi_target_linux(grtfmi_dir, modelName);
    end


end