clear; close all;
addpath 'matclasses';
stagenames = struct;
stagenames.pre = {'slow1','fast','slow2','adaptation','post_adaptation'};
stagenames.post = {'fast','salute','post_salute'};
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
folder = uigetdir(syshelpers.driveroot());
gf = GaitForceEvents(folder,stagenames,basicnames,subjectpattern);
gf = gf.load_stages();
gf.confirm_stages();
gf = gf.compute_basics();

for b=basicnames    
    specs = struct; 
    specs.name = b{:};
    syms = cell(1,gf.numstages);
    for s=1:gf.numstages
        stage = gf.stages(s);
        syms{s} = gf.basics.(stage.name).([b{:} '_symmetries']);
    end
    specs.data = syms;
    specs.stagenames = stagenames.(gf.prepost);
    specs.titlesprefix = gf.prepost;
    if strcmp(gf.prepost,'pre')
        specs.baselines = 1:3;
        specs.fitmodel = 4:5;
    else
        specs.baselines = 1;
        specs.fitmodel = 2:3;
    end
    specs.model = 'exp2';
    visu = VisHelpers(specs);
    visu.plot_global(false);
end
do_export = input('save the current statistics to file? [y/n] ','s');
if strcmp(do_export,'y')
    gf.export();
end


