#!/usr/local/bin/Rscript

library('getopt')
library(rredis)

spec = matrix(c(
  'host', 'r', 1,    "character", "IP address of redis server.",
  'port', 'p', 1,    "character", "port of redis server, default is 6379.",
  'gene', 'g', 1,    "character", "symbol of gene of interest",
  'type', 't', 1,    "character", "pert_type, either 'trt_sh' (default), or 'trt_oe'",
  'outfile', 'o', 1, "character", "output file, default is gene_type.rds",
  'help', 'h', 0,    "logical", "print usage"
), byrow=TRUE, ncol=5)
opt = getopt(spec)

if ( !is.null(opt$help) ) {
  cat(getopt(spec, usage=TRUE))
  q(status=1)
}

if ( is.null(opt$port    ) ) { opt$port      = 6379      }
if ( is.null(opt$type    ) ) { opt$type      = "trt_sh"}
if ( is.null(opt$host    ) ) { stop("--host argument is required.")      }
if ( is.null(opt$gene    ) ) { stop("--gene argument is required.")      }
if ( is.null(opt$outfile ) ) { opt$outfile  = paste0(opt$gene, "_", opt$type, ".rds")}

r_host <- opt$host
r_port <- opt$port

check_redis <- function() {
  tryCatch(
    {
      redisConnect(host=r_host, port=r_port, nodelay = FALSE)
    },
    error = function(e) {
      print(e)
      stop("Could not connect to redis. Env redis_host = ", r_host, " redis_port = ", r_port, ".")
    })
  dbs <- redisCmd("DBSIZE")[1]
  if(dbs != "1221420")
    stop(paste0("LINCS db has ", dbs, " records, expected 1221420. Exiting."))
  return(TRUE)
}

ok <- check_redis()

metadata <- readRDS("data/metadata.rds")
metadata$pert_desc <- tolower(metadata$pert_desc)

inst <- which(metadata$pert_desc == opt$gene &  
                    metadata$is_gold & 
                    metadata$pert_type == opt$type)
keys <- paste(metadata$distil_id[inst], "_ZSVC", sep="")
data <- do.call(cbind, redisMGet(keys))
ids <- genes <- rownames(data)

nac <- apply(data, 2, function(x) { sum(x == "NA") })
ix <- which(nac >= 976)

if(length(ix) > 0)
  data <- data[, -ix]

data <- apply(data, 2, as.numeric)
rownames(data) <- ids
saveRDS(data, file=opt$out)

redisClose()
