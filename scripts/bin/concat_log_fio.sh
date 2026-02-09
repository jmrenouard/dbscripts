#!/bin/bash
set -euo pipefail

# --- Minimal Utility Functions ---
now() { echo "$(date "+%F %T %Z")($(hostname -s))"; }
info() { echo "$(now) INFO: $*" 1>&2; }
error() { echo "$(now) ERROR: $*" 1>&2; return 1; }
ok() { info "[SUCCESS] $* [SUCCESS]"; }
sep1() { echo "$(now) -----------------------------------------------------------------------------"; }
title1() { sep1; echo "$(now) $*"; sep1; }
cmd() {
    local tcmd="$1"
    local descr=${2:-"$tcmd"}
    title1 "RUNNING: $descr"
    set +e
    eval "$tcmd"
    local cRC=$?
    set -e
    if [ $cRC -eq 0 ]; then
        ok "$descr"
    else
        error "$descr (RC=$cRC)"
    fi
    return $cRC
}
banner() { title1 "START: $*"; info "run as $(whoami)@$(hostname -s)"; }
footer() {
    local lRC=${lRC:-"$?"}
    info "FINAL EXIT CODE: $lRC"
    [ $lRC -eq 0 ] && title1 "END: $* SUCCESSFUL" || title1 "END: $* FAILED"
    return $lRC
}
# --- End of Utility Functions ---

echo -n "Name;"
echo -n "terse_version;fio_version;jobname;groupid;error;"
echo -n "READ_kb;READ_bandwidth;READ_IOPS;READ_runtime;READ_Slat_min;"
echo -n "READ_Slat_max;READ_Slat_mean;READ_Slat_dev;READ_Clat_max;"
echo -n "READ_Clat_min;READ_Clat_mean;READ_Clat_dev;READ_clat_pct01;"
echo -n "READ_clat_pct02;READ_clat_pct03;READ_clat_pct04;READ_clat_pct05;"
echo -n "READ_clat_pct06;READ_clat_pct07;READ_clat_pct08;READ_clat_pct09;"
echo -n "READ_clat_pct10;READ_clat_pct11;READ_clat_pct12;READ_clat_pct13;"
echo -n "READ_clat_pct14;READ_clat_pct15;READ_clat_pct16;READ_clat_pct17;"
echo -n "READ_clat_pct18;READ_clat_pct19;READ_clat_pct20;READ_tlat_min;"
echo -n "READ_lat_max;READ_lat_mean;READ_lat_dev;READ_bw_min;READ_bw_max;"
echo -n "READ_bw_agg_pct;READ_bw_mean;READ_bw_dev;WRITE_kb;WRITE_bandwidth;"
echo -n "WRITE_IOPS;WRITE_runtime;WRITE_Slat_min;WRITE_Slat_max;WRITE_Slat_mean;"
echo -n "WRITE_Slat_dev;WRITE_Clat_max;WRITE_Clat_min;WRITE_Clat_mean;WRITE_Clat_dev;"
echo -n "WRITE_clat_pct01;WRITE_clat_pct02;WRITE_clat_pct03;WRITE_clat_pct04;"
echo -n "WRITE_clat_pct05;WRITE_clat_pct06;WRITE_clat_pct07;WRITE_clat_pct08;"
echo -n "WRITE_clat_pct09;WRITE_clat_pct10;WRITE_clat_pct11;WRITE_clat_pct12;"
echo -n "WRITE_clat_pct13;WRITE_clat_pct14;WRITE_clat_pct15;WRITE_clat_pct16;"
echo -n "WRITE_clat_pct17;WRITE_clat_pct18;WRITE_clat_pct19;WRITE_clat_pct20;"
echo -n "WRITE_tlat_min;WRITE_lat_max;WRITE_lat_mean;WRITE_lat_dev;WRITE_bw_min;"
echo -n "WRITE_bw_max;WRITE_bw_agg_pct;WRITE_bw_mean;WRITE_bw_dev;CPU_user;"
echo -n "CPU_sys;CPU_csw;CPU_mjf;PU_minf;iodepth_1;iodepth_2;iodepth_4;"
echo -n "iodepth_8;iodepth_16;iodepth_32;iodepth_64;lat_2us;lat_4us;lat_10us;"
echo -n "lat_20us;lat_50us;lat_100us;lat_250us;lat_500us;lat_750us;lat_1000us;"
echo -n "lat_2ms;lat_4ms;lat_10ms;lat_20ms;lat_50ms;lat_100ms;lat_250ms;"
echo -n "lat_500ms;lat_750ms;lat_1000ms;lat_2000ms;lat_over_2000ms;disk_name;"
echo -n "disk_read_iops;disk_write_iops;disk_read_merges;disk_write_merges;"
echo -n "disk_read_ticks;write_ticks;disk_queue_time;disk_utilization"
for d in $(find . -mindepth 1 -type d); do
	rep="$(basename $d)"
	(
		cd $d
		for l in *.log; do
			echo -n "$rep;"
			grep '%;' $l
		done
	)
done
