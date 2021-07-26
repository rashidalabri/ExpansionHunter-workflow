METADATA = pd.read_table(config["metadata"]).set_index("Sample name", drop=False)

def get_genotype_mem_mb(wildcards, attempt):
    base = config["eh_mem_gb"] * 1024
    increment = (config["eh_mem_gb_increment"] * 1024) * (attempt - 1)
    return base + increment

rule genotype_sample:
    input:
        cram="resources/cram/{sample}.cram",
        crai="resources/cram/{sample}.cram.crai",
        fa="resources/reference/GRCh38.fa",
        fai="resources/reference/GRCh38.fa.fai",
        var="resources/variant_catalog/chunked/{variant}/{variant}.{n}.json"
    params:
        sex=lambda wildcards: METADATA.loc[wildcards['sample'], 'Sex'],
        prefix=lambda wildcards, output: output.json[:-5],
        mode=config['expansionhunter_mode']
    output:
        json=temp("results/{variant}/{sample}/{sample}.{n}.json"),
        vcf=temp("results/{variant}/{sample}/{sample}.{n}.vcf"),
        bam=temp("results/{variant}/{sample}/{sample}_realigned.{n}.bam"),
    conda:
        "../envs/expansionhunter.yaml"
    envmodules:
        "expansionhunter/4.0.2"
    log:
        stdout="logs/expansionhunter/{variant}/{sample}/{sample}.{n}.stdout.log",
        stderr="logs/expansionhunter/{variant}/{sample}/{sample}.{n}.stderr.log"
    cache: True
    resources:
        mem_mb=get_genotype_mem_mb
    shell:
        "ExpansionHunter --reads {input.cram} "
        "--reference {input.fa} "
        "--variant-catalog {input.var} "
        "--output-prefix {params.prefix} "
        "--sex {params.sex} "
        "--analysis-mode {params.mode} "
        "2> {log.stderr} 1> {log.stdout}"
