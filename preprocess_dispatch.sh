#!/bin/bash
#$ -V
#$ -cwd
#$ -S /bin/bash

usage() { echo "Usage: $0 [-r ref.fa] [-v path of vcflib] [-c chrosome] vcfFile1" 1>&2; exit 1; }

while getopts ":r:v:c:" o; do
	case "${o}" in
		r)
			Ref=${OPTARG}
			;;
		v)
			vcflibPath=${OPTARG}
			;;
		c)
			chrosome=${OPTARG}
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${Ref}" ] || [ -z "${vcflibPath}" ] || [ -z "${chrosome}" ]; then
	usage
fi

vcfFile=$1
Vcfallelicprimitives=${vcflibPath}/bin/vcfallelicprimitives
Vcfbreakmulti=${vcflibPath}/bin/vcfbreakmulti
Vcfuniq=${vcflibPath}/bin/vcfuniq
Vcffilter=${vcflibPath}/bin/vcffilter
name=`echo $vcfFile | sed -e 's/.vcf//g'`

### break multi and allelic primitives###
cat $vcfFile | grep "^#\|^$chrosome\s" | ${Vcfallelicprimitives} | ${Vcfbreakmulti} | ${Vcfallelicprimitives} | ${Vcfuniq} > .venn/${name}.${chrosome}.decomplx.brk.decomplx.vcf

###prepared VCF files###
pvcf=${name}.${chrosome}.decomplx.brk.decomplx.vcf
echo ${pvcf}  saved!

###separate SNP and indel###
pvcf_snp=`echo $pvcf | sed -e 's/.vcf//g' | awk '{print $0 ".snp.vcf"}'`
pvcf_indel=`echo $pvcf | sed -e 's/.vcf//g' | awk '{print $0 ".indel.vcf"}'`
awk '{if( (length($4)==1 && length($5)==1) || substr($0, 0, 1)=="#" ){print $0}}' .venn/$pvcf > .venn/${pvcf_snp}
echo ${pvcf_snp} saved!
awk '{if( (length($4)!=1 || length($5)!=1) || substr($0, 0, 1)=="#" ){print $0}}' .venn/$pvcf > .venn/${pvcf_indel}
echo ${pvcf_indel} saved!

