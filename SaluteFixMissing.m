close all; clear;
addpath matclasses
addpath matfunctions
addpath yamlmatlab
folder = uigetdir(syshelpers.driveroot());
conf = yaml.ReadYaml('conf.yml');
kind = 'salute';
if isempty(regexpi(folder,'salute'))
    kind = 'restep';
end
constants = conf.GaitFors.(kind).constants;
gr = GaitReversed(folder,constants.subjectpattern);
if ~gr.has_loaded_from_disk
    gr = gr.find_heel_strikes();
    close;
    gr = gr.load_salute_stages(constants.protocol_pattern);
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
