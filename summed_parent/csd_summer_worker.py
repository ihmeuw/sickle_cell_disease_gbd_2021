from argparse import ArgumentParser
from get_draws.api import get_draws
from db_queries import get_demographics
import pandas as pd
import os


user="USERNAME"
release_id = 9
output_folder = "FILEPATH"
ME_list = [2097, 2100, 2103]
measures = [5, 15]

if __name__ == '__main__':
  parser = ArgumentParser()
  parser.add_argument('--loc', type=int)
  args = parser.parse_args()
  loc = args.loc
  
  demo = get_demographics('epi', release_id = release_id)
  ages = demo['age_group_id'] + [164]
  
  sum_df = None
  counter = 0
  checker = []
  
  for me in ME_list:
    print(me)
    print(loc)
    df = get_draws('modelable_entity_id',me, source='epi', measure_id=measures, location_id=loc, 
                   release_id = release_id,
                   sex_id=[1,2], age_group_id = ages)
    df = df.drop(columns=['model_version_id', 'modelable_entity_id'])
    df = df.set_index(['age_group_id', 'sex_id', 'location_id', 'year_id', 'measure_id', 'metric_id'])
  
    if sum_df is None:
      sum_df = df
      checker.append(df.loc[2, 1, loc, 1990]['draw_100'])
    else:
      sum_df = sum_df + df
      checker.append(df.loc[2, 1, loc, 1990]['draw_100'])
  
  print(checker)
  print(sum(checker))
  print(sum_df.loc[2, 1, loc, 1990]['draw_100'])
  
  sum_df.to_csv(os.path.join(output_folder, f'{loc}.csv'))
