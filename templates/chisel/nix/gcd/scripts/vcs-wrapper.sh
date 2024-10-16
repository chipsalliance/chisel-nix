#!@shell@

_EXTRA_ARGS="$@"

if ((${VERBOSE:-0})); then
  set -x
fi

_LIB=@lib@
_DATE_BIN=@dateBin@
_VCS_SIM_BIN=@vcsSimBin@
_VCS_SIM_DAIDIR=@vcsSimDaidir@
_VCS_FHS_ENV=@vcsFhsEnv@
_VCS_COV_DIR=@vcsCovDir@

_NOW=$("$_DATE_BIN" "+%Y-%m-%d-%H-%M-%S")
_GCD_SIM_RESULT_DIR=${GCD_SIM_RESULT_DIR:-"gcd-sim-result"}
_CURRENT="$_GCD_SIM_RESULT_DIR"/all/"$_NOW"
mkdir -p "$_CURRENT"
ln -sfn "all/$_NOW" "$_GCD_SIM_RESULT_DIR/result"

cp "$_VCS_SIM_BIN" "$_CURRENT/"
cp -r "$_VCS_SIM_DAIDIR" "$_CURRENT/"

if [ -n "$_VCS_COV_DIR" ]; then
  cp -vr "$_LIB/$_VCS_COV_DIR" "$_CURRENT/"
  _CM_ARG="-cm assert -cm_dir ./$_VCS_COV_DIR" # vcs runs in $_CURRENT
fi

chmod -R +w "$_CURRENT"
pushd "$_CURRENT" >/dev/null

_emu_name=$(basename "$_VCS_SIM_BIN")
_daidir=$(basename "$_VCS_SIM_DAIDIR")

export LD_LIBRARY_PATH="$PWD/$_daidir:$LD_LIBRARY_PATH"

"$_VCS_FHS_ENV" -c "./$_emu_name $_CM_ARG $_EXTRA_ARGS" &> >(tee ./vcs-emu-journal.log)

if [ -n "$_VCS_COV_DIR" ]; then
  "$_VCS_FHS_ENV" -c "urg -dir "./$_VCS_COV_DIR" -format text"
fi

if ((${DATA_ONLY:-0})); then
  rm -f "./$_emu_name"
fi

set -e _emu_name _daidir

echo "VCS emulator finished, result saved in $_GCD_SIM_RESULT_DIR/result"
