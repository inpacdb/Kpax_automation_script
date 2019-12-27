#!/bin/bash
PRO=""	# directory containing the protein structures
work=""	# working directory
EPI=""	# directory containing the structure to be compared
FILENAME=""				# structure to be compared
OUTPUT=""	# output directory containg results
cd $OUTPUT; mkdir clustered
cd "$PRO"
#####Batch######
a=1
n=1
for f in *.pdb
do
	mkdir -p "$work"/batch$a; cp "$f" "$work"/batch$a/
	if [ "$n" -eq 40 ]
	then
		a=`expr $a + 1`
		n=0
	fi	 
	n=`expr $n + 1`
done
######db creation#####
cd "$work"; 
num=`ls -1 -d batch* | wc -l`
a=1
while [ $a -le $num ]
do
	cd "$work"/batch$a/
	$KP -build=cluster_batch$a *.pdb	# bulid db for batch$(num)
	mv kpax_results kpax_db$a
	a=`expr $a + 1`
done 
#### RMSD analysis########
a=1
while [ $a -le $num ]
do
	cd "$work"/batch$a/; cp "$EPI"/"$FILENAME" .
	$KP -db=cluster_batch$a "$FILENAME"	# performs calculation
	mv kpax_results kpax_rmsd$a; cd kpax_rmsd$a/; mv kpax.log kpax_batch$a.log;
	sed -n '/RMSD/,/Mean/p' kpax_batch$a.log | awk -v OFS='\t' '{ print $15,$7}'| sed '1,2d;$d' | sed '$d' >>"$OUTPUT"/combined.txt
	cd ${FILENAME%.pdb}/; cp *_${FILENAME%.pdb}.pdb "$work"/clustered/
	a=`expr $a + 1`
done

cd "$OUTPUT"
sort -k2n combined.txt -o sorted.txt
sed -i '1i Cluster\tRMSD' sorted.txt
