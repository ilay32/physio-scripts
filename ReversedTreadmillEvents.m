close all; clear;
addpath 'matclasses';
addpath 'matfunctions';
folder = uigetdir();
gr = GaitReversed(folder,'stability-\d+');
if ~gr.has_loaded_from_disk
    gr = gr.find_heel_strikes();
    gr = gr.load_ps_stages();
    gr = gr.mark_stages(gr.left_hs(1));
    gr.confirm_stages();
    gr = gr.group_events('HS');
    savecurrent = input('save the current stage boundaries and heel strikes to disk [y/n]? ','s');
    if strcmp(savecurrent,'y')
        gr.save_basic_data();
    end
else
    gr.confirm_stages();
    gr = gr.group_events('HS');
end
gr.proper_export();

