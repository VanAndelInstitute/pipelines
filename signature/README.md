# Gene signature creation from L1000

## Pre-requisites

Database must be up and running.

```
qsub ~/projects/deploy-redis/redis-start.pbs
```

Data will take several minutes to load. 

## Extract gene perturbation instances

```
# Usage: ./fetch_inst.R [-[-host|r] <character>] [-[-port|p] <character>] \
#                     [-[-gene|g] <character>] [-[-type|t] <character>] \
#                     [-[-out|o] <character>] [-[-help|h]]
#     -r|--host    IP address of redis server.
#     -p|--port    port of redis server, default is 6379.
#     -g|--gene    symbol of gene of interest
#     -t|--type    pert_type, either 'trt_sh' (default), or 'trt_oe'
#     -o|--out     output file, default is gene_type.rds
#     -h|--help    print usage
#

/fetch_inst.R --host 10.152.220.27 --gene lmna

```

## Score genes ins extracted datase

```
# Usage: ./score_genes.R [-[-infile|i] <character>] [-[-outfile|o] <character>] [-[-help|h]]
#     -i|--infile     input file in rds format, such as output by fetch_inst.
#     -o|--outfile    output file, default is genescores.rds
#     -h|--help       print usage

./score_genes.R -h
    
```