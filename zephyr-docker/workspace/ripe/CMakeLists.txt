# SPDX-License-Identifier: Apache-2.0

#set(GCC_PLUGIN_COMPILE_FLAGS "-fdump-tree-ssa -freport-bug -O0 -fplugin=/workdir/plugin.so -g -fdump-tree-optimized")
#set(CMAKE_C_FLAGS  "${CMAKE_CXX_FLAGS} ${GCC_PLUGIN_COMPILE_FLAGS}")

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

# Override standard Microsemi UART adressing with the on from Future Electronics
#set(DTC_OVERLAY_FILE ${CMAKE_CURRENT_LIST_DIR}/src/ripe.dts)

# include($ENV{ZEPHYR_BASE}/cmake/app/boilerplate.cmake NO_POLICY_SCOPE)
#project(hello_world C ASM)
project(ripe)

#target_sources(app PRIVATE src/ripe_attack_generator.c src/setjmp.S )
target_sources(app PRIVATE src/ripe_attack_generator.c )
