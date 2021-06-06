
library( ape ) 
library( lubridate )
library( treedater ) 
library(alakazam)
require(stringi)
require( mlesky )

run_mlesky <- function(tds_list, ofn, taxis) {
  
  if(!inherits(tds_list, what = c("list")))
    tds_list = readRDS(tds_list)
  
  res_mlesky_list = lapply(tds_list, function(tds) {
    
    weeks = round(as.numeric((date_decimal(max(tds[[1]]$sts))-date_decimal(min(tds[[1]]$sts)))/7))
    res <- weeks * 2
    class( tds ) <- 'multiPhylo' 
    
    tds = lapply( tds , 
                  function(x) {x$tip.label = unlist(lapply(strsplit(x$tip.label, '[|]'), function(y) paste0(y[1])))
                  return(x)}
    )
    
    NeStartTimeBeforePresent =  max( tds[[1]]$sts ) - min( tds[[1]]$sts )
    print(paste0("NeStartTimeBeforePresent = ", NeStartTimeBeforePresent))
    
    sgs = parallel::mclapply( tds, function(td) {
      mlskygrid(td, tau = NULL, tau_lower=.001, tau_upper = 10 , sampleTimes = td$sts , res = res, ncpu = 3, NeStartTimeBeforePresent = NeStartTimeBeforePresent)
    }, mc.cores = 10 )
    
    
    out = lapply(sgs, function(sg) {
      with( sg, approx( time, ne, rule = 1, xout = taxis )$y )
    })
    
    out
    
  })
  
  
  # I am collapsing the results from all alignments and all dated trees together as one.
  res_mlesky <- 
    do.call( cbind, lapply(res_mlesky_list, function(x) do.call( cbind, x ) ))
  
  saveRDS( list( time = taxis, ne = res_mlesky ) , file=paste0(ofn, "_mlesky", '.rds' ))
  
  res_mlesky
  
}




# metadata 
civetfn =  list.files(  '/cephfs/covid/bham/results/msa/20210604/alignments/' , patt = 'cog_[0-9\\-]+_metadata.csv', full.names=TRUE) #'../phylolatest/civet/cog_global_2020-12-01_metadata.csv'
civmd = read.csv( civetfn , stringsAs=FALSE , header=TRUE )
civmd$central_sample_id=civmd$sequence_name
civmd$sample_date <- as.Date( civmd$sample_date )
civmd$sample_time <- decimal_date( civmd$sample_date ) 


mltr_fn = 'B.1.1.7'
mltr_list = list.files(  '/cephfs/covid/bham/climb-covid19-geidelbergl/617.2/f0-trees' , patt = mltr_fn, full.names=TRUE)
mltr = lapply(mltr_list, read.tree)

sts <- lapply(mltr, function(x) {
  civmd$sample_time[  match( x$tip.label , civmd$central_sample_id ) ]
})

taxis = decimal_date( seq( as.Date(date_decimal(min(unlist(sts)))) , as.Date(date_decimal(max(unlist(sts)))), by = 1) )




res_mlesky = run_mlesky(tds_list = "/cephfs/covid/bham/climb-covid19-geidelbergl/617.2/Sample_England_controlB.1.1.7_n_tree_dating_5_dated_trees.rds",
                        ofn = "/cephfs/covid/bham/climb-covid19-geidelbergl/617.2/Sample_England_controlB.1.1.7_n_tree_dating_5_dated_trees_mlesky.rds",
                        taxis = taxis)

