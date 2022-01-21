# pset_seq
a norns mod to sequence psets

pset_seq is a simple mod that lets you sequence script psets.

### Requirements

- norns

### Documentation

you can install *pset_seq* and then activate the mod in `SYSTEM > MODS > PSET_SEQ`. after activating for the first time you need to restart `SYSTEM > RESTART`. 

after installation you can activate the sequencer by going to `PARAMETERS > EDIT > PSET_SEQUENCER`. 

In the `PSET_SEQUENCER` sub-menu you'll find the following parameters to control the sequencer:

* `mod midi port`: sets the midi port (set in SYSTEMS>DEVICES>MIDI) of the device that can be used to send program changes to load a new pset
* `mod midi in`: sets the name device assigned to the selected `mod midi port` that can be used to send program changes to load a new pset
* `pset seq enabled`: turns the sequencer on and off
* `pset seq mode`: there are four modes:
  * `loop`: loads the psets in order returning to the first pset after the last one has loaded
  * `up/down`: loads the psets in order, with the load order reversed after the last pset or first pset has been loaded.
  * `random`: randomly loads the psets
  * `load pset`: manually loads a pset (note:this works whether or not the sequencer has been enabled)
* `pset seq beats` and `pset seq beats per bar`: the combination of these two parameters sets the frequency in which a new pset gets loaded. the formula is:
  * `clock tempo` * (`pset seq beats` / `pset seq beats per bar`)  
* `first` and `last`: the first and last psets to be used by the pset sequencer may be set with these two parameters
* `<<reset first/last range>>`: resets the first and last parameters (this is used to refresh the parameters if a new pset has been added to the script)

TODO<br>
* enable `pset exclusion sets`: this will allow parameters to be excluded from the pset sequencer so they may be adjusted while the pset sequencer is running. 
* replace metro with lattice

### Download

```
;install https://github.com/jaseknighter/pset_seq
```

https://github.com/jaseknighter/pset_seq
