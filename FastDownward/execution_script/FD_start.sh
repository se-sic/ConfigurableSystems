#!/bin/bash

# This is a script that is written to benchmark tar.
# In general, there are 4 non-functional properties that are measured:
# 1. performance
# 2. energy
# 3. size of the compressed file
#OUTPUT_DIR="/scratch/$USER/FastDownward/results6/output_${SLURM_ARRAY_TASK_ID}"
#mkdir -p $OUTPUT_DIR
#OUTPUT_FILE="${OUTPUT_DIR}/output.log"


#add params

Releases_dom_pruning=("2020_06" "2019_12" "2019_06" "2019_01" "2018_07")
Releases_with_sas=("2020_06" "2019_12" "2019_06" "2019_01")
Releases_merge_linear=("2016_01" "2016_07")

params="astar("
em_has_option blind && params="${params}blind()"

#em_has_option max && [[ "$(em_option revisions)" = "2020_06" ]] && params="${params}max()"
#em_has_option max && [[ "$(em_option revisions)" != "2020_06" ]] && params="${params}hmax()" 
em_has_option max && params="${params}hmax()" 


em_has_option canonicalPDB && params="${params}cpdbs()"

em_has_option random && r="random_seed=$(em_option random)"

em_has_option mergeAndShrink && params="${params}merge_and_shrink("
em_has_option labelReduction && params="${params}label_reduction=exact(before_shrinking="
  em_has_option beforeShrinking && params="${params}true"
  em_has_option labelReduction && ! em_has_option beforeShrinking && params="${params}false"
  em_has_option labelReduction && params="${params},before_merging="
    em_has_option beforeMerging && params="${params}true"
    em_has_option labelReduction && ! em_has_option beforeMerging && params="${params}false"
  em_has_option method && params="${params},method="
    em_has_option allSystems && params="${params}ALL_TRANSITION_SYSTEMS"
    em_has_option allSystemsWithFixpoint && params="${params}ALL_TRANSITION_SYSTEMS_WITH_FIXPOINT"
    em_has_option twoSystems && params="${params}TWO_TRANSITION_SYSTEMS"
em_has_option labelReduction && params="${params},${r})"
em_has_option shrinkStrat && params="${params},shrink_strategy="
  em_has_option bisimulation && params="${params}shrink_bisimulation()"
  em_has_option fPreserving && [[ "$(em_option revisions)" = "2016_01" ]] && params="${params}shrink_fh()"
  em_has_option fPreserving && [[ "$(em_option revisions)" != "2016_01" ]] && params="${params}shrink_fh(${r})"
  em_has_option mergeStrat && ! [[ " ${Releases_merge_linear[@]} " =~ " $(em_option revisions) " ]] && params="${params},merge_strategy=merge_precomputed(merge_tree=linear(${r}))"
  em_has_option mergeStrat && [[ " ${Releases_merge_linear[@]} " =~ " $(em_option revisions) " ]] && params="${params},merge_strategy=merge_linear()"

em_has_option mergeAndShrink && params="${params})"

em_has_option landmarkCut && params="${params}lmcut()"
em_has_option landmarkCount && params="${params}lmcount(lm_factory="
em_has_option exhaustiveLM && params="${params}lm_exhaust("
em_has_option hmLM && params="${params}lm_hm(m=$(em_option m),"
em_has_option RHWLM && params="${params}lm_rhw("
em_has_option zhuGivanLM && params="${params}lm_zg("
    em_has_option resonableOrders && params="${params}reasonable_orders=true,"
    em_has_option landmarkCount && ! em_has_option resonableOrders && params="${params}reasonable_orders=false,"
    em_has_option onlyCausalLMs && params="${params}only_causal_landmarks=true,"
    em_has_option landmarkCount && ! em_has_option onlyCausalLMs && params="${params}only_causal_landmarks=false,"
    em_has_option disjunctiveLMs && params="${params}disjunctive_landmarks=true," # this feature didn't work before results5 because of a typo in the feature model... remeasure?
    em_has_option landmarkCount && ! em_has_option disjunctiveLMs && params="${params}disjunctive_landmarks=false,"
    em_has_option conjunctiveLMs && params="${params}conjunctive_landmarks=true,"
    em_has_option landmarkCount && ! em_has_option conjunctiveLMs && params="${params}conjunctive_landmarks=false,"
    em_has_option noOrders && params="${params}no_orders=true)"
    em_has_option landmarkCount && ! em_has_option noOrders && params="${params}no_orders=false)"
    em_has_option landmarkCount && params="${params})"

em_has_option iPDB && params="${params}ipdb(max_time=infinity,"
em_has_option iPDB && [[ " ${Releases_dom_pruning[@]} " =~ " $(em_option revisions) " ]]  && params="${params}max_time_dominance_pruning=0.0,"
em_has_option iPDB && [[ ! " ${Releases_dom_pruning[@]} " =~ " $(em_option revisions) " ]] && params="${params}dominance_pruning=false,"
em_has_option iPDB && params="${params}pdb_max_size=$(em_option pdbMaxSize),collection_max_size=$(em_option collectionMaxSize),num_samples=$(em_option numSamples),min_improvement=$(em_option minImprovement))"

params="${params})"

#add workloads
input_domain_source=""
input_task_source=""

em_has_option data_network_p05 && input_domain_source="${input_domain_source}data-network-opt18-strips/domain.pddl" && input_task_source="${input_task_source}data-network-opt18-strips/p05.pddl"
em_has_option scanalyzer_p11 && input_domain_source="${input_domain_source}scanalyzer-opt11-strips/domain.pddl" && input_task_source="${input_task_source}scanalyzer-opt11-strips/p11.pddl"
em_has_option scanalyzer_p06 && input_domain_source="${input_domain_source}scanalyzer-opt11-strips/domain.pddl" && input_task_source="${input_task_source}scanalyzer-opt11-strips/p06.pddl"
em_has_option sokoban_p13 && input_domain_source="${input_domain_source}sokoban-opt11-strips/domain.pddl" && input_task_source="${input_task_source}sokoban-opt11-strips/p13.pddl"
em_has_option sokoban_p17 && input_domain_source="${input_domain_source}sokoban-opt11-strips/domain.pddl" && input_task_source="${input_task_source}sokoban-opt11-strips/p17.pddl"
em_has_option sokoban_opt08_p04 && input_domain_source="${input_domain_source}sokoban-opt08-strips/domain.pddl" && input_task_source="${input_task_source}sokoban-opt08-strips/p04.pddl"
em_has_option sokoban_opt08_p08 && input_domain_source="${input_domain_source}sokoban-opt08-strips/domain.pddl" && input_task_source="${input_task_source}sokoban-opt08-strips/p08.pddl"
em_has_option transport_p08 && input_domain_source="${input_domain_source}transport-opt14-strips/domain.pddl" && input_task_source="${input_task_source}transport-opt14-strips/p08.pddl"
em_has_option transport_p04 && input_domain_source="${input_domain_source}transport-opt14-strips/domain.pddl" && input_task_source="${input_task_source}transport-opt14-strips/p04.pddl"
em_has_option transport_opt08_p04 && input_domain_source="${input_domain_source}transport-opt08-strips/domain.pddl" && input_task_source="${input_task_source}transport-opt08-strips/p04.pddl"
em_has_option termes_p17 && input_domain_source="${input_domain_source}termes-opt18-strips/domain.pddl" && input_task_source="${input_task_source}termes-opt18-strips/p17.pddl"
em_has_option agricola_p02 && input_domain_source="${input_domain_source}agricola-opt18-strips/domain.pddl" && input_task_source="${input_task_source}agricola-opt18-strips/p02.pddl"
em_has_option hiking_ptesting225 && input_domain_source="${input_domain_source}hiking-opt14-strips/domain.pddl" && input_task_source="${input_task_source}hiking-opt14-strips/ptesting-2-2-5.pddl"
em_has_option hiking_ptesting226 && input_domain_source="${input_domain_source}hiking-opt14-strips/domain.pddl" && input_task_source="${input_task_source}hiking-opt14-strips/ptesting-2-2-6.pddl"
em_has_option hiking_ptesting244 && input_domain_source="${input_domain_source}hiking-opt14-strips/domain.pddl" && input_task_source="${input_task_source}hiking-opt14-strips/ptesting-2-4-4.pddl"
em_has_option elevators_p22 && input_domain_source="${input_domain_source}elevators-opt08-strips/domain.pddl" && input_task_source="${input_task_source}elevators-opt08-strips/p22.pddl"
em_has_option ged_d28 && input_domain_source="${input_domain_source}ged-opt14-strips/domain.pddl" && input_task_source="${input_task_source}ged-opt14-strips/d-2-8.pddl"
em_has_option ged_d43 && input_domain_source="${input_domain_source}ged-opt14-strips/domain.pddl" && input_task_source="${input_task_source}ged-opt14-strips/d-4-3.pddl"
em_has_option visitall_opt11_p05 && input_domain_source="${input_domain_source}visitall-opt11-strips/domain.pddl" && input_task_source="${input_task_source}visitall-opt11-strips/problem05-full.pddl"
em_has_option visitall_opt14_p056 && input_domain_source="${input_domain_source}visitall-opt14-strips/domain.pddl" && input_task_source="${input_task_source}visitall-opt14-strips/p-05-6.pddl"

# Get Release
input_release="$(em_option revisions)"



# Get temporary directory for saving the file to compress.
em_get_persistent_temp_dir
em_get_temp_dir
# Copy the file to the local partition to avoid error that is caused by the NFS.
input="${persistent_temp_dir}"
mkdir -p "$(dirname ${input}/${input_domain_source})"
cp -ru "/scratch/$USER/FastDownward/downward-benchmarks/${input_domain_source}" "${input}/${input_domain_source}"
mkdir -p "$(dirname ${input}/${input_task_source})"
cp -ru "/scratch/$USER/FastDownward/downward-benchmarks/${input_task_source}" "${input}/${input_task_source}"
cp -ru "/scratch/$USER/FastDownward/Release_${input_release}" "${input}/Release_${input_release}"

# For the output, the temporary directory is used, as it will be deleted after the job.
output_file="${temp_dir}/fd_log_${input_task_source}"

mkdir -p "$(dirname ${temp_dir}/${input_task_source}_times.txt)"
# To guarantee the isolation of different jobs, the output (-f) is written
# in a temporary directory which is deleted when the job terminates.
command=(/usr/bin/time -o "${temp_dir}/${input_task_source}_times.txt" -f "%U %M" "${input}/Release_${input_release}/fast-downward.py")
[[ " ${Releases_with_sas[@]} " =~ " $(em_option revisions) " ]] && command+=(--sas-file "${temp_dir}/output.sas")
command+=("${input}/${input_domain_source}" "${input}/${input_task_source}" --search "${params[@]}" )


#echo ${command[@]} >> ~/output.log
# STEP 1: SEARCH
em_begin_step search
# use the binary /usr/bin/time instead of the shell builtin time
# "${command[@]}"  > /dev/null 2>&1

# ${temp_dir}/output.log
pushd .
cd ${temp_dir}
#echo "${command[@]}" >> $OUTPUT_FILE 2>&1
"${command[@]}" > ${temp_dir}/output.log 2>&1
#"${command[@]}" >> ${OUTPUT_DIR}/output.log 2>&1
#"${command[@]}" >> /scratch/$USER/FastDownward/results_random_5/output.log 2>&1
#"${command[@]}" >> /scratch/$USER/FastDownward/results_random_debug_all/${SLURM_JOB_NODELIST}_output.log 2>&1
#"${command[@]}" >> /scratch/$USER/FastDownward/results_unsuc/${SLURM_ARRAY_TASK_ID}_output.log 2>&1
#/usr/bin/time -o "${temp_dir}/${input_task_source}_times.txt" -f "%U %M" "sleep 2"
#sleep 3
popd
em_end_step search

#time_output=$(cat "${OUTPUT_DIR}/${input_task_source}_times.txt")
time_output=$(cat "${temp_dir}/${input_task_source}_times.txt")
# Convert it to an array for further use
time_output=(${time_output})

# Get the needed time
time=${time_output[0]}
#time="1"

# Get the needed memory
memory=${time_output[1]}
#memory="10"

##echo "Time: $time; Memory: $memory" >> $OUTPUT_FILE;
##echo "python3 /scratch/$USER/FastDownward/read_log.py  ${OUTPUT_DIR}/output.log" >> $OUTPUT_FILE 2>&1;
#(cat ${temp_dir}/output.log >> $OUTPUT_FILE)
#internal_output=$(python3 /scratch/$USER/FastDownward/read_log.py  ${OUTPUT_DIR}/output.log)
internal_output=$(python3 /scratch/$USER/FastDownward/read_log.py  ${temp_dir}/output.log)
#internal_output=$(python3 /scratch/$USER/FastDownward/read_log.py /scratch/$USER/FastDownward/results_random_5/output.log)
#internal_output=$(python3 /scratch/${USER}/FastDownward/read_log.py /scratch/${USER}/FastDownward/results_unsuc/${SLURM_ARRAY_TASK_ID}_output.log)
IFS=";"
read -a internal_arr <<< $internal_output
##echo "Internal time: ${internal_arr[0]}; Internal memory: ${internal_arr[1]}" >> $OUTPUT_FILE;

# Pass the values of the NFPs into the stat command

# Execution time (performance)

em_stat search extperformance ${time}
em_stat search intperformance ${internal_arr[0]}

# Maximum memory needed

em_stat search extmemory ${memory}
em_stat search intmemory ${internal_arr[1]}
