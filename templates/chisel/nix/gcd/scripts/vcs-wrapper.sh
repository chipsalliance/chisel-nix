#!@shell@

_EXTRA_ARGS="$@"

if ((${VERBOSE:-0})); then
  set -x
fi

_DATE_BIN=@dateBin@
_VCS_SIM_BIN=@vcsSimBin@
_VCS_SIM_DAIDIR=@vcsSimDaidir@
_VCS_FHS_ENV=@vcsFhsEnv@

_NOW=$("$_DATE_BIN" "+%Y-%m-%d-%H-%M-%S")
_GCD_SIM_RESULT_DIR=${GCD_SIM_RESULT_DIR:-"gcd-sim-result"}
_CURRENT="$_GCD_SIM_RESULT_DIR"/all/"$_NOW"
mkdir -p "$_CURRENT"
ln -sfn "all/$_NOW" "$_GCD_SIM_RESULT_DIR/result"

cp "$_VCS_SIM_BIN" "$_CURRENT/"
cp -r "$_VCS_SIM_DAIDIR" "$_CURRENT/"

chmod -R +w "$_CURRENT"

pushd "$_CURRENT" >/dev/null

_emu_name=$(basename "$_VCS_SIM_BIN")
_daidir=$(basename "$_VCS_SIM_DAIDIR")

export LD_LIBRARY_PATH="$PWD/$_daidir:$LD_LIBRARY_PATH"

"$_VCS_FHS_ENV" -c "./$_emu_name $_EXTRA_ARGS" &> >(tee vcs-emu-journal.log)

if ((${DATA_ONLY:-0})); then
  rm -f "./$_emu_name"
fi

set -e _emu_name _daidir

popd >/dev/null

echo "VCS emulator finished, result saved in $_GCD_SIM_RESULT_DIR/result"
