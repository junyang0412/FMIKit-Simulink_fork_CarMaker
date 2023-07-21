function grtfmi_copy_output(fmi_dir, proj_dir, modelName)
    plugin_dir = fullfile(proj_dir, 'Plugins', modelName);
    if ~exist(plugin_dir, 'dir')
        mkdir(plugin_dir)
    end
    copyfile(fullfile(fmi_dir, 'FMUArchive'), plugin_dir);
    copyfile(fullfile(fmi_dir, [modelName, '.fmu']), fullfile(proj_dir, 'Plugins'));
    pluginfo = fullfile(pwd, '..', [modelName, '.pluginfo']);
    if exist(pluginfo, 'file')
        copyfile(pluginfo, fullfile(proj_dir, 'Plugins'));
    end
end