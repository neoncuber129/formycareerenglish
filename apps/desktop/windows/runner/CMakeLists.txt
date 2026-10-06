cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "selection_host_bridge.cpp"
  "main.cpp"
  "popup_flutter_window.cpp"
  "region_selector_window.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the build version.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# Disable Windows macros that collide with C++ standard library functions.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# Add dependency libraries and include directories. Add any application-specific
# dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# MSBuild PostBuild often runs with a minimal PATH; resolve dotnet explicitly.
find_program(FMC_DOTNET dotnet)
if(NOT FMC_DOTNET)
  foreach(_fmc_dotnet_candidate IN ITEMS
      "$ENV{ProgramW6432}/dotnet/dotnet.exe"
      "$ENV{ProgramFiles}/dotnet/dotnet.exe"
      "$ENV{LOCALAPPDATA}/Microsoft/dotnet/dotnet.exe")
    if(EXISTS "${_fmc_dotnet_candidate}")
      set(FMC_DOTNET "${_fmc_dotnet_candidate}")
      break()
    endif()
  endforeach()
endif()
if(NOT FMC_DOTNET)
  message(FATAL_ERROR
    "dotnet CLI not found (required to publish Formycareer.SelectionHost). "
    "Install the .NET SDK from https://dotnet.microsoft.com/download and/or add "
    "dotnet to PATH, then re-configure the Windows build.")
endif()

set(_fmc_selection_proj
    "${CMAKE_CURRENT_SOURCE_DIR}/../../../../native/selection_host/Formycareer.SelectionHost/Formycareer.SelectionHost.csproj")
set(_fmc_sel_pub "${CMAKE_BINARY_DIR}/selection_host_publish")

set(_fmc_playwright_translate_src "${CMAKE_SOURCE_DIR}/../third_party/playwright_translate")
get_filename_component(_fmc_playwright_translate_abs "${_fmc_playwright_translate_src}" ABSOLUTE)

# Windows / MSBuild: CMake emits `if %errorlevel% neq 0` between POST_BUILD steps;
# after `dotnet publish` that can expand to invalid syntax ("filename incorrect").
# Delegate the whole sequence to runner_post_build.bat (`|| exit /b 1` per step).
if(WIN32)
  add_custom_command(
    TARGET ${BINARY_NAME}
    POST_BUILD
    COMMAND
      cmd
      /c
      "${CMAKE_CURRENT_SOURCE_DIR}/runner_post_build.bat"
      "${FMC_DOTNET}"
      "${_fmc_selection_proj}"
      "${_fmc_sel_pub}"
      "$<TARGET_FILE_DIR:${BINARY_NAME}>"
      "${CMAKE_COMMAND}"
      "${_fmc_playwright_translate_abs}"
      "${CMAKE_CURRENT_SOURCE_DIR}/sync_playwright_translate.bat"
    COMMENT "Publish SelectionHost + optional Playwright sidecar (${FMC_DOTNET})")
else()
  add_custom_command(
    TARGET ${BINARY_NAME}
    POST_BUILD
    COMMAND
      "${FMC_DOTNET}"
      publish
      "${_fmc_selection_proj}"
      -c
      Release
      -r
      win-x64
      --self-contained
      false
      -o
      "${_fmc_sel_pub}"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_fmc_sel_pub}/Formycareer.SelectionHost.exe"
            "$<TARGET_FILE_DIR:${BINARY_NAME}>/Formycareer.SelectionHost.exe"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_fmc_sel_pub}/Formycareer.SelectionHost.dll"
            "$<TARGET_FILE_DIR:${BINARY_NAME}>/Formycareer.SelectionHost.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_fmc_sel_pub}/Formycareer.UiaSelection.dll"
            "$<TARGET_FILE_DIR:${BINARY_NAME}>/Formycareer.UiaSelection.dll"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_fmc_sel_pub}/Formycareer.SelectionHost.runtimeconfig.json"
            "$<TARGET_FILE_DIR:${BINARY_NAME}>/Formycareer.SelectionHost.runtimeconfig.json"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${_fmc_sel_pub}/Formycareer.SelectionHost.deps.json"
            "$<TARGET_FILE_DIR:${BINARY_NAME}>/Formycareer.SelectionHost.deps.json"
    COMMENT "Publish SelectionHost (${FMC_DOTNET})")
endif()
