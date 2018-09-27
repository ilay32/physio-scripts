clear; close all;
global goon; 
goon = true;
addpath 'matclasses';
stagenames = struct;
stagenames.pre = {'slow1','fast','slow2','adaptation','post_adaptation'};
stagenames.post = {'fast','salute','post_salute'};
stagenames.post11_part1 = {'fast','salute'};
stagenames.post11_part2 = {'salute','post_salute'};
stagenames.post23_part1 = {'slow'};
stagenames.post23_part2 = {'salute','post_salute'};
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
folder = uigetdir('C:\Users\Public\Salute\Salute Trials\naamadiskonkey');
for part=1:2
    partname = ['part' num2str(part)];
    gfp = GaitForceEvents(fullfile(folder,partname),stagenames,basicnames,subjectpattern);
    gfp = gfp.load_stages('.*(salute)?.*(pre|post).*(left|right)?.*txt$');
    gfp = gfp.mark_stages('ready');
    gfp.confirm_stages();
    if ~goon
        error('Operation Aborted');
    end
    gfp = gfp.compute_basics();
    eval(['part' num2str(part) ' = gfp;']);
    clear gfp;
end
gf = part1.combine(part2);
for b=basicnames
    fprintf('Computing %s Symmetries:\n',b{:});
    specs = struct; 
    specs.name = b{:};
    syms = cell(1,gf.numstages);
    for s=1:gf.numstages
        stage = gf.stages(s);
        syms{s} = gf.basics.(stage.name).data.([b{:} '_symmetries']);
    end
    specs.data = syms;
    specs.stagenames = extractfield(gf.stages,'name');
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
    learning_times = visu.plot_global(false);
    gf = gf.process_learning_times(learning_times,b{:});
    fprintf('done.\n\n');
end
do_export = input('save the current statistics to file? [y/n] ','s');
if strcmp(do_export,'y')
    gf.export();
end