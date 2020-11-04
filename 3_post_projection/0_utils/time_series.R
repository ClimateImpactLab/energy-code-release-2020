# Timeseries function

# This function returns a global timeseries from projection impacts

#----------------------------------------------------------------------------------

library(ggplot2)

#create function that plots timeseries
ggtimeseries <- function(df.list = NULL, 
                         df.u = NULL, df.x = "year",
                         ub = NULL, lb = NULL, 
                         ub.2 = NULL, lb.2 = NULL, 
                         ub.3 = NULL, lb.3 = NULL, 
                         uncertainty.color = "black", 
                         uncertainty.color.2 = "black", 
                         uncertainty.color.3 = "black", 
                         df.box = NULL, df.box.2 = NULL, 
                         #uncertainty.legend.title = "Upper and lower cost bounds", 
                         start.yr = 2000, end.yr = 2099, 
                         legend.title = "Adaptation", legend.breaks = c("full adaptation", "income adaptation", "no adaptation", "total mortality-related costs"), 
                         legend.values = c("#009E73", "#E69F00", "#D55E00", "#000000"), 
                         x.label = "Year", y.label = "Deaths per 100,000", 
                         y.limits = NULL, x.limits = c(2000, 2100),
                         rcp.value = NULL, ssp.value = NULL, iam.value = NULL) {
  
  #base plot
  p <- ggplot() + 
    geom_hline(yintercept=0, size=.2) + #zerolin* e
    scale_x_continuous(expand=c(0, 0), limits=c(start.yr, end.yr)) +
    scale_colour_manual(name=legend.title, breaks=legend.breaks, values=legend.values) + 
    scale_alpha_manual(name="", values=c(.7)) +
    theme_bw() +
    theme(panel.grid.major = element_blank(), 
          panel.grid.minor = element_blank(),
          panel.background = element_blank(), 
          axis.line = element_line(colour = "black")) +
    xlab(x.label) + ylab(y.label) +
    coord_cartesian(ylim = y.limits, xlim = x.limits)  +
    #theme(legend.position = c(0.15, 0.85)) +
    ggtitle(paste0(rcp.value,"-", ssp.value, "-", iam.value)) 

    

  if (!is.null(ub)){ #plot uncertainty
    p <- p + geom_ribbon(data = df.u, aes(x=df.u[,df.x], ymin=df.u[,ub], ymax=df.u[,lb]), fill = uncertainty.color, linetype=2, alpha=0.2) 
  }
  
  if (!is.null(ub.2)){ #plot 2nd layer uncertainty
    p <- p + geom_ribbon(data = df.u, aes(x=df.u[,df.x], ymin=df.u[,ub.2], ymax=df.u[,lb.2]), fill = uncertainty.color, linetype=2, alpha=0.2)  #plot 2nd layer uncertainty
  }
  
  if (!is.null(ub.3)){ #plot 2nd layer uncertainty
    p <- p + geom_ribbon(data = df.u, aes(x=df.u[,df.x], ymin=df.u[,ub.3], ymax=df.u[,lb.3]), fill = uncertainty.color, linetype=2, alpha=0.2)  #plot 3rd layer uncertainty
  }
  
  if (!is.null(df.list)){ #plot timeseries
    
    #assign model names to each data frame
    for (j in seq_along(df.list)){
      df.list[[j]]$model <- legend.breaks[j]
    }
    df <- do.call("rbind", df.list)
    
    p <- p + geom_line(data=df, aes(x=df[,1], y=df[,2], color=model), alpha = 1, size=1) #plot adaptation scenario lines
  }

  if(!is.null(df.box)){ #plot first boxplot
    p <- p + geom_errorbar(aes(x=(end.yr+3), ymin = df.box[1], ymax = df.box[7]), color = "tomato4", lty = "dotted", width = 0) + #errorbar rcp85
        geom_boxplot(aes(x=(end.yr+3), ymin = df.box[2], lower = df.box[3], middle = df.box[4], upper = df.box[5], ymax = df.box[6]), #boxplot rcp85
                     width = 2, size = 0.5, fill="tomato2", color="tomato4", stat = "identity", alpha = 1) +
        scale_x_continuous(expand=c(0, 0), limits=c((x.limits[1]), (x.limits[2] + 2))) +
        coord_cartesian(ylim = y.limits, xlim = c(x.limits[1], (x.limits[2] + 2)))
  }
  
  if(!is.null(df.box.2)){ #plot second boxplot
    p <- p + geom_errorbar(aes(x=(end.yr+7), ymin = df.box.2[1], ymax = df.box.2[7]), color = "steelblue4", lty = "dotted", width = 0) + #errorbar rcp85
      geom_boxplot(aes(x=(end.yr+7), ymin = df.box.2[2], lower = df.box.2[3], middle = df.box.2[4], upper = df.box.2[5], ymax = df.box.2[6]), #boxplot rcp85
                   width = 2, size = 0.5, fill="steelblue2", color="steelblue4", stat = "identity", alpha = 1) +
      scale_x_continuous(expand=c(0, 0), limits=c((x.limits[1]), (x.limits[2] + 8))) +
      coord_cartesian(ylim = y.limits, xlim = c(x.limits[1], (x.limits[2] + 8)))
  }
    

  return(p)
} 
