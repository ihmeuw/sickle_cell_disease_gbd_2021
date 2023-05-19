import os
import argparse
import numpy as np
import pandas as pd
from get_draws.api import get_draws
from db_queries import get_demographics, get_demographics_template


##############################################################################
# the code to run hardy weinberg
##############################################################################

def hardy_weinberg(output_me_id, year_id,release_id,out_dir):
	epi_demographics = get_demographics(gbd_team="epi", release_id=release_id) #run this function to get all of the location_ids in the GBD
	loc_vec = epi_demographics['location_id'] #extract the location IDs
	hw_map = pd.read_csv("FILEPATH/hw_me_map.csv")
	selector = (hw_map['output_me_id'] == output_me_id)
	input_me_id_vec = hw_map.loc[selector,'input_me_id'].values
	multiplier = int(hw_map.loc[selector,'hetero_multiplier'].values[0])
	df = get_draws("modelable_entity_id",input_me_id_vec,location_id=loc_vec,year_id=year_id,measure_id=5,age_group_id=164,source="epi",release_id=release_id) #run the get_draws call, and only pull information for age_group_id=164
	if len(input_me_id_vec) > 1:
		df = df.groupby(['location_id','sex_id','age_group_id','measure_id','year_id','metric_id']).sum()

	draw_cols = ["draw_{i}".format(i=i) for i in range(0, 1000)] #get the col names of each draw in the df 
	for col in draw_cols: #for each draw_col
		"""
		This for-loop utilizes the Hardy Weinberg approach for calculating allele frequencies. There are two HW equations that we utilize, shown below:

		1) p^2 + 2pq + q^2 = 1
		2) p + q = 1
		where p is the frequency of the dominant allele in a population and q is the frequency of the recessive allele in a population.
		
		We are interested in finding the heterozygous gene frequency (2pq), which is the frequency of the "carriers", which is calculated by using the following steps:
		- We know the value for q^2 (which represents the prevalence of a genetic disease), which is returned from the get_draws call
		- Therefore, we can square root the values from the get_draws call to calculate q
		- Using equation 2, we can also say that p = 1 - q
		- Substituting those values into the heterozygous term in equation 1 (2pq -> 2q(1-q)), we can calculate the heterozygous frequency of each genetic disease.
		- Note: Hemoglobin E trait is derived from the compound heterozygous genoytype B(0)E, therefore its heterozygous frequency only needs to be multiplied by 1 instead of 2 (pq instead of 2pq, respectively), hence the `multiplier` variable
		"""
		df[col] = df[col].apply(np.sqrt,axis=0) #solve for p by squarerooting each value in the get_draws result
		df[col] = int(multiplier) * df[col] * (1 - df[col]) #solve for the heterozygous gene frequency

	file_nombre = out_dir+"/hw_"+str(year_id)+"_"+str(output_me_id)+".csv"
	df.to_csv(file_nombre) #write out the result

##############################################################################
# when called as a script
##############################################################################


if __name__ == "__main__":

	# parse command line args
	parser = argparse.ArgumentParser()
	parser.add_argument("output_me_id", help="the output modelable entity ID", type=int)
	parser.add_argument("year_id", type=int, help='year id to run')
	parser.add_argument("release_id", help="release id for calculation", type=int)
	parser.add_argument("out_dir", help="The output directory where the .csv files will be saved", type=str)
	
	args = parser.parse_args()
	
	hardy_weinberg(args.output_me_id ,args.year_id,args.release_id,args.out_dir)
