__author__ = "Jonas Almlöf"
__copyright__ = "Copyright 2022, Jonas Almlöf"
__email__ = "jonas.almlof@scilifelab.uu.se"
__license__ = "GPL-3"


rule exon_skipping:
    input:
        bed=config.get("exon_skipping", {}).get("design_bed", []),
        junction_file="fusions/star_fusion/{sample}_{type}/SJ.out.tab",
    output:
        results=temp("fusions/exon_skipping/{sample}_{type}.results.tsv"),
    log:
        "fusions/exon_skipping/{sample}_{type}.results.tsv.log",
    benchmark:
        repeat(
            "fusions/exon_skipping/{sample}_{type}.results.tsv.benchmark.tsv",
            config.get("exon_skipping", {}).get("benchmark_repeats", 1),
        )
    threads: config.get("exon_skipping", {}).get("threads", config["default_resources"]["threads"])
    resources:
        threads=config.get("exon_skipping", {}).get("threads", config["default_resources"]["threads"]),
        time=config.get("exon_skipping", {}).get("time", config["default_resources"]["time"]),
        mem_mb=config.get("exon_skipping", {}).get("mem_mb", config["default_resources"]["mem_mb"]),
        mem_per_cpu=config.get("exon_skipping", {}).get("mem_per_cpu", config["default_resources"]["mem_per_cpu"]),
        partition=config.get("exon_skipping", {}).get("partition", config["default_resources"]["partition"]),
    container:
        config.get("exon_skipping", {}).get("container", config["default_container"])
    conda:
        "../envs/exon_skipping.yaml"
    message:
        "{rule}: Find intrgenic fusions and report them in {output.results}"
    script:
        "../scripts/exon_skipping.py"
