# Gene signature creation from L1000

## Pre-requisites

Database must be up and running.

```
qsub ~/projects/deploy-redis/redis-start.pbs
```

Data will take several minutes to load. 

## Extract gene perturbation instances

```
# Usage: ./fetch_inst [-[-host|r] <character>] [-[-port|p] <character>] \
#                     [-[-gene|g] <character>] [-[-type|t] <character>] \
#                     [-[-out|o] <character>] [-[-help|h]]
#     -r|--host    IP address of redis server.
#     -p|--port    port of redis server, default is 6379.
#     -g|--gene    symbol of gene of interest
#     -t|--type    pert_type, either 'trt_sh' (default), or 'trt_oe'
#     -o|--out     output file, default is gene_type.rds
#     -h|--help    print usage
#

/fetch_inst --host 10.152.220.27 --gene lmna

```

## Score genes extracted from database

```
# Usage: ./score_genes [-[-infile|i] <character>] [-[-outfile|o] <character>] [-[-help|h]]
#     -i|--infile     input file in rds format, such as output by fetch_inst.
#     -o|--outfile    output file, default is genescores.rds
#     -h|--help       print usage

./score_genes -h
    
```

## Empiric probability density for gene signatures.

Assume availability of HPC/qsub infrastruture.

```
# Usage: ./perm_genes [-[-sample|s] <integer>] [-[-iter|i] <integer>] 
#                     [-[-host|r] <character>] [-[-port|p] <character>] 
#                     [-[-type|t] <character>] [-[-outfile|o] <character>] [-[-help|h]]
#     -s|--sample     sample size for each iteration.
#     -i|--iter       number of iterations.
#     -r|--host       IP address of redis server.
#     -p|--port       port of redis server, default is 6379
#     -t|--type       pert_type, either `trt_sh` (default) or `trt_oe`
#     -h|--help       print usage    -h|--help       print usage

/perm_genes --host 10.152.220.27 --sample 100 --iter 100

```


