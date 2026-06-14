# Install script for directory: /home/muneeb/Projects/com-warraich-petroleum/linux

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "0")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/llvm-objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum"
         RPATH "$ORIGIN/lib")
  endif()
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle" TYPE EXECUTABLE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/intermediates_do_not_run/warraich_petroleum")
  if(EXISTS "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum")
    file(RPATH_CHANGE
         FILE "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum"
         OLD_RPATH "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/dynamic_color:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/flutter_secure_storage_linux:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/printing:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/screen_retriever_linux:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/sqlite3_flutter_libs:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/url_launcher_linux:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/window_manager:/home/muneeb/Projects/com-warraich-petroleum/linux/flutter/ephemeral:/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/pdfium-src/lib:"
         NEW_RPATH "$ORIGIN/lib")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/llvm-strip" "$ENV{DESTDIR}/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/warraich_petroleum")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/data/icudtl.dat")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/data" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/linux/flutter/ephemeral/icudtl.dat")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libflutter_linux_gtk.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/linux/flutter/ephemeral/libflutter_linux_gtk.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libdynamic_color_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/dynamic_color/libdynamic_color_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libflutter_secure_storage_linux_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/flutter_secure_storage_linux/libflutter_secure_storage_linux_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libprinting_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/printing/libprinting_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libpdfium.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/pdfium-src/lib/libpdfium.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libscreen_retriever_linux_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/screen_retriever_linux/libscreen_retriever_linux_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libsqlite3_flutter_libs_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/sqlite3_flutter_libs/libsqlite3_flutter_libs_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/liburl_launcher_linux_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/url_launcher_linux/liburl_launcher_linux_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libwindow_manager_plugin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/window_manager/libwindow_manager_plugin.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libdartjni.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/jni/shared/libdartjni.so")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE DIRECTORY FILES "/home/muneeb/Projects/com-warraich-petroleum/build/native_assets/linux/")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  
  file(REMOVE_RECURSE "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/data/flutter_assets")
  
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/data/flutter_assets")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/data" TYPE DIRECTORY FILES "/home/muneeb/Projects/com-warraich-petroleum/build//flutter_assets")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Runtime" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib/libapp.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/bundle/lib" TYPE FILE FILES "/home/muneeb/Projects/com-warraich-petroleum/build/lib/libapp.so")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/flutter/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/runner/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/dynamic_color/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/flutter_secure_storage_linux/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/printing/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/screen_retriever_linux/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/sqlite3_flutter_libs/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/url_launcher_linux/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/window_manager/cmake_install.cmake")
  include("/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/plugins/jni/cmake_install.cmake")

endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
if(CMAKE_INSTALL_COMPONENT)
  if(CMAKE_INSTALL_COMPONENT MATCHES "^[a-zA-Z0-9_.+-]+$")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
  else()
    string(MD5 CMAKE_INST_COMP_HASH "${CMAKE_INSTALL_COMPONENT}")
    set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INST_COMP_HASH}.txt")
    unset(CMAKE_INST_COMP_HASH)
  endif()
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/home/muneeb/Projects/com-warraich-petroleum/build/linux/x64/release/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
