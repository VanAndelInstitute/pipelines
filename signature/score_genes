#!/usr/bin/env Rscript

library('getopt')
library(rredis)

spec = matrix(c(
  'infile', 'i', 1, "character", "input file in rds format, such as output by fetch_inst.",
  'outfile', 'o', 1, "character", "output file, default is genescores.rds",
  'help', 'h', 0, "logical", "print usage"
), byrow=TRUE, ncol=5)
opt = getopt(spec)

if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE))
  q(status=1)
}

if ( is.null(opt$outfile) ) { opt$outfile = "genescores.rds"}
if ( is.null(opt$infile ) ) { stop("--in argument is required.")}

data <- readRDS(opt$infile)

ks <- function(x, ix) {
  n <- length(x)
  scores <- -rep(1/(n-length(ix)), n)
  inc <- 1/length(ix)
  
  # need to account for ties
  ix <- floor(x[ix])
  scores[ix] <- 0
  for(i in ix) {
    scores[i] = scores[i] + inc
  }
  if(-min(cumsum(scores)) >= max(cumsum(scores))) {
    return(0)
  } else {
    return(max(cumsum(scores)))
  }
}

ranks <- apply(-data, 2, rank)
ranks <- rank(as.vector(ranks))
genes <- rep(rownames(data), ncol(data))

ranks_d <- rank(-ranks)
up <- numeric(0)
down <- numeric(0)
for(g in unique(genes)) {
  up <- c(up, ks(ranks, which(genes==g) ) )
  down <- c(down, ks(ranks_d, which(genes==g) ) )
}
names(up) <- unique(genes)
names(down) <- unique(genes)

saveRDS(list(up=up, down=down), file=opt$outfile)
