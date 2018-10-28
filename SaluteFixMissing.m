close all; clear;
addpath 'matclasses';
addpath 'matfunctions';
folder = uigetdir();
subpat = '\d{3}_[A-Za-z]{2}';
if ~regexpi(folder,'salute')
    subpat = '[A-Za-z]{2}\d{3}';
end
gr = GaitReversed(folder,subpat);
if ~gr.has_loaded_from_disk
    gr = gr.find_heel_strikes();
    close;
    gr = gr.load_salute_stages('.*(salute)?.*(pre|post).*(left|right)?.*txt$');
    gr = gr.mark_stages(gr.left_hs(1));
end
gr.confirm_stages();
if ~gr.has_loaded_from_disk
    gr = gr.group_events('HS');
    gr = gr.find_toe_offs();
end
gr.show_grouped('hs');
gr.show_grouped('to');
gr.save_basic_data();
