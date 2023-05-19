#!/bin/bash
source FILEPATH/activate gbd_env
python 02_calc_hw.py "$@"
conda deactivate
