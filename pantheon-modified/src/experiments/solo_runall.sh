time=30
timeout=300
#./system_setup.sh
pids=""
sys_cpu_cnt=`lscpu | grep "^CPU(s):" | awk '{print $2}'`
cnt=0

#schemes="c2tcp copa vivace ledbat sprout"
#schemes="sage orca indigo dbbr"
schemes="bbr cubic"
setup_time=5

#loss_list="0"
#loss_list="0 0.0000001 0.0000002 0.0000003 0.0000004 0.0000005 0.00000006 0.0000007 0.0000008 0.0000009 0.000001 0.0000011 0.0000012 0.0000013 0.0000014 0.0000015 0.0000016 0.0000017 0.0000018 0.0000019 0.0000020 0.0000021 0.0000022 0.0000023 0.0000024 0.0000025 0.0000026 0.0000027 0.0000028 0.0000029"
loss_list="0 0.0000001 0.0000002 0.0000003 0.0000004 0.0000005 0.00000006 0.0000007 0.0000008 0.0000009"
#bw_list="12 24 48 96 192"
#del_list="5 10 20 40 80"
bw_list="192"
#del_list="5 80"
del_list="5"
for cc in $schemes
do
    for bw in $bw_list
    do
        if [ $bw -gt 100 ]
            then
                #cpu_num=$((sys_cpu_cnt/5))
                cpu_num=10
            else
                cpu_num=1
        fi
        ## Pantheon and Mahimahi have problem with links higher than 300Mbps!
        ## For now, avoid using any link BW>300Mbps. But, stay tuned! A new patch is on the way! ;)
        for del in $del_list
        do 
            bdp=$((del*bw/6))
            for loss in $loss_list
            do
                #for qs in $((bdp/2)) $bdp $((2*bdp)) $((4*bdp)) $((8*bdp)) $((16*bdp))
                for qs in $((4*bdp))
                do
                    for dl_post in ""
                    do
                        link="$bw$dl_post"
                        echo "./cc_solo.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw $setup_time"
                        ./cc_solo.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw $setup_time &
                        cnt=$((cnt+1))
                        pids="$pids $!"
                        sleep 1
                    done
:<<"CMT"
                    if [ $bw -lt 50 ]
                    then
                        scales="2 4"
                    elif [ $bw -lt 100 ]
                    then
                        scales="2"
                    else
                        scales=""
                    fi
                    for scale in $scales
                    do
                        dl_post="-${scale}x-u-7s-plus-10"
                        bw2=$((bw*scale))
                        link="$bw$dl_post"
                        echo "./cc_solo.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time"
                        ./cc_solo.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time &
                        cnt=$((cnt+1))
                        pids="$pids $!"
                        sleep 2
                    done
                    if [ $bw -gt 40 ]
                    then
                        scales="2 4"
                    elif [ $bw -gt 20 ]
                    then
                        scales="2"
                    else
                        scales=""
                    fi
                    for scale in $scales
                    do
                        dl_post="-${scale}x-d-7s-plus-10"
                        bw2=$((bw/scale))
                        link="$bw$dl_post"
                        echo "./cc_solo.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time &"
                        ./cc_solo.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time &
                        cnt=$((cnt+1))
                        pids="$pids $!"
                        sleep 2
                    done
CMT
                    if [ $cnt -ge $cpu_num ]
                    then
                        for pid in $pids
                        do
                            wait $pid
                        done
                        cnt=0
                        pids=""
                        ./clean-tmp.sh
                    fi
                done
            done
        done
    done
done
sleep 5

cpu_num=$((sys_cpu_cnt))

for cc in $schemes
do
    for loss in $loss_list
    do
        for bw in $bw_list
        do
            for del in $del_list
            do
                bdp=$((del*bw/6))
                #for qs in $((bdp/2)) $bdp $((2*bdp)) $((4*bdp)) $((8*bdp)) $((16*bdp))
                for qs in $((4*bdp))
                do
                    for dl_post in ""
                    do
                        link="$bw$dl_post"
                        echo "./cc_solo_analysis.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw $setup_time"
                        ./cc_solo_analysis.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw $setup_time &
                        cnt=$((cnt+1))
                        pids="$pids $!"
                        sleep 2
                    done
:<<"CMT"
                    if [ $bw -lt 50 ]
                    then
                        scales="2 4"
                    elif [ $bw -lt 100 ]
                    then
                        scales="2 4"
                    elif [ $bw -lt 200 ]
                    then
                        scales=""
                    else
                        scales=""
                    fi
                    for scale in $scales
                    do
                        dl_post="-${scale}x-u-7s-plus-10"
                        bw2=$((bw*scale))
                        link="$bw$dl_post"
                        echo "./cc_solo_analysis.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time"
                        ./cc_solo_analysis.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time &
                        cnt=$((cnt+1))
                        pids="$pids $!"
                    done
                    scales="2 4"
                    for scale in $scales
                    do
                        dl_post="-${scale}x-d-7s-plus-10"
                        bw2=$((bw/scale))
                        link="$bw$dl_post"
                        echo "./cc_solo_analysis.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time"
                        ./cc_solo_analysis.sh $cc dataset-gen 1 1 0 $del $qs "$loss" $link $time $bw $bw2 $setup_time &
                        cnt=$((cnt+1))
                        pids="$pids $!"
                    done
CMT
                    if [ $cnt -ge $cpu_num ]
                    then
                        for pid in $pids
                        do
                            wait $pid
                        done
                        cnt=0
                        pids=""
                    fi
                done
            done
        done
    done
done
./clean-tmp.sh
for cc in $schemes
do
    ./prepare-solo_league.sh $cc
done
./clean-tmp2.sh
