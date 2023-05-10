set_time_format -unit ns -decimal_places 3

create_clock -name {gen24} -period 41.667 [get_ports {gen24}]
derive_pll_clocks
derive_clock_uncertainty
