cmake_minimum_required(VERSION 3.5)

project(gamma-cc C)


find_package(PkgConfig REQUIRED)


pkg_check_modules(EFL REQUIRED
    elementary
    ecore
    eina
    evas
)


add_executable(
    gamma-cc
    main.c
)


target_include_directories(
    gamma-cc
    PRIVATE
    ${EFL_INCLUDE_DIRS}
)


target_compile_options(
    gamma-cc
    PRIVATE
    ${EFL_CFLAGS_OTHER}
)


target_link_directories(
    gamma-cc
    PRIVATE
    ${EFL_LIBRARY_DIRS}
)


target_link_libraries(
    gamma-cc
    ${EFL_LIBRARIES}
)


install(
    TARGETS gamma-cc
    DESTINATION /usr/bin
)
