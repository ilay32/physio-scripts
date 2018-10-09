%close all; clear;
addpath 'matclasses';
addpath 'matfunctions';
folder = uigetdir();
gr = GaitReversed(folder,'\d{3}_[A-Za-z]{2}');
gr = gr.find_heel_strikes();
close
gr = gr.load_salute_stages('.*(salute)?.*(pre|post).*(left|right)?.*txt$');
gr = gr.mark_stages(gr.left_hs(1));
gr.confirm_stages();
gr = gr.group_events('HS');
%gr.show_grouped('hs');
gr = gr.find_toe_offs();
gr.show_grouped('to');
%gr = gr.group_events('TO');
%gr.list_cop_points();