set(PythonKit_EXPORTS_FILE ${CMAKE_CURRENT_BINARY_DIR}/PythonKitExports.cmake)
configure_file(PythonKitConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/PythonKitConfig.cmake)

get_property(PythonKit_EXPORTS GLOBAL PROPERTY PythonKit_EXPORTS)
export(TARGETS ${PythonKit_EXPORTS} FILE ${PythonKit_EXPORTS_FILE})
