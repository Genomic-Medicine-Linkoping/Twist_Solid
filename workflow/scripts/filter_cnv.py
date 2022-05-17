
from pysam import VariantFile

def variant_in_genelist(chrom, start, end, gene_dict):
    keep_variant = False
    genes = ""
    if chrom in gene_dict:
        for gene_region in gene_dict[chrom]:
            g_start = gene_region[0]
            g_end = gene_region[1]
            if ((start >= g_start and start <= g_end) or
                (end >= g_start and end <= g_end) or
                (start < g_start and end > g_end)):
                keep_variant = True
                if genes == "":
                    genes = gene_region[2]
                else:
                    genes = "%s,%s" % (genes, gene_region[2])
    return keep_variant, genes


def filter_variants(in_vcf, out_vcf, filter_bed_file):
    gene_dict = {}
    for line in filter_bed_file:
        columns = line.strip().split("\t")
        chrom = columns[0]
        start = int(columns[1])
        end = int(columns[2])
        gene = columns[3]
        if chrom not in gene_dict:
            gene_dict[chrom] = [[start, end, gene]]
        else:
            gene_dict[chrom].append([start, end, gene])

    vcf_in = VariantFile(in_vcf)
    new_header = vcf_in.header
    new_header.info.add("Genes", "1", "String", "Gene names")
    vcf_out = VariantFile(out_vcf, 'w', header=new_header)
    vcf_out.close()
    vcf_in.close()

    vcf_out = open(out_vcf, "a")
    vcf_in = open(in_vcf)
    header = True
    for line in vcf_in:
        if header:
            if line[:6] == "#CHROM":
                header = False
            continue
        columns = line.strip().split("\t")
        chrom = columns[0]
        start = int(columns[1])
        INFO = lline[7]
        end = int(INFO.split("END=")[1].split(";")[0])

        keep_variant, genes = variant_in_genelist(chrom, start, end, gene_dict)
        if keep_variant:
            INFO = "Genes=%s;%s" % (genes, INFO)
            columns[7] = INFO
            vcf_out.write(columns[0])
            for column in columns[1:]:
                vcf_out.write("\t" + column)
            vcf_out.write("\n")
    vcf_out.close()


if __name__ == "__main__":
    in_vcf = snakemake.input.vcf
    out_vcf = snakemake.output.vcf
    filter_bed_file = open(snakemake.params.filter_config)

    filter_variants(in_vcf, out_vcf, filter_bed_file)
