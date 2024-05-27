Add this blob of code to ~/.bashrc
for the venv activation script to work if needed

from terminal run:
nano ~/.bashrc
and add to the bottom of the file

############
if [ -f "$MORE_STARTUP" ]; then
    . $MORE_STARTUP
elif [ -n "$MORE_STARTUP" ]; then
    echo "Warning! Could not run ${MORE_STARTUP}"
fi
###########

source: https://superuser.com/questions/1701789/how-can-i-have-a-terminal-window-persist-beyond-the-script-it-was-opened-for-n

then create venv-activate:

###########
#!/bin/bash
cd $PWD
source ./venv/bin/activate
echo "venv activated"
python --version
###########

and activate.sh:

###########
#!/bin/bash
echo "Activating venv..."
cd $PWD
export MORE_STARTUP=$PWD/activate-venv
exec bash
###########

Run: sudo chmod +x ./activate.sh
to make it executable.
./activate.sh should now activate the venv and display python version:D

for reference...
/usr/bin/python --version
./venv/bin/python --version
