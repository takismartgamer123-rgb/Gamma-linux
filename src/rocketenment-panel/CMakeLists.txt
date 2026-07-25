cmake_minimum_required(VERSION 3.5)

project(rocketenment-panel C)

find_package(PkgConfig REQUIRED)

pkg_check_modules(EFL REQUIRED
    elementary
    ecore
    eina
    evas
)

add_executable(
    rocketenment-panel
    main.c
    panel.c
    clock.c
)

target_include_directories(
    rocketenment-panel
    PRIVATE
    ${EFL_INCLUDE_DIRS}
)

target_compile_options(
    rocketenment-panel
    PRIVATE
    ${EFL_CFLAGS_OTHER}
    -Wall
    -Wextra
)

target_link_directories(
    rocketenment-panel
    PRIVATE
    ${EFL_LIBRARY_DIRS}
)

target_link_libraries(
    rocketenment-panel
    ${EFL_LIBRARIES}
)

install(
    TARGETS rocketenment-panel
    DESTINATION /usr/bin
)
