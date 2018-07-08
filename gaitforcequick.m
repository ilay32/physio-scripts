folder = uigetdir();
ge = GaitForceEvents(folder);
ge = ge.find_heel_strikes();
ge.quick_export();