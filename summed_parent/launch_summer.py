from db_queries import get_demographics
import subprocess

user="USERNAME"
release_id = 9
output_folder = "FILEPATH"
ME_list = [2097, 2100, 2103]

demo = get_demographics('epi', release_id = release_id)
locs = demo['location_id']
years = demo['year_id']

error_path="FILEPATH"
output_path="FILEPATH"

## Currently run launch_summer, then once done, run launch_saver . 
for loc in locs:
  jn = f'scd_summer_{loc}'
  call = (f'sbatch  --mem 512M -c 1 -p all.q'
        f' -A proj_nch'
        f' -o {output_path}'
        f' -e {error_path}'
        f' -J {jn}'
        f' cluster_shell.sh'
        f' csd_summer_worker.py'
        f' --loc {loc}')
  subprocess.call(call, shell=True)


## Once summed, now save  
call = (f'sbatch  --mem 100G -c 25 -p all.q'
        # f' -d $(squeue --noheader --format %i --name <std_summer_*>)'
        f' -A proj_nch'
        f' -o {output_path}'
        f' -e {error_path}'
        f' -J summer_save'
        f' cluster_shell.sh'
        f' summer_save.py')
subprocess.call(call, shell=True)

