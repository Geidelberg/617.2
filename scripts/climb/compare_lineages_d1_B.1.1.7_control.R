# Maximum likeihood estimation of Ne(t) from resampled ML trees
# Designed to be run on CLIMB server to retrieve sample time information

library( ape )
library( lubridate )
library( glue )
library( mlesky )
library( treedater ) 

library( sarscov2 ) 
require(ggplot2)
require(grid)
require(gridExtra)
require(ggtree)
library(alakazam)
require(stringi)



#95% HPD interval	[5.2065E-4, 6.7144E-4]
mr = 5.9158E-4
mrci = 	c( 5.2065E-4, 6.7144E-4)
mrsd = diff( mrci ) / 4 / 1.96





# metadata 
civetfn =  list.files(  '/cephfs/covid/bham/results/msa/20210604/alignments/' , patt = 'cog_[0-9\\-]+_metadata.csv', full.names=TRUE) #'../phylolatest/civet/cog_global_2020-12-01_metadata.csv'
civmd = read.csv( civetfn , stringsAs=FALSE , header=TRUE )
civmd$central_sample_id=civmd$sequence_name
civmd$sample_date <- as.Date( civmd$sample_date )
civmd$sample_time <- decimal_date( civmd$sample_date ) 



datetree <- function(mltr, civmd, meanrate)
{
  sts <- setNames( civmd$sample_time[  match( mltr$tip.label , civmd$central_sample_id ) ], mltr$tip.label )
  tr <- di2multi(mltr, tol = 1e-05)
  tr = unroot(multi2di(tr))
  tr$edge.length <- pmax(1/29000/5, tr$edge.length)
  dater(unroot(tr), sts[tr$tip.label], s = 29000, omega0 = meanrate, numStartConditions = 0, meanRateLimits = c(meanrate, meanrate + 1e-6), ncpu = 6)
}

date_trees <- function(ofn, n_tree_dating = 10, civmd, meanrate, meanratesd, ncpu = 4, ...)
{
  
  mltr_fn = 'B.1.1.7'
  mltr_list = list.files(  '/cephfs/covid/bham/climb-covid19-geidelbergl/617.2/f0-trees' , patt = mltr_fn, full.names=TRUE)
  
  mltr = lapply(mltr_list, read.tree)

  # checking all samples have metadata attached... removing tips that aren't able to be matched
  mltr = lapply(mltr, function(tr) ape::drop.tip(tr, tr$tip.label[!tr$tip.label %in% civmd$central_sample_id]))
  
  
  tds = parallel::mclapply(mltr, function(tr) {
    tmp = lapply(1:n_tree_dating, function(x) {
      td = datetree( tr , civmd = civmd, meanrate =  max( 0.0001, rnorm( 1, meanrate, sd = meanratesd ) ) )
      td$tip.label =  paste0(td$tip.label, '|', as.Date(date_decimal(td$sts)), '|', td$sts )
      td
    })
    tmp
  }, mc.cores = ncpu)
  
  saveRDS( tds , file=paste0(ofn, "_dated_trees", '.rds' ))
  
  tds
}



# make treedater trees for each ML tree.
tds_list = date_trees(ofn = paste0('Sample_England_', 'controlB.1.1.7', '_n_tree_dating_', n_tree_dating), civmd = civmd, 
                      meanrate = mr,n_tree_dating = 5,
                      meanratesd = mrsd, ncpu = 4)

