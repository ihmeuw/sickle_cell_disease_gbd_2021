##' ***************************************************************************
##' Title: disease_change_decomposition.R
##' Purpose: Decompose change of a disease metric into growth, aging and frequency
##' ***************************************************************************

Sys.umask(mode = 002)


args <- commandArgs(trailingOnly = TRUE)
table <- args[1]
release <- args[2]
compare_version_id_como <- args[3]
sex <- args[4]




library(data.table)
library(ggplot2)
library(openxlsx)
library(dplyr)
select <- dplyr::select
library(stringr)
library(readxl)
invisible(sapply(list.files("FILEPATH", full.names = T), source))


lm <- get_location_metadata(91, release_id = release)
locations <- unique(lm$location_id)

am <- get_age_metadata(release_id = release)
ages <- unique(am$age_group_id)


root_dir <- "FILEPATH"

savedir <- "FILEPATH"
if (!(dir.exists(savedir))){
  dir.create(savedir)
}
#------------------------------------------
# 1. Get all pop for years we are analyzing change 
#---------------------------------------
allpop_2000 <- get_population(release_id = release,age_group_id = 22, sex_id = sex, location_id = locations, year_id = 2000)
setnames(allpop_2000, 'population', 'all_pop')
allpop_2000[, c('age_group_id', 'run_id') := NULL]

allpop_2021 <- get_population(release_id = release, age_group_id = 22, sex_id = sex, location_id = locations, year_id = 2021)
setnames(allpop_2021, 'population', 'all_pop')
allpop_2021[, c('age_group_id', 'run_id') := NULL]
#------------------------------------------
# 2. Get age specific pop for years we are analyzing change 
#---------------------------------------
age_pop_2000 <- get_population(release_id = release, age_group_id = ages, sex_id = sex, location_id = locations, year_id = 2000)
age_pop_2021 <- get_population(release_id = release, age_group_id = ages, sex_id = sex, location_id = locations, year_id = 2021)

#------------------------------------------
# 3. Calculate age structure for years we are analyzing change 
#---------------------------------------
age_struc_2000 <- merge(age_pop_2000, allpop_2000, by = c('location_id', 'year_id', 'sex_id'))
age_struc_2000[, pop_prop_2000 := population/all_pop]
setnames(age_struc_2000, 'population', 'age_pop_2000')
setnames(age_struc_2000, 'all_pop', 'all_pop_2000')
age_struc_2000 <- age_struc_2000[, .(location_id, age_group_id, all_pop_2000, pop_prop_2000, age_pop_2000)]

age_struc_2021 <- merge(age_pop_2021, allpop_2021, by = c('location_id', 'year_id', 'sex_id'))
age_struc_2021[, pop_prop_2021 := population/all_pop]
setnames(age_struc_2021, 'population', 'age_pop_2021')
setnames(age_struc_2021, 'all_pop', 'all_pop_2021')
age_struc_2021 <- age_struc_2021[, .(location_id, age_group_id, all_pop_2021, pop_prop_2021, age_pop_2021)]


age_struc <- merge(age_struc_2000, age_struc_2021, by = c('location_id', 'age_group_id'))
#------------------------------------------
# 4. Get all age prevalence for years we are analyzing change
#---------------------------------------

allage_counts <- get_outputs("cause", 
                             cause_id=615, 
                             metric_id=1, 
                             measure_id=5, 
                             gbd_round_id=7, 
                             decomp_step = 'iterative',
                             compare_version_id = compare_version_id_como,
                             location_id = locations, 
                             year_id = c(2000,2021), 
                             age_group_id = ages,
                             sex_id = sex)

allage_counts <- allage_counts[, .(age_group_id, location_id, year_id, sex, val)]

prev <- dcast(allage_counts, age_group_id + location_id + sex  ~ year_id, value.var = 'val')
prev$sex <- NULL
setnames(prev, c("2000", "2021"), c("prev_2000", "prev_2021"))

#------------------------------------------
# 5. Do calculations
#---------------------------------------
calcs <- merge(prev, age_struc, by  = c('location_id', 'age_group_id'))

calcs <- merge(calcs, lm[, .(location_id, level)], by = 'location_id')


###############
calcs[, prev_2000_counts := prev_2000]
calcs[, prev_2021_counts := prev_2021]

calcs[, prev_2000 := prev_2000/age_pop_2000]
calcs[, prev_2021 := prev_2021/age_pop_2021]


calc_df <- copy(calcs)
calc_df[, prev90_agestruc90 := pop_prop_2000*prev_2000]
calc_df[, prev90_aging := (pop_prop_2021 - pop_prop_2000)*prev_2000] #ipa
calc_df[, agestruc90_frequency:= pop_prop_2000*(prev_2021-prev_2000)] #ipm
calc_df[, aging_frequency := (pop_prop_2021 - pop_prop_2000)*(prev_2021-prev_2000)] #ipam

# Aggregate to all ages
cols <- calc_df %>% select(-c('location_id','age_group_id', 'all_pop_2021', 'all_pop_2000')) %>% names()
agg_calc_df <- calc_df[, lapply(.SD, sum), by = .(location_id), .SDcols = cols]
setnames(agg_calc_df, c('age_pop_2000', 'age_pop_2021'), c('all_pop_2000', 'all_pop_2021'))

agg_calc_df[, mp := (all_pop_2021-all_pop_2000)*prev90_agestruc90]
agg_calc_df[, ma := all_pop_2000*prev90_aging]
agg_calc_df[, mm := all_pop_2000*agestruc90_frequency]

agg_calc_df[, ipa := (all_pop_2021-all_pop_2000)*prev90_aging ]
agg_calc_df[, ipm := (all_pop_2021-all_pop_2000)*agestruc90_frequency]
agg_calc_df[, iam := all_pop_2000*aging_frequency]
agg_calc_df[, ipam := (all_pop_2021-all_pop_2000)*aging_frequency]

agg_calc_df[, aging := ma + (.5*ipa)+(.5*iam)+((1/3)*ipam)]
agg_calc_df[, population := mp + (.5*ipa)+(.5*ipm)+((1/3)*ipam)]
agg_calc_df[, diseasefreq := mm + (.5*ipm)+(.5*iam)+((1/3)*ipam)]

agg_calc_df[, age_percent := (aging/prev_2000_counts)*100]
agg_calc_df[, pop_percent := (population/prev_2000_counts)*100]
agg_calc_df[, df_percent := (diseasefreq/prev_2000_counts)*100]

agg_calc_df[, actual_change := ((prev_2021_counts-prev_2000_counts)/prev_2000_counts)*100]

agg_calc_df[, check := age_percent + pop_percent + df_percent]

agg_calc_df <- merge(agg_calc_df, lm[, .(location_id, location_name, ihme_loc_id)], by = 'location_id')



write.csv(agg_calc_df, "FILEPATH", row.names = F)
