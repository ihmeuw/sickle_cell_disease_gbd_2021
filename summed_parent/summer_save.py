import pandas as pd
from save_results import save_results_epi

from datetime import date


release_id = 9
output_folder = "FILEPATH"
output_me = 18679


save_results_epi(
  input_dir = output_folder,
  input_file_pattern = '{location_id}.csv',
  modelable_entity_id = output_me,
  description="Sum of sub MEs (2097, 2100, 2103)",
  release_id = release_id,
  measure_id = [5,15],
  birth_prevalence = True,
  mark_best=True,
  bundle_id=209, 
  crosswalk_version_id= 35012 ## this is in fact just a 209 crosswalk version but for the purpose of passing this function, need to supply
)
