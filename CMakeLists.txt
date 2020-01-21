cmake_minimum_required(VERSION 3.15.1)

project(PythonKit
  LANGUAGES Swift)

list(APPEND CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/cmake/modules)

include(SwiftSupport)

add_subdirectory(PythonKit)
add_subdirectory(cmake/modules)
