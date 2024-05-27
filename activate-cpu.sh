#!/bin/bash

echo "Activating venv-cpu..."

cd $PWD

export MORE_STARTUP=$PWD/activate-venv-cpu

exec bash
