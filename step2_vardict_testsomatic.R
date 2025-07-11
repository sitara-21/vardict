#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
input_file <- args[1]
output_file <- args[2]

  if (!file.exists(output_file)){
 
    print(input_file) 
    myfile <- file(input_file, "r")
    open(myfile, blocking=TRUE)
    myinput = readLines(myfile) # read from stdin
  
    if (length(myinput) > 0 ){
      mynumcols = sapply(gregexpr("\\t", myinput[1]), length) + 1 # count num of tabs + 1
    }else{
      mynumcols = 0
      d = matrix(0,0,0)
    }
  
    if (mynumcols >= 48) {
      d <- read.table( textConnection(myinput), sep = "\t", header = F, colClasses=c("character", NA, NA, NA, NA, "character", "character", NA, NA, NA, NA, NA, NA, "character", NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "character", NA, "character",  NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, "character", "character", "character", "character"))
    } else if (mynumcols > 0){
      stop("Incorrect input detected in testsomatic.R")
    }
  
    if (nrow(d) > 0){
      pvalues1 <- vector(mode="double", length=dim(d)[1])
      oddratio1 <- vector(mode="double", length=dim(d)[1])
      pvalues2 <- vector(mode="double", length=dim(d)[1])
      oddratio2 <- vector(mode="double", length=dim(d)[1])
      pvalues <- vector(mode="double", length=dim(d)[1])
      oddratio <- vector(mode="double", length=dim(d)[1])
  
      for( i in 1:dim(d)[1] ) {
        h <- fisher.test(matrix(c(d[i,10], d[i,11], d[i,12], d[i,13]), nrow=2))
        pvalues1[i] <- round(h$p.value, 5)
        oddratio1[i] <- round(h$estimate, 5)
        h <- fisher.test(matrix(c(d[i,28], d[i,29], d[i,30], d[i,31]), nrow=2))
        pvalues2[i] <- round(h$p.value, 5)
        oddratio2[i] <- round(h$estimate, 5)
        tref <- if ( d[i,8] - d[i,9] < 0 ) 0 else d[i,8] - d[i,9]
        rref <- if ( d[i,26] - d[i,27] < 0 ) 0 else d[i,26] - d[i,27]
        h <- fisher.test(matrix(c(d[i,9], tref, d[i,27], rref), nrow=2), alternative="greater")
        pv <- h$p.value
        od <- h$estimate
        h <- fisher.test(matrix(c(d[i,9], tref, d[i,27], rref), nrow=2), alternative="less")
        if ( h$p.value < pv ) {
          pv <- h$p.value
          od <- h$estimate
        }
        pvalues[i] <- round(pv, 5)
        oddratio[i] <- round(od, 5)
      }
      curscipen <- getOption("scipen")
      options(scipen=999)
      write.table(data.frame(d[,1:25], pvalues1, oddratio1, d[,26:43], pvalues2, oddratio2, d[, 44:dim(d)[2]], pvalues, oddratio), file = output_file, quote = F, sep = "\t", eol = "\n", row.names=F, col.names=F)
      options(scipen=curscipen)
    }
    else {
      # Create an empty file if there are no rows
      file.create(output_file)
    }
  }




