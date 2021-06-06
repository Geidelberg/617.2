# NOTE THAT FOR PUBLIC RELEASE THIS IS RENAMED d3!
require(ggplot2)
require(lubridate)
library(cowplot)
library(grid)
library(gridExtra)


plot_mlesky <- function(ofn, ofn2, Lineage_main, Lineage_matched, dedup, meanrate) {
  tN = readRDS( ofn )
  tN2 = readRDS( ofn2 )
  
  ## serial intervals
  si = c(0.0183261824523828, 0.0665923069549798, 0.10191389126982, 0.11771677925845, 
         0.118385594423979, 0.1096347062151, 0.0961232167086674, 0.0810548507317701, 
         0.0663831287123141, 0.0531489564979809, 0.0417894990491873, 0.0323750573522434, 
         0.0247742309894593, 0.0187612758047075, 0.0140813981461474, 0.0104874277075941, 
         0.00775805851929146, 0.0057048545673487, 0.00417284495185088, 
         0.00303779925570447, 0.00220207207827872, 0.00159010774803958, 
         0.00114418671426919, 0.000820682873170497, 0.000586918953808024, 
         0.000418607884427491, 0.000297819806188371, 0.000211396110753381, 
         0.000149730189133779, 0.000105841261787254, 7.46778409554949e-05, 
         5.25983179138212e-05, 3.69864509106588e-05, 2.59685201488002e-05, 
         1.82064265847881e-05, 1.27470903972249e-05, 8.91331245966853e-06, 
         6.22499658997633e-06, 4.34249018810284e-06, 3.02596564560886e-06, 
         2.10638769937432e-06, 1.46481847063118e-06, 1.01770269167467e-06
  )
  si = si / sum( si )
  
  
 
  
  
  # attach( tN )
  q_ne = t(apply( tN$ne, 1, function(x) quantile( na.omit(x), c(.5, .025, .975 )) ))
  q_mane = t(apply( tN2$ne, 1, function(x) quantile( na.omit(x), c(.5, .025, .975 )) ))
  
  
  lb = 14 # days to look back in moving window 
  gr =  apply( tN$ne, 2, function(x) {
    lx = length( x) 
    x0 = head( x , lx - lb )
    x1 = tail(x, lx - lb ) 
    r = c( rep(NA, lb ), log( x1 / x0 )/lb )
    #r = c( NA, diff(log(x))   )
    R = rep( NA, length(r) )
    R[ !is.na(r) ] <- epitrix::r2R0( r[!is.na(r)], si )
    R
  }) 
  magr =  apply( tN2$ne, 2, function(x){
    lx = length( x) 
    x0 = head( x , lx - lb )
    x1 = tail(x, lx - lb ) 
    r = c( rep(NA, lb ), log( x1 / x0 )/lb )
    #r = c( NA, diff(log(x))   )
    R = rep( NA, length(r) )
    R[ !is.na(r) ] <- epitrix::r2R0( r[!is.na(r)], si )
    R
  })
  
  
  # gr =  apply( tN$ne, 2, function(x) c(exp( diff(log(x)) )^6.5, NA)  ) 
  # magr =  apply( tN2$ne, 2, function(x) c(exp( diff(log(x)) )^6.5, NA)  ) 
  
  q_gr = t( apply( gr, 1, function(x) quantile( na.omit(x), c(.5, .025, .975 )) ) )
  q_magr = t( apply( magr, 1, function(x) quantile( na.omit(x), c(.5, .025, .975 )) ) )
  
  colnames( q_ne ) = colnames( q_mane ) = c( 'y', 'ylb', 'yub' )
  pldf0 = as.data.frame( q_ne ) ; pldf0$Lineage = Lineage_main; pldf0$time = tN$time
  pldf1 = as.data.frame( q_mane ); pldf1$Lineage = Lineage_matched; pldf1$time = tN2$time
  pldf = rbind( pldf0, pldf1 )
  
  p0 = ggplot( aes(x = as.Date( date_decimal( time)), y = y, colour = Lineage, fill = Lineage , ymin = ylb, ymax = yub ) ,
               data = pldf ) +
    geom_path(size=1) + geom_ribbon( alpha = .25, col = NA ) + xlab('') + ylab('Effective population size' ) +
    theme_minimal() + theme(legend.position='none',panel.grid.minor = element_blank())+
    scale_x_date(date_breaks = "1 month", date_labels = '%b')+theme(axis.text=element_text(size=12),
                                                                    axis.title=element_text(size=14)) + scale_y_log10()+
    annotation_logticks(colour = 'grey', short = unit(.05, "cm"), mid = unit(.05, "cm"), long = unit(.05, "cm"))
  
  colnames( q_gr ) = colnames( q_magr ) = c( 'y', 'ylb', 'yub' )
  gpldf0 = as.data.frame( q_gr ) ; gpldf0$Lineage = Lineage_main; gpldf0$time = tN$time
  gpldf1 = as.data.frame( q_magr ); gpldf1$Lineage = Lineage_matched; gpldf1$time = tN2$time
  gpldf = rbind( gpldf0, gpldf1 )
  
  Rratio = gr / magr
  qRr =  t( apply( Rratio, 1, function(x) quantile( na.omit(x), c(.5, .025, .975 )) ) )
  colnames( qRr ) =  c( 'y', 'ylb', 'yub' )
  Rrpldf = as.data.frame( qRr ); Rrpldf$time = tN$time
  
  
  r_range = range(c(gpldf$yub, Rrpldf$yub, gpldf$ylb, Rrpldf$ylb), na.rm = T)
  
  p1 =  ggplot( aes(x = as.Date( date_decimal( time)), y = y, colour = Lineage, fill = Lineage , ymin = ylb, ymax = yub ) , 
                data = gpldf ) +
    geom_path(size=1) + geom_ribbon( alpha = .25 , col = NA) + xlab('') + ylab('Reproduction number' ) + theme_minimal() +
    scale_y_log10(limits = r_range) + annotation_logticks(colour = 'grey', short = unit(.05, "cm"), mid = unit(.05, "cm"), long = unit(.05, "cm"))   +
    geom_hline( aes( yintercept=1), lty = 2 )  + theme(legend.position='', panel.grid.minor = element_blank())+
    scale_x_date(date_breaks = "1 month", date_labels = '%b')+
    theme(axis.text=element_text(size=12),
          axis.title=element_text(size=14))
  
  p2 = ggplot( aes(x = as.Date( date_decimal( time)), y = y, ymin = ylb, ymax = yub ) , data = Rrpldf ) + geom_path(size=1) +
    
    geom_ribbon( alpha = .25, col = NA ) + xlab('') + ylab('Ratio of reproduction numbers' ) + theme_minimal() +
    scale_y_log10(limits = r_range) + annotation_logticks(colour = 'grey', short = unit(.05, "cm"), mid = unit(.05, "cm"), long = unit(.05, "cm")) + theme( panel.grid.minor = element_blank())+
    geom_hline( aes( yintercept=1), lty = 2 ) +scale_x_date(date_breaks = "1 month", date_labels = '%b')+
    theme(axis.text=element_text(size=12),  axis.title=element_text(size=14))
  
  legend <- cowplot::get_legend(
    p1 + theme(legend.box.margin = margin(0, 0, 0, 12), legend.position = "top", legend.title = element_text(size=14), legend.text =element_text(size=12) )
  )
  
  
  # p1 + annotate("rect", xmin=as.Date("2020-11-05"), xmax=as.Date("2020-12-01"), ymin=0, ymax=Inf, alpha = 0.512, fill = "grey", col = "grey")+
  #   annotate("rect", xmin=as.Date("2021-01-05"), xmax=as.Date("2021-01-23"), ymin=0, ymax=Inf, alpha = 0.512, fill = "grey", col = "grey")
  
  
  
  
  P0 = cowplot::plot_grid( plotlist = list( p0, p1, p2 ), nrow = 1, align = "v" )
  
  P0 = cowplot::plot_grid(legend, P0, ncol = 1, rel_heights =  c(0.1, 1))
  
  ggsave( plot = P0, file = paste0('./617.2/results/d1_', Lineage_main, '_', Lineage_matched, dedup, '_', "meanrate", meanrate, '.pdf'), width = 12, height = 4.5 )
  
  print(P0)
  
  Time=tN$time
  
  # detach(tN)
  return(list(ofn = ofn, 
              time = Time,
              pldf0 = pldf0,
              gpldf0 = gpldf0,
              q_ne = q_ne
  ))
}




plot_mlesky(ofn ="./617.2/results/Sample_England_B.1.617.2_n_tree_dating_5_dated_trees_mlesky.rds_mlesky.rds",
            ofn2 ="./617.2/results/Sample_England_controlB.1.1.7_n_tree_dating_5_dated_trees_mlesky.rds_mlesky.rds", 
            Lineage_main = "B.1.617.2",
            Lineage_matched = "B.1.1.7",
            dedup = "", meanrate = "sampled" )

