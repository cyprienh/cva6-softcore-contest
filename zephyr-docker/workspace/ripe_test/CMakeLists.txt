# SPDX-License-Identifier: Apache-2.0

set(GCC_PLUGIN_COMPILE_FLAGS "-fdump-tree-ssa -freport-bug -fplugin=/workdir/plugin.so -g -fdump-tree-optimized -Wall")
#set(RIPE_PARAMETERS "-DRIPEt=100 -DRIPEi=200 -DRIPEc=300 -DRIPEl=400 -DRIPEf=501")
set(CMAKE_C_FLAGS  "${CMAKE_C_FLAGS} ${GCC_PLUGIN_COMPILE_FLAGS} ${RIPE_PARAMETERS}")
cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# Override standard Microsemi UART adressing with the on from Future Electronics
#set(DTC_OVERLAY_FILE ${CMAKE_CURRENT_LIST_DIR}/src/ripe.dts)

# include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
#project(hello_world C ASM)
project(ripe)
#target_sources(app PRIVATE src/ripe_attack_generator.c src/setjmp.S )
target_sources(app PRIVATE src/ripe_attack_generator.c )
target_compile_definitions(app PRIVATE RIPEt=$ENV{RIPEt})
target_compile_definitions(app PRIVATE RIPEi=$ENV{RIPEi})
target_compile_definitions(app PRIVATE RIPEc=$ENV{RIPEc})
target_compile_definitions(app PRIVATE RIPEl=$ENV{RIPEl})
target_compile_definitions(app PRIVATE RIPEf=$ENV{RIPEf})
