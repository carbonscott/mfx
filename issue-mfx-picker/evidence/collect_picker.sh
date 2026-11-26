#!/bin/bash
# collect_picker.sh OUTDIR : evidence for the mfx-picker draft (run on S3DF, sdfiana025).
#  1) upstream-code.txt: pcdshub/mfx default-branch head, attenuator_scan.py at that head (line-numbered),
#     and git diff between the twin's clone 4beeab1 and the head for the relevant files (fresh capture).
#  2) verbatim copies of the x2 proof re-run's files (run 2026-11-26 02:56-03:14Z on sdfrome091), each under a
#     header naming the source file; the copied text is not changed.
set -u
OUT=$1; mkdir -p "$OUT"
H=/sdf/data/lcls/ds/prj/prjcwang31/scratch/main/sim-issues/agents/h1
M=$H/mfx-upstream
RUNSHA=4beeab1ea557460e1db858ce095f39a4e3f8afca
P=/sdf/data/lcls/ds/prj/prjcwang31/scratch/main/sim-explore/agents/h4/x2/out
BASE=$P/base-20261126T025624Z; FIX=$P/fixed-20261126T030448Z
git -C $M fetch -q origin
HEAD_SHA=$(git -C $M rev-parse origin/HEAD); BR=$(git -C $M symbolic-ref --short refs/remotes/origin/HEAD)
NOW=$(date -u +%FT%TZ)
hdr() {  # hdr <commit text> <cmd text>
  echo "# host: $(hostname)"; echo "# date: $NOW"; echo "# commit: $1"; echo "# cmd: $2"; }

{
hdr "mfx $HEAD_SHA (pcdshub/mfx $BR head) vs $RUNSHA (twin clone)" "collect_picker.sh $OUT (upstream check)"
echo
echo "\$ git ls-remote https://github.com/pcdshub/mfx HEAD refs/heads/master refs/heads/run27 refs/heads/1020945-undulator-1026"
git ls-remote https://github.com/pcdshub/mfx HEAD refs/heads/master refs/heads/run27 refs/heads/1020945-undulator-1026
echo "\$ git symbolic-ref --short refs/remotes/origin/HEAD    # default branch"
echo "$BR"
echo "\$ git log -1 --format='%H %cI %s' origin/HEAD"
git -C $M log -1 --format='%H %cI %s' origin/HEAD
F="mfx/attenuator_scan.py mfx/autorun.py mfx/db.py"
echo "\$ git diff $RUNSHA $HEAD_SHA -- $F | wc -l"
git -C $M diff $RUNSHA $HEAD_SHA -- $F | wc -l
echo
echo "\$ git show $HEAD_SHA:mfx/attenuator_scan.py | cat -n | sed -n '19,30p;86,101p;205,320p'"
git -C $M show $HEAD_SHA:mfx/attenuator_scan.py | cat -n | sed -n '19,30p;86,101p;205,320p'
echo
echo "\$ git show $HEAD_SHA:mfx/autorun.py | cat -n | grep -E 'close_picker|pulsepicker'"
git -C $M show $HEAD_SHA:mfx/autorun.py | cat -n | grep -E 'close_picker|pulsepicker'
} > $OUT/upstream-code.txt 2>&1

copy() {  # copy <src> <dst> <commit text>
  { hdr "$3" "collect_picker.sh $OUT (verbatim copy of $1)"
    echo "# source: $1"; echo "# (the lines below are the file as the run wrote it)"; echo
    cat "$1"; } > "$OUT/$2"
}
RUNC="mfx 4beeab1ea557 sim-hutch 4d7df7067b5c lcls2 5eb773c84b9d (run on sdfrome091, Slurm job 47153577)"
FIXC="mfx 387a4c1 (= 4beeab1ea557 + x2 fix-picker.patch) sim-hutch 4d7df7067b5c lcls2 5eb773c84b9d (run on sdfrome091)"
cp $BASE/summary.txt $OUT/ci-base-summary.txt
cp $FIX/summary.txt $OUT/ci-fix-summary.txt
D=attscan-default-picker-preopened
copy $BASE/$D/script.py      base-default-script.txt    "$RUNC"
copy $BASE/$D/case.txt       base-default-case.txt      "$RUNC"
copy $BASE/$D/session.out    base-default-session.txt   "$RUNC"
copy $BASE/$D/camonitor.txt  base-default-camonitor.txt "$RUNC"
copy $BASE/$D.check.out      base-default-check.txt     "$RUNC"
copy $FIX/$D/session.out     fix-default-session.txt    "$FIXC"
copy $FIX/$D/camonitor.txt   fix-default-camonitor.txt  "$FIXC"
copy $FIX/$D.check.out       fix-default-check.txt      "$FIXC"
FXR=/sdf/data/lcls/ds/prj/prjcwang31/scratch/main/sim-explore/agents/h4/mfx-fix
{ hdr "mfx $(git -C $FXR rev-parse HEAD) (fix clone) vs $RUNSHA" "collect_picker.sh $OUT (git -C $FXR diff $RUNSHA HEAD)"
  echo; echo "\$ git diff $RUNSHA HEAD    # in the fix clone the fix run used"
  git -C $FXR diff $RUNSHA HEAD; } > $OUT/fix-mfx.diff.txt 2>&1
ls -la $OUT
