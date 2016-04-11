# Change Log

## 1.2 (2016-04-11)

Bugfixes:

  - Fixed bug in renaming peaks.

## 1.1 (2016-02-03)

Features

  - New export dialog that allows export of accept, maybe, and reject lists. Users can also now optionally export spectra.
  - Added up / down / left / right controls to the spectra view.
  - Added (a)ccept / (s) maybe / (d) reject controls to the tree view.
  - Excel exports now contain iTRAQ / TMT column labels for each channel.
  - UI now scales properly with window resizes.
  - Added the ability to process arguments from the command line.

Bugfixes:

  - Fixed the list of iTRAQ masses used for iTRAQ 4-plex.
  - Fixed MATLAB errors when moving spectra between accept / maybe / reject lists.
  - Removed trailing tabs from exported Excel files.
  - Fixed TMT 6-plex export to only output 6 channels (Was previously all 10-plex channels)

## 1.0 (2015-11-07)

Initial code written primarily by Tim Curran and Daniel Rothenberg.
