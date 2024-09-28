clear -all

# Analyze source files and property files
set fd [open ./filelist.f r]
if {$fd < 0} {
  error "File open failed!"
}
set filelist [split [read $fd] "\n"]
close $fd
 
foreach file $filelist {
  if {[string length $file]} {
    analyze -sv12 \ $file
  }
}

# Elaborate design and properties
elaborate

# Set up Clocks and Resets
clock clock
reset reset

# Get design information to check general complexity
get_design_info

# Prove properties
# 1st pass: Quick validation of properties with default engines
set_max_trace_length 100
prove -all

report -file report.txt

set failed_properties [get_property_list -include {status {cex unreachable}}]
set length [llength $failed_properties]
if { $length > 0 } {
  puts "There are $length failed properties!"
} else {
  puts "All properties passed!"
}
set failed_num [open failed_num w]
puts $failed_num "$length"
close $failed_num
exit 0
