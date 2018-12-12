clear; close all;
global goon; 
goon = true;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
folder = uigetdir(syshelpers.driveroot());
for part=1:2
    partname = ['part' num2str(part)];
    gfp = GaitForceEvents(fullfile(folder,partname),'salute');
    gfp = gfp.load_stages();
    gfp = gfp.mark_stages('ready');
    gfp.confirm_stages();
    if ~goon
        error('Operation Aborted');
    end
    gfp = gfp.compute_basics(); %#ok<NASGU>
    eval(['part' num2str(part) ' = gfp;']);
    clear gfp;
end
gf = part1.combine(part2);
for b=gf.conf.constants.basicnames
    fprintf('Computing %s Symmetries:\n',b{:});
    visu = gf.get_visualizer(b{:});
    learning_times = visu.plot_global(false);
    gf = gf.process_learning_times(learning_times,b{:});
    fprintf('done.\n\n');
end
gf.save_gist();
do_export = input('save the current statistics to file? [y/n] ','s');
if strcmp(do_export,'y')
    gf.export();
end
