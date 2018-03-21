#!/usr/bin/env python
# -*- coding: utf-8 -*-

import expyriment
from expyriment import  control, stimuli, design, misc
from expyriment import io as exio


exp = expyriment.design.Experiment(name="Corridor Walk")
expyriment.control.initialize(exp)
expyriment.control.start()

openscreen = exio.Screen((0,0,0),1,True,(0,0))
name = exio.TextInput(screen=openscreen,message="subject name", position=(10,20), gap=2)
age = exio.TextInput(screen=openscreen,message="subject age", position=(10,50))
name.get()
age.get()
expyriment.control.end()

#from expyriment import control, stimuli, design, misc
#
#digit_list = [1, 2, 3, 4, 6, 7, 8, 9] * 12
#design.randomize.shuffle_list(digit_list)
#
#exp = control.initialize()
#exp.data_variable_names = ["digit", "btn", "rt", "error"]
#
#control.start(exp)
#
#for digit in digit_list:
#    target = stimuli.TextLine(text=str(digit), text_size=80)
#    exp.clock.wait(500 - stimuli.FixCross().present() - target.preload())
#    target.present()
#    button, rt = exp.keyboard.wait([misc.constants.K_LEFT, misc.constants.K_RIGHT])
#    error = (button == misc.constants.K_LEFT) == digit%2
#    if error: stimuli.Tone(duration=200, frequency=2000).play()
#    exp.data.add([digit, button, rt, int(error)])
#    exp.clock.wait(1000 - stimuli.BlankScreen().present() - target.unload())
#
#control.end(goodbye_text="Thank you very much...", goodbye_delay=2000)
