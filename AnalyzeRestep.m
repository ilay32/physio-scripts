clear; close all;
global goon; 
goon = true;
addpath 'matclasses';
addpath 'matfunctions';
export_basics = {'step_length'};
stagenames = struct;
stagenames.pre = {'slow','fast','adaptation','post_adaptation','re_adaptation'};
stagenames.post = stagenames.pre;


basicnames = {'step_duration','step_length'};
subjectpattern = '[A-Za-z]{2}\d{3}';
folder = uigetdir(syshelpers.driveroot());
listofcop = syshelpers.subdirs(folder,'.*COP.*txt',true);
if isempty(listofcop)
    gf = GaitMissing(folder,stagenames,basicnames,subjectpattern);
    gf = gf.load_from_disk();
else
    gf = GaitForceEvents(folder,stagenames,basicnames,subjectpattern);
    gf = gf.load_stages('.*Day_(1|2)\.txt.*');
    gf = gf.mark_stages('ready');
    gf.confirm_stages();
    if ~goon
        error('Operation Aborted');
    end
end
gf = gf.compute_basics();
for b=export_basics
    fprintf('Computing %s Symmetries\n',b{:});
    visu = gf.get_visualizer(b{:});
    learning_times = visu.plot_global(false);
    gf = gf.process_learning_times(learning_times,b{:});
end
gf.save_gist();


