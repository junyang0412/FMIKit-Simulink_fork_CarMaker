function grtfmi_target_windows(grtfmi_dir, modelName)

    cmake_command       = get_param(modelName, 'CMakeCommand');
    cmake_command       = grtfmi_find_cmake(cmake_command);
    
    generator           = get_param(modelName, 'CMakeGenerator');
    if ispc
        generator_platform  = get_param(modelName, 'CMakeGeneratorPlatform');
    end
    toolset             = get_param(modelName, 'CMakeToolset');
    optimization_level  = get_param(modelName, 'CMakeCompilerOptimizationLevel');
    optimization_flags  = get_param(modelName, 'CMakeCompilerOptimizationFlags');
    build_configuration = get_param(modelName, 'CMakeBuildConfiguration');
    source_code_fmu     = get_param(modelName, 'SourceCodeFMU');
    fmi_version         = get_param(modelName, 'FMIVersion');
    proj_dir            = get_param(modelName, 'ProjDir');

    % copy extracted nested FMUs
    nested_fmus = find_system(modelName, 'LookUnderMasks', 'All', 'FunctionName', 'sfun_fmurun');

    if ~isempty(nested_fmus)
        disp('### Copy nested FMUs')
        for i = 1:numel(nested_fmus)
            nested_fmu = nested_fmus{i};
            unzipdir = FMIKit.getUnzipDirectory(nested_fmu);
            user_data = get_param(nested_fmu, 'UserData');
            dialog = FMIKit.showBlockDialog(nested_fmu, false);
            if user_data.runAsKind == 0
                model_identifier = char(dialog.modelDescription.modelExchange.modelIdentifier);
            else
                model_identifier = char(dialog.modelDescription.coSimulation.modelIdentifier);
            end
            disp(['Copying ' unzipdir ' to resources'])                
            copyfile(unzipdir, fullfile('FMUArchive', 'resources', model_identifier), 'f');
        end
    end

    disp('### Running CMake generator')
    % get model sources
    [custom_include, custom_source, custom_library] = ...
        grtfmi_model_sources(modelName, pwd);

    custom_include = cmake_list(custom_include);
    custom_source  = cmake_list(custom_source);
    custom_library = cmake_list(custom_library);
    custom_define  = cmake_list(regexp(get_param(modelName, 'CustomDefine'), '\s+', 'split'));

    % check for Simscape blocks
    if isempty(find_system(modelName, 'BlockType', 'SimscapeBlock'))
        simscape_blocks = 'off';
    else
        simscape_blocks = 'on';
    end

    % write the CMakeCache.txt file
    msysroot = getenv("MSYS_ROOT");
    if isempty(msysroot)
        disp('Cannot find environment variable MSYS_ROOT')
    end
    rootpath = fullfile(msysroot, 'mingw64');
    make = fullfile(rootpath, 'bin/mingw32-make.exe');
    gcc = fullfile(rootpath, 'bin/gcc.exe');
    gpp = fullfile(rootpath, 'bin/g++.exe');

    fid = fopen('CMakeCache.txt', 'w');
    fprintf(fid, 'CMAKE_SYSTEM_NAME=%s\n', 'Windows');
    fprintf(fid, 'CMAKE_GENERATOR:STRING=%s\n', generator);
    if ispc && ~strcmp(generator, 'MinGW Makefiles')
        fprintf(fid, 'CMAKE_GENERATOR_PLATFORM:STRING=%s\n', generator_platform);
    else
        fprintf(fid, 'CMAKE_MAKE_PROGRAM:STRING=%s\n', strrep(make, '\', '/'));
        fprintf(fid, 'CMAKE_C_COMPILER:STRING=%s\n', strrep(gcc, '\', '/'));
        fprintf(fid, 'CMAKE_CXX_COMPILER:STRING=%s\n', strrep(gpp, '\', '/'));
        fprintf(fid, 'CMAKE_C_COMPILER_FORCED:INT=%d\n', 1);
        fprintf(fid, 'CMAKE_CXX_COMPILER_FORCED:INT=%d\n', 1);
    end

    if ~isempty(toolset)
        fprintf(fid, 'CMAKE_GENERATOR_TOOLSET:STRING=%s\n', toolset);
    end
    fprintf(fid, 'MODEL_NAME:STRING=%s\n', modelName);
    fprintf(fid, 'MATLAB_ROOT:STRING=%s\n', strrep(matlabroot, '\', '/'));
    fprintf(fid, 'RTW_DIR:STRING=%s\n', strrep(pwd, '\', '/'));
    fprintf(fid, 'CUSTOM_INCLUDE:STRING=%s\n', custom_include);
    fprintf(fid, 'CUSTOM_SOURCE:STRING=%s\n', custom_source);
    fprintf(fid, 'CUSTOM_LIBRARY:STRING=%s\n', custom_library);
    fprintf(fid, 'CUSTOM_DEFINE:STRING=%s\n', custom_define);
    fprintf(fid, 'SOURCE_CODE_FMU:BOOL=%s\n', upper(source_code_fmu));
    fprintf(fid, 'SIMSCAPE:BOOL=%s\n', upper(simscape_blocks));
    fprintf(fid, 'FMI_VERSION:STRING=%s\n', fmi_version);
    fprintf(fid, 'COMPILER_OPTIMIZATION_LEVEL:STRING=%s\n', optimization_level);
    fprintf(fid, 'COMPILER_OPTIMIZATION_FLAGS:STRING=%s\n', optimization_flags);
    fclose(fid);

    disp('### Generating project')

    command = ['"' cmake_command '" "' strrep(grtfmi_dir, '\', '/') '"'];
    status = system(command);
    assert(status == 0, 'Failed to run CMake generator');

    disp('### Building FMU')
    status = system(['"' cmake_command '" --build . --config ' build_configuration]);
    assert(status == 0, 'Failed to build FMU');

    if ~exist(proj_dir, 'dir')
        return
    end
    grtfmi_copy_output(pwd, proj_dir, modelName);
end


function joined = cmake_list(array)

    if isempty(array)
        joined = '';
        return
    end
    
    joined = array{1};
    
    for i = 2:numel(array)
        joined = [joined ';' array{i}];  
    end
    
end
    