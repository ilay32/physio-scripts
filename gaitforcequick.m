folder = uigetdir();
ge = GaitForceEvents(folder);
ge = ge.find_heel_strikes();
ge.quick_export();
comp = input('compare with GaitForce? [y/n] ','s');
if strcmp(comp,'y')
    ge.check_against_gaitforce();
end

