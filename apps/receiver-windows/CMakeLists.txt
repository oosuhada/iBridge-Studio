cmake_minimum_required(VERSION 3.21)

project(ibridge_receiver_windows LANGUAGES CXX)

add_executable(ibridge-receiver
  src/main.cpp
)

target_compile_features(ibridge-receiver PRIVATE cxx_std_17)

if(NOT WIN32)
  message(FATAL_ERROR "ibridge-receiver currently targets Windows only because the Plan A renderer uses Win32 and D3D11.")
endif()

target_compile_definitions(ibridge-receiver PRIVATE
  NOMINMAX
  WIN32_LEAN_AND_MEAN
)

target_link_libraries(ibridge-receiver PRIVATE
  d3d11
  dxgi
  d3dcompiler
)
