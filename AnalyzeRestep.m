clear; close all;
global goon; 
goon = true;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
conf = yaml.ReadYaml('conf.yml');
folder = uigetdir(syshelpers.driveroot());
listofcop = syshelpers.subdirs(folder,'.*COP.*txt',true);
if isempty(listofcop)
    gf = GaitMissing(folder,'restep');
    gf = gf.load_from_disk();
else
    gf = GaitForceEvents(folder,'restep');
    gf = gf.load_stages();
    gf = gf.mark_stages('ready');
    gf.confirm_stages();
    if ~goon
        error('Operation Aborted');
    end
end
gf = gf.compute_basics();
for b=RestepGroups.export_basics
    fprintf('Computing %s Symmetries\n',b{:});
    visu = gf.get_visualizer(b{:});
    learning_times = visu.plot_global(false);
    gf = gf.process_learning_times(learning_times,b{:});
end
fprintf('\n\nLAST PROCESSED: %s\n',folder)
save = input('save this data [y/n]? ','s');
if strcmp(save,'y')
    gf.save_gist();
end


