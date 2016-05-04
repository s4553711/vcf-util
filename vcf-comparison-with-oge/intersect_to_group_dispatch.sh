#!/usr/bin

usage() { echo "Usage: $0 [-f ref.fa] [-v path of vcflib] [-r region] vcfFile1 vcfFile2 " 1>&2; exit 1; }

while getopts ":f:v:r:" o; do
    case "${o}" in
        f)
            Ref=${OPTARG}
            ;;
        v)
            vcflibPath=${OPTARG}
            ;;
        r)
            region=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${Ref}" ] || [ -z "${vcflibPath}" ]; then
    usage
fi

name1=$1
name2=$2
name3=$3
event=$4
Vcfintersect=$vcflibPath/bin/vcfintersect

${Vcfintersect} -i .venn/data/${name1}_${name2}.int.all.vcf .venn/${name3}.${region}.decomplx.brk.decomplx.vcf -r ${Ref} > .venn/int_${name1}_${name2}_${name3}_${region}_${event}.vcf
