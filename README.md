# 617.2


The scripts in scripts/climb contain the code to:
1. date trees in lineage 617.2 (compare_lineages_d1_B.1.617.2.R)
2. date trees in lineage 1.1.7 (compare_lineages_d1_B.1.1.7_control.R)
3. run mlesky on dated trees 617.2 (mlesky_d1_B.1.617.2.R)
4. run mlesky on dated trees 1.1.7 (mlesky_d1_B.1.1.7_control.R)

What is required is a directory with ML trees for both lineages in nwk filetype.

The code is mostly generalisable but not totally so needs to be edited a bit with new analyses.

Basically, the R scripts will be on climb. The bash files point towards those R scripts. You use 'sbatch <bashscript>' to launch them. So you'll need to launch 2 jobs to date the two linages, then once that's done, you'll need to launch 2 more jobs to run mlesky.

Edit R scripts:
in compare_lineages_xxx.R:
- Make sure the civetfn definition is reading the latest md file
- Make sure mltr_list is pointing to the correct dir with all the ml trees

Upload the R scripts to climb

Edit the bash files:
- date_trees_xxx.sh bash files need to point to the R script with the correct path on line 12. at the moment it's pointing to an R script in my dir but you'll need to point it to yours. Make sure it's pointing to the R script of the same name though.


To date trees: 
- bash files in /bash need to be climb
- also the R files in scripts/climb need to be on climb
- navigate to dir with the bash files
- type in console: 'sbatch date_trees_climb_B.1617.2.sh' this launches the tree dating script for 6172
- type in console: 'sbatch date_trees_climb_B.1.1.7_control.sh' this launches the tree dating script for 117
- to check the progress of the jobs you can type in console 'squeue  -u climb-covid19-geidelbergl -O jobid,name:30,username:30,state,timeused,nodelist' but edit for your username


Edit R scripts:
in mlesky_d1_xxx.R
- again make sure civetfn is up to date metadata file
- again make sure it's finding the correct ML trees
- when run_mlesky is called, make sure it's reading in the correct dated trees, and make sure the output file name (arg 'ofn') is good

Upload R scripts to climb

Edit bash files:
- the mlesky_climb_xxx.sh files also need to have the path changed to the correct dir. Again make sure it's pointing to the R script of the same name.



Once you have the dated trees in rds form in your dir, to run mlesky:
- 'sbatch mlesky_climb_B.1.617.2.sh'
- 'sbatch mlesky_climb_B.1.1.7_control.sh'


If you have problems, Radoslaw is really helpful

