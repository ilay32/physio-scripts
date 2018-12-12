close all;
clear;
global goon; 
goon = true;
addpath 'matclasses';
addpath 'matfunctions';
stagenames = struct;

basicnames = {...
    'step_length',...
	'step_duration',... 
	'stride_duration',...
	'stride_length',...
	'step_width',...
	'swing_duration',...
	'stance_duration',...
	'ds_duration'...
};
folder = uigetdir(syshelpers.driveroot());
listofcop = syshelpers.subdirs(folder,'.*COP.*txt',true);
if isempty(listofcop)
    gf = GaitMissing(folder,basicnames,'salute');
    gf = gf.load_from_disk();
else
    gf = GaitForceEvents(folder,basicnames,'salute');
    gf = gf.load_stages('.*(salute)?.*(pre|post).*(left|right)?.*txt$');
    gf = gf.mark_stages('ready');
    gf.confirm_stages();
    if ~goon
        error('Operation Aborted');
    end
end
gf = gf.compute_basics();
for b=basicnames
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


