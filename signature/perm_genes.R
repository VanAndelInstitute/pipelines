#!/usr/bin/env Rscript

library('getopt')
library(rredis)
library(snow)
library(doSNOW)

setwd(Sys.getenv("PBS_O_WORKDIR"))

spec = matrix(c(
  'sample', 's', 1, "integer", "sample size for each iteration.",
  'iter', 'i', 1, "integer", "number of iterations.",
  'host', 'r', 1,    "character", "IP address of redis server.",
  'port', 'p', 1,    "character", "port of redis server, default is 6379",
  'type', 't', 1, "character", "pert_type, either `trt_sh` (default) or `trt_oe`",
  'outfile', 'o', 1, "character", "output file root, default is gene_type_sample",
  'help', 'h', 0, "logical", "print usage"
), byrow=TRUE, ncol=5)
opt = getopt(spec)

if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE))
  q(status=1)
}

if ( is.null(opt$port    ) ) { opt$port      = 6379      }
if ( is.null(opt$type    ) ) { opt$type      = "trt_sh"}
if ( is.null(opt$host    ) ) { stop("--host argument is required.")      }
if ( is.null(opt$sample ) ) { stop("--sample argument is required.")}
if ( is.null(opt$iter ) ) { stop("--iter argument is required.")}
if ( is.null(opt$outfile) ) { opt$outfile = paste0("gene_", opt$type, "_", opt$sample, "_pdf.rds")}

metadata <- readRDS("data/metadata.rds")
SAMPLESIZE = opt$sample

init <- function() {
  f <- Sys.getenv('PBS_NODEFILE')
  x <- if (nzchar(f)) readLines(f) else rep('localhost', 3)
  nodes <- as.data.frame(table(x), stringsAsFactors=FALSE)
  cores <- rep(nodes$x, nodes$Freq)
  cl <- makeSOCKcluster(cores)
  registerDoSNOW(cl)
  list(cl=cl, cores=cores)
}

env <- init()

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
  
  if(-min(cumsum(scores)) > max(cumsum(scores))) {
    return(0)
  } else {
    return(max(cumsum(scores)))
  }
}

r <- foreach(i=1:opt$iter, .packages="rredis") %dopar% {  
  
  r_host = opt$host
  r_port = opt$port
  
  # keep data set size the same as our dataset of interest
  rand_inst <- sample(which(metadata$pert_type == opt$type), SAMPLESIZE)
  rand_keys <- paste(metadata$distil_id[rand_inst], "_ZSVC", sep="")
  
  redisConnect(host=r_host, port=r_port)
  rand_data <- do.call(cbind, redisMGet(rand_keys))
  redisClose()
  
  ids <- rownames(rand_data)
  rand_data <- apply(rand_data, 2, as.numeric)
  rownames(rand_data) <- ids
  
  # invert sign so that largest values have smallest rank
  ranks <- apply(-rand_data, 2, rank)
  ranks <- rank(as.vector(ranks))
  genes <- rep(rownames(rand_data), ncol(rand_data))
  
  ranks_down <- rank(-ranks)
  up_r <- numeric(0)
  down_r <- numeric(0)
  
  for(g in unique(genes)) {
    up_r <- c(up_r, ks(ranks, which(genes==g) ) )
    down_r <- c(down_r, ks(ranks_down, which(genes==g) ) )
  }
  return(list(up=up_r, down=down_r, gene_ids=rownames(rand_data)))
}


f1 <- function(x) { return(x$up)}
f2 <- function(x) { return(x$down)}

up <- do.call(cbind, lapply(r, f1))
down <- do.call(cbind, lapply(r, f2))
rownames(up) <- rownames(down) <- r[[1]]$gene_ids

saveRDS(up, file=paste0(opt$outfile, "_up_pdf.rds"))
saveRDS(down, file=paste0(opt$outfile, "_down_pdf.rds"))

stopCluster(env$cl)