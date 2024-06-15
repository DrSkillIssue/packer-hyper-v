# DrSIPackerHV
PowerShell Module to deploy Packer Virtual Machines to Hyper-V.

## NOTE
For Windows, a secondary ISO is created upon deployment. This process is done via:
* cygwin1.dll
* mkisofs.exe

The above libraries / executables were retrieved via [cdrtools](http://sourceforge.net/projects/cdrtools/)