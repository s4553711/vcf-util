#!/bin/bash

getDir() {
	SCRIPT="$(readlink --canonicalize-existing "$0")"
	SCRIPTPATH="$(dirname "$SCRIPT")"
	echo $SCRIPTPATH
}
script_dir=$(getDir)

usage() { echo "Usage: $0 [-r ref.fa] [-v path of vcflib] vcfFile1 vcfFile2 vcfFile3" 1>&2; exit 1; }

while getopts ":r:v:b:" o; do
    case "${o}" in
        r)
            Ref=${OPTARG}
            ;;
        v)
            vcflibPath=${OPTARG}
            ;;
        b)
            bedPath=${OPTARG}
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

if [ ! -z "${bedPath}" ]; then
	bedPathArg="-b $bedPath"
else
	bedPathArg=""
fi

vcfFile1=$1
vcfFile2=$2
vcfFile3=$3
name1=`basename $vcfFile1 | sed -e 's/.vcf//g'`
name2=`basename $vcfFile2 | sed -e 's/.vcf//g'`
if [ "$#" -eq 3 ]; then
	name3=`basename $vcfFile3 | sed -e 's/.vcf//g'`
fi
Vcfallelicprimitives=${vcflibPath}/bin/vcfallelicprimitives
Vcfbreakmulti=${vcflibPath}/bin/vcfbreakmulti
Vcfintersect=${vcflibPath}/bin/vcfintersect

rm -rf .venn
mkdir -p .venn/log
mkdir -p .venn/data
touch ".venn/start"

echo "preprocessing ..."
chrs="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 X Y MT GL000207.1 GL000226.1 GL000229.1 GL000231.1 GL000210.1 GL000239.1 GL000235.1 GL000201.1 GL000247.1 GL000245.1 GL000197.1 GL000203.1 GL000246.1 GL000249.1 GL000196.1 GL000248.1 GL000244.1 GL000238.1 GL000202.1 GL000234.1 GL000232.1 GL000206.1 GL000240.1 GL000236.1 GL000241.1 GL000243.1 GL000242.1 GL000230.1 GL000237.1 GL000233.1 GL000204.1 GL000198.1 GL000208.1 GL000191.1 GL000227.1 GL000228.1 GL000214.1 GL000221.1 GL000209.1 GL000218.1 GL000220.1 GL000213.1 GL000211.1 GL000199.1 GL000217.1 GL000216.1 GL000215.1 GL000205.1 GL000219.1 GL000224.1 GL000223.1 GL000195.1 GL000212.1 GL000222.1 GL000200.1 GL000193.1 GL000194.1 GL000225.1 GL000192.1 NC_007605 hs37d5"
for vcf in $@; do
	name=`basename $vcf | sed -e 's/.vcf//g'`
	for chr in $chrs; do
		qsub -q hipipe.q -N venn.cleanup.$name.$chr -o .venn/log/venn.cleanup.$name.$chr.out -e .venn/log/venn.cleanup.$name.$chr.err -cwd ${script_dir}/preprocess_dispatch.sh -r $Ref -v $vcflibPath -c $chr ${vcf}
	done
done

for vcf in $@; do
	name=`basename $vcf | sed -e 's/.vcf//g'`
	qsub -q hipipe.q -N venn.catpre.$name -hold_jid venn.cleanup.* -o .venn/log/venn.catpre.$name.out -e .venn/log/venn.catpre.$name.err -cwd ${script_dir}/catPreProcess.sh $name
done

for chr in $chrs; do
	qsub -q hipipe.q -N venn.intersect.${name1}_${name2}.$chr -hold_jid venn.catpre.* -o .venn/log/venn.intersect.${name1}_${name2}.$chr.out -e .venn/log/venn.intersect.${name1}_${name2}.$chr.err -cwd ${script_dir}/intersect_dispatch.sh $bedPathArg -f $Ref -v $vcflibPath -r $chr ${name1} ${name2} all
done
qsub -q hipipe.q -N venn.catInt.${name1}_${name2} -hold_jid venn.intersect.${name1}_${name2}.* -o .venn/log/venn.catInt.${name1}_${name2}.out -e .venn/log/venn.catInt.${name1}_${name2}.err -cwd ${script_dir}/catInt.sh $name1 $name2 all

if [ "$#" -eq 3 ]; then
	echo "we have 3 vcfs to compare"
	for chr in $chrs; do
		qsub -q hipipe.q -N venn.intersect.${name1}_${name3}.$chr -hold_jid venn.catpre.* -o .venn/log/venn.intersect.${name1}_${name3}.$chr.out -e .venn/log/venn.intersect.${name1}_${name3}.$chr.err -cwd ${script_dir}/intersect_dispatch.sh $bedPathArg -f $Ref -v $vcflibPath -r $chr ${name1} ${name3} all
	done
	qsub -q hipipe.q -N venn.catInt.${name1}_${name3} -hold_jid venn.intersect.${name1}_${name3}.* -o .venn/log/venn.catInt.${name1}_${name3}.out -e .venn/log/venn.catInt.${name1}_${name3}.err -cwd ${script_dir}/catInt.sh $name1 $name3 all

	for chr in $chrs; do
		qsub -q hipipe.q -N venn.intersect.${name2}_${name3}.$chr -hold_jid venn.catpre.* -o .venn/log/venn.intersect.${name2}_${name3}.$chr.out -e .venn/log/venn.intersect.${name2}_${name3}.$chr.err -cwd ${script_dir}/intersect_dispatch.sh $bedPathArg -f $Ref -v $vcflibPath -r $chr ${name2} ${name3} all
	done
	qsub -q hipipe.q -N venn.catInt.${name2}_${name3} -hold_jid venn.intersect.${name2}_${name3}.* -o .venn/log/venn.catInt.${name2}_${name3}.out -e .venn/log/venn.catInt.${name2}_${name3}.err -cwd ${script_dir}/catInt.sh $name2 $name3 all

	for chr in $chrs; do
		qsub -q hipipe.q -N venn.intersect.${name1}_${name2}_${name3}.$chr -hold_jid venn.catInt.${name1}_${name2} -o .venn/log/venn.intersect.${name1}_${name2}_${name3}.$chr.out -e .venn/log/venn.intersect.${name1}_${name2}_${name3}.$chr.err -cwd ${script_dir}/intersect_to_group_dispatch.sh -f $Ref -v $vcflibPath -r $chr ${name1} ${name2} ${name3} all
	done
	qsub -q hipipe.q -N venn.catInt.group.${name1}_${name2}_${name3} -hold_jid venn.intersect.${name1}_${name2}_${name3}.* -o .venn/log/venn.catInt.group.${name1}_${name2}_${name3}.out -e .venn/log/venn.catInt.group.${name1}_${name2}_${name3}.err -cwd ${script_dir}/catInt-group.sh $name1 $name2 $name3 all
fi
