import os
import argparse
import numpy as np
import pandas as pd
from save_results import save_results_epi
from db_queries import get_demographics, get_demographics_template

##############################################################################
# the code to save hardy weinberg results
##############################################################################

def upload_hw_results(output_meid,bundle_id,xwalk_id,out_dir,release_id,description):
	epi_demographics = get_demographics(gbd_team="epi", release_id=release_id) #run this function to get all of the age_ids in the GBD
	age_vec = epi_demographics['age_group_id'] #extract the age group IDs
	print(str(description))
	compile_me_data(output_meid,age_vec,out_dir)
	save_results_epi(input_dir=out_dir,
	  input_file_pattern='hw_{year_id}_'+str(output_meid)+'.csv',
		modelable_entity_id=output_meid,
		description=description.replace("_"," "),
		measure_id=5, #should this be 5 or 6??
		metric_id=3,
		release_id=release_id,
		bundle_id=bundle_id,
		crosswalk_version_id=xwalk_id,
		birth_prevalence=True)


def compile_me_data(output_meid,age_vec,out_dir):
	file_vec = os.listdir(out_dir)
	for dis_file in file_vec: #for each file in the directory
		if ".csv" in dis_file: #if it is a .csv file
			file_nombre = out_dir+"/"+dis_file # call the file name
			df =  pd.read_csv(file_nombre)
			df = compile_ages(df,age_vec)
			df['modelable_entity_id'] = int(output_meid) #set the me id column to the output me id
			#df.to_hdf(file_nombre,key='draws',mode='w',format='table') #export to a csv to be uploaded into the GBD using save_results
			df.to_csv(file_nombre,index=False) #write out the result


def compile_ages(df,age_vec):
	return_df = df.copy()
	for age in age_vec: #for every age
		if age!=164: #and not 164, since that is what is orginially pulled
			df['age_group_id'] = age #make a copy of the df with the new age ID
			return_df = pd.concat([return_df,df]) #r bind that to the data frame that will get returned
	return return_df


##############################################################################
# when called as a script
##############################################################################

if __name__ == "__main__":

	# parse command line args
	parser = argparse.ArgumentParser()

	parser.add_argument("output_meid", help="Hardy Weinberg output MEID", type=int)
	parser.add_argument("bundle_id", help="Bundle id for save_results", type=int)
	parser.add_argument("xwalk_id", help="Crosswalk id for save_results", type=int)
	parser.add_argument("output_dir", help='location of the draws to upload', type=str)
	parser.add_argument("release_id", type=int)
	parser.add_argument("description", help="Description of the model being saved", type=str)

	args = parser.parse_args()

	upload_hw_results(args.output_meid, args.bundle_id, args.xwalk_id, args.output_dir, args.release_id, args.description)
