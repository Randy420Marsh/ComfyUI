#!/bin/bash

echo "Activating venv..."

cd $PWD

export MORE_STARTUP=$PWD/activate-venv

exec bash
