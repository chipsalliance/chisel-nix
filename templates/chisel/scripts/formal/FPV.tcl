# Make sure you have run the nix build command to build the formal results
# Now the result/ directory should contain the GCD.sv and GCDFormal.sv

clear -all

# Analyze design under verification files
set RESULT_PATH ./result

# Analyze source files and property files
analyze -sv12 \
  ${RESULT_PATH}/GCD.sv \
  ${RESULT_PATH}/GCDFormal.sv

# Elaborate design and properties
elaborate -top GCDFormal

# Set up Clocks and Resets
clock clock
reset reset

# Get design information to check general complexity
get_design_info

# Prove properties
# 1st pass: Quick validation of properties with default engines
set_max_trace_length 100
prove -all

# Report proof results
report

