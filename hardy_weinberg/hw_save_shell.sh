#!/bin/bash
source FILEPATH/activate gbd_env
python 03_save_hw.py "$@"
conda deactivate
