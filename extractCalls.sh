#!/bin/bash

vcf=$1
usage() { echo "Usage: $0 [-w workspace] [-n outvcf file name] [-o output folder] vcfFile" 1>&2; exit 1; }

while getopts ":w:n:o:" o; do
	case "${o}" in
		w)
			workspace=${OPTARG}
			;;
		n)
			outvcf=${OPTARG}
			;;
		o)
			out_folder=${OPTARG}
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND-1))

if [ -z "${workspace}" ] || [ -z "${outvcf}" ] || [ -z "${out_folder}" ]; then
	usage
fi

out_name=`basename $outvcf | sed -e 's/.vcf//g'`

cat $vcf | ${workspace}/config/vcflib/bin/vcfallelicprimitives | ${workspace}/config/vcflib/bin/vcfbreakmulti | ${workspace}/config/vcflib/bin/vcfallelicprimitives > $out_folder/$out_name.de.brk.de.vcf

cat $out_folder/$out_name.de.brk.de.vcf | $workspace/config/vcflib/bin/vcffilter -g "!(GT = .|. ) & !(GT = ./. ) & !(GT = 0|0 ) & !(GT = 0/0 ) " | $workspace/config/vcflib/bin/vcffixup - | $workspace/config/vcflib/bin/vcffilter -f "AC > 0" > $out_folder/$out_name.call.vcf

#grep '0\/0\|^#\|\.$' $vcf > $out_folder/$out_name.no_call.vcf

cat $out_folder/$out_name.de.brk.de.vcf | $workspace/config/vcflib/bin/vcffilter -g "(GT = .|. ) | (GT = ./. ) | (GT = 0|0 ) | (GT = 0/0 ) " | egrep -v "#" | awk 'FS="\t" {if ($10 != ".") print $0}' > $out_folder/$out_name.no_call.vcf
