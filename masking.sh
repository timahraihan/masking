#! /bin/bash -xv


#getting flux fluxer from catalogue

awk '{if($1=="#id"||$1=="#"){}else{print $28"\t"$29}}' ../goodss_3dhst.v4.1.cats/Catalog/goodss_3dhst.v4.1.cat > fluxfromcat.dat

#getting XY coordinates and flux from radec

rm tmp_all_X_Y tmp_cat

sky2xy -v ../Optical/IMAGES/hlsp_xdf_hst_acswfc-30mas_hudf_f606w_v1_sci.fits @ra-dec2.dat | awk '{if (($1 !~/^\#/)&&($9)) {print $8, $9}}' > tmp_all_X_Y
paste tmp_all_X_Y fluxfromcat.dat | awk '{print $1,$2,$3,$4}' > tmp_cat

echo "VERBOSE = DEBUG"       >  asctoldac_tmp.conf
echo "COL_NAME  = Xpos"      >> asctoldac_tmp.conf
echo "COL_TTYPE = FLOAT"     >> asctoldac_tmp.conf
echo "COL_HTYPE = FLOAT"     >> asctoldac_tmp.conf
echo 'COL_COMM = ""'         >> asctoldac_tmp.conf
echo 'COL_UNIT = ""'         >> asctoldac_tmp.conf
echo 'COL_DEPTH = 1'         >> asctoldac_tmp.conf
echo "COL_NAME  = Ypos"      >> asctoldac_tmp.conf
echo "COL_TTYPE = FLOAT"     >> asctoldac_tmp.conf
echo "COL_HTYPE = FLOAT"     >> asctoldac_tmp.conf
echo 'COL_COMM = ""'         >> asctoldac_tmp.conf
echo 'COL_UNIT = ""'         >> asctoldac_tmp.conf
echo 'COL_DEPTH = 1'         >> asctoldac_tmp.conf
echo "COL_NAME  = Flux"      >> asctoldac_tmp.conf
echo "COL_TTYPE = FLOAT"     >> asctoldac_tmp.conf
echo "COL_HTYPE = FLOAT"     >> asctoldac_tmp.conf
echo 'COL_COMM = ""'         >> asctoldac_tmp.conf
echo 'COL_UNIT = ""'         >> asctoldac_tmp.conf
echo 'COL_DEPTH = 1'         >> asctoldac_tmp.conf
echo "COL_NAME  = Fluxer"    >> asctoldac_tmp.conf
echo "COL_TTYPE = FLOAT"     >> asctoldac_tmp.conf
echo "COL_HTYPE = FLOAT"     >> asctoldac_tmp.conf
echo 'COL_COMM = ""'         >> asctoldac_tmp.conf
echo 'COL_UNIT = ""'         >> asctoldac_tmp.conf
echo 'COL_DEPTH = 1'         >> asctoldac_tmp.conf

#convert ascii to ldac format

rm corrpol.cat

asctoldac -i tmp_cat  -c asctoldac_tmp.conf -t OBJECTS -o corrpol.cat -b 1 -n "CORR_lincomb"

#checking

ldacdesc -i corrpol.cat

#filtering negative positions
rm test_filter.cat

ldacfilter -i corrpol.cat -t OBJECTS -o test_filter.cat -c "((Xpos>0)AND(Ypos>0));"

#masking out

rm test_mask.cat

ldacaddmask -i test_filter.cat -t OBJECTS -o test_mask.cat -f tmp.reg.conv -n in_area -x Xpos Ypos

#convert ldac to ascii format

rm new_cat.dat

ldactoasc -i test_mask.cat -t OBJECTS -k Xpos Ypos in_area Flux Fluxer > new_cat.dat

#making region files

rm entries.reg ds9_all3dhst.reg
awk '{if($1=="#" || $3=="0"){}else{print "circle("$1","$2","20")"}}' new_cat.dat  > entries.reg
cat blank.reg entries.reg > ds9_all3dhst.reg

#open ds9

ds9 ../Optical/IMAGES/hlsp_xdf_hst_acswfc-30mas_hudf_f606w_v1_sci.fits -scale mode zscale -regions load ds9_all3dhst.reg &

#APPHOT
rm cat.dat appout mags.dat
awk '{if($1=="#" || $3=="0"){}else{print $1"\t"$2}}' new_cat.dat > cat.dat

python ../intern/apphot/apphot.py ../Optical/IMAGES/hlsp_xdf_hst_acswfc-30mas_hudf_f606w_v1_sci.fits cat.dat 23.33 appout

python ../intern/apphot/mag.py appout 25.00 magf606

python ../intern/apphot/mag.py fluxfromcat.dat 25.00 mags.dat

paste magf606 mags.dat | awk '{if($1=="#"){}else{print $1,$2,$3,$4}}' > magnitude606.dat

gnuplot
