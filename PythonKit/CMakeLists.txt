add_library(PythonKit
  NumpyConversion.swift
  Python.swift
  PythonLibrary+Symbols.swift
  PythonLibrary.swift)
set_target_properties(PythonKit PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_BINARY_DIR})

get_swift_host_arch(swift_arch)
install(TARGETS PythonKit
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>
  RUNTIME DESTINATION bin)
install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/PythonKit.swiftdoc
  ${CMAKE_CURRENT_BINARY_DIR}/PythonKit.swiftmodule
  DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/$<LOWER_CASE:${CMAKE_SYSTEM_NAME}>/${swift_arch})
set_property(GLOBAL APPEND PROPERTY PythonKit_EXPORTS PythonKit)
