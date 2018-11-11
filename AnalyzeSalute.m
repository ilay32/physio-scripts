clear; close all;
global goon; 
goon = true;
addpath 'matclasses';
addpath 'matfunctions';
stagenames = struct;
stagenames.pre = {'slow1','fast','slow2','adaptation','post_adaptation'};
stagenames.post = {'fast','salute','post_salute'};
stagenames.pre10 = {'slow1','fast','slow2','adaptation'};
stagenames.post10 = {'fast','salute'};

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
subjectpattern = '\d{3}_[A-Za-z]{2}';
% katrin subjectpattern = '[A-Za-z]{2}\d{3}');
folder = uigetdir(syshelpers.driveroot());
listofcop = syshelpers.subdirs(folder,'.*COP.*txt',true);
if isempty(listofcop)
    gf = GaitMissing(folder,stagenames,basicnames,subjectpattern);
    gf = gf.load_from_disk();
else
    gf = GaitForceEvents(folder,stagenames,basicnames,subjectpattern);
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
do_export = input('save the current statistics to file? [y/n] ','s');
if strcmp(do_export,'y')
    gf.export();
end


