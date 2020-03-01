add_library(PythonKit
  NumpyConversion.swift
  Python.swift
  PythonLibrary+Symbols.swift
  PythonLibrary.swift)
set_target_properties(PythonKit PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_BINARY_DIR})

get_swift_host_arch(swift_arch)
get_swift_host_os(swift_os)
install(TARGETS PythonKit
  ARCHIVE DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${swift_os}
  LIBRARY DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${swift_os}
  RUNTIME DESTINATION bin)
if(CMAKE_SYSTEM_NAME STREQUAL Darwin)
  install(FILES $<TARGET_PROPERTY:PythonKit,Swift_MODULE_DIRECTORY>/PythonKit.swiftdoc
    DESTINATION  lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${swift_os}/PythonKit.swiftmodule
    RENAME ${swift_arch}.swiftdoc)
  install(FILES $<TARGET_PROPERTY:PythonKit,Swift_MODULE_DIRECTORY>/PythonKit.swiftmodule
    DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${swift_os}/PythonKit.swiftmodule
    RENAME ${swift_arch}.swiftmodule)
else()
  install(FILES
    $<TARGET_PROPERTY:PythonKit,Swift_MODULE_DIRECTORY>/PythonKit.swiftdoc
    $<TARGET_PROPERTY:PythonKit,Swift_MODULE_DIRECTORY>/PythonKit.swiftmodule
    DESTINATION lib/swift$<$<NOT:$<BOOL:${BUILD_SHARED_LIBS}>>:_static>/${swift_os}/${swift_arch})
endif()
set_property(GLOBAL APPEND PROPERTY PythonKit_EXPORTS PythonKit)
