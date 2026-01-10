#include <winsock2.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <mfapi.h>
#include <mfidl.h>
#include <mfreadwrite.h>
#include <wrl/client.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <sstream>
#include <stdexcept>
#include <string>
#include <thread>
#include <vector>

using Microsoft::WRL::ComPtr;
using Clock = std::chrono::steady_clock;

namespace {

struct Options {
  int width = 5120;
  int height = 2880;
  int output_width = 0;
  int output_height = 0;
  bool output_resolution_set = false;
  int fps = 60;
  int duration_seconds = 60;
  bool synthetic = false;
  bool fullscreen = false;
  bool vsync = true;
  bool static_frame = false;
  bool gpu_pattern = false;
  bool uncapped = false;
  bool hud = true;
  bool transport_sink = false;
  int port = 48320;
  std::string scale_mode = "nearest";
  std::string csv_path;
  std::string decode_file;
};

struct FrameStats {
  uint64_t frame_id = 0;
  double fill_ms = 0.0;
  double upload_ms = 0.0;
  double draw_present_ms = 0.0;
  double total_ms = 0.0;
  bool missed_budget = false;
};

#pragma pack(push, 1)
struct ProtocolFrameHeaderV0 {
  uint32_t magic = 0;
  uint16_t version = 0;
  uint16_t header_len = 0;
  uint64_t session_id = 0;
  uint64_t frame_id = 0;
  uint16_t chunk_id = 0;
  uint16_t chunk_count = 0;
  uint16_t width = 0;
  uint16_t height = 0;
  uint16_t fps_target = 0;
  uint8_t codec = 0;
  uint8_t color_format = 0;
  uint32_t flags = 0;
  uint64_t capture_ns = 0;
  uint64_t encode_start_ns = 0;
  uint64_t encode_done_ns = 0;
  uint64_t send_ns = 0;
  uint32_t payload_len = 0;
  uint32_t dropped_before = 0;
};
#pragma pack(pop)

static_assert(sizeof(ProtocolFrameHeaderV0) == 80,
              "protocol v0 frame header must be 80 bytes");

struct TransportStats {
  uint64_t frame_id = 0;
  uint32_t payload_len = 0;
  uint32_t dropped_before = 0;
  uint64_t missing_before = 0;
  double receive_ms = 0.0;
  uint16_t width = 0;
  uint16_t height = 0;
  uint16_t fps_target = 0;
  uint8_t codec = 0;
  uint32_t flags = 0;
};

struct DecodeFrameStats {
  uint64_t frame_id = 0;
  double decode_ms = 0.0;
  double upload_ms = 0.0;
  double render_ms = 0.0;
  double total_ms = 0.0;
  bool missed_budget = false;
};

double MsSince(Clock::time_point start, Clock::time_point end) {
  return std::chrono::duration<double, std::milli>(end - start).count();
}

std::string HResultMessage(HRESULT hr) {
  char* buffer = nullptr;
  DWORD size = FormatMessageA(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr, static_cast<DWORD>(hr), MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<char*>(&buffer), 0, nullptr);

  std::ostringstream oss;
  oss << "HRESULT 0x" << std::hex << static_cast<unsigned long>(hr);
  if (size > 0 && buffer != nullptr) {
    oss << ": " << buffer;
    LocalFree(buffer);
  }
  return oss.str();
}

void CheckHR(HRESULT hr, const char* label) {
  if (FAILED(hr)) {
    std::ostringstream oss;
    oss << label << " failed: " << HResultMessage(hr);
    throw std::runtime_error(oss.str());
  }
}

void PrintUsage() {
  std::cout
      << "ibridge-receiver --synthetic --resolution 5120x2880 --fps 60 "
         "--duration 60 [--fullscreen] [--csv path] [--no-vsync] "
         "[--static-frame] [--gpu-pattern] [--uncapped] [--no-hud] "
         "[--output-resolution 5120x2880] [--scale-mode nearest|linear]\n"
         "ibridge-receiver --transport-sink --port 48320 --duration 10 "
         "[--csv path]\n"
         "ibridge-receiver --decode-file sample.mp4 --fullscreen "
         "[--output-resolution 5120x2880] [--scale-mode linear] [--csv path]\n";
}

bool ConsumeValue(int& index, int argc, char** argv, std::string* value) {
  if (index + 1 >= argc) {
    return false;
  }
  *value = argv[++index];
  return true;
}

void ParseResolution(const std::string& text, int* width, int* height) {
  const size_t x = text.find('x');
  if (x == std::string::npos) {
    throw std::runtime_error("resolution must look like 5120x2880");
  }
  *width = std::stoi(text.substr(0, x));
  *height = std::stoi(text.substr(x + 1));
  if (*width <= 0 || *height <= 0) {
    throw std::runtime_error("resolution must be positive");
  }
}

Options ParseOptions(int argc, char** argv) {
  Options options;
  for (int i = 1; i < argc; ++i) {
    std::string arg = argv[i];
    std::string value;
    if (arg == "--help" || arg == "-h") {
      PrintUsage();
      std::exit(0);
    } else if (arg == "--transport-sink") {
      options.transport_sink = true;
    } else if (arg == "--decode-file") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--decode-file requires a value");
      }
      options.decode_file = value;
    } else if (arg.rfind("--decode-file=", 0) == 0) {
      options.decode_file = arg.substr(std::strlen("--decode-file="));
    } else if (arg == "--synthetic") {
      options.synthetic = true;
    } else if (arg == "--resolution") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--resolution requires a value");
      }
      ParseResolution(value, &options.width, &options.height);
    } else if (arg.rfind("--resolution=", 0) == 0) {
      ParseResolution(arg.substr(std::strlen("--resolution=")), &options.width,
                      &options.height);
    } else if (arg == "--output-resolution") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--output-resolution requires a value");
      }
      ParseResolution(value, &options.output_width, &options.output_height);
      options.output_resolution_set = true;
    } else if (arg.rfind("--output-resolution=", 0) == 0) {
      ParseResolution(arg.substr(std::strlen("--output-resolution=")),
                      &options.output_width, &options.output_height);
      options.output_resolution_set = true;
    } else if (arg == "--fps") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--fps requires a value");
      }
      options.fps = std::stoi(value);
    } else if (arg.rfind("--fps=", 0) == 0) {
      options.fps = std::stoi(arg.substr(std::strlen("--fps=")));
    } else if (arg == "--duration") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--duration requires a value");
      }
      options.duration_seconds = std::stoi(value);
    } else if (arg.rfind("--duration=", 0) == 0) {
      options.duration_seconds = std::stoi(arg.substr(std::strlen("--duration=")));
    } else if (arg == "--fullscreen") {
      options.fullscreen = true;
    } else if (arg == "--no-vsync") {
      options.vsync = false;
    } else if (arg == "--static-frame") {
      options.static_frame = true;
    } else if (arg == "--gpu-pattern") {
      options.gpu_pattern = true;
    } else if (arg == "--uncapped") {
      options.uncapped = true;
    } else if (arg == "--no-hud") {
      options.hud = false;
    } else if (arg == "--port") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--port requires a value");
      }
      options.port = std::stoi(value);
    } else if (arg.rfind("--port=", 0) == 0) {
      options.port = std::stoi(arg.substr(std::strlen("--port=")));
    } else if (arg == "--scale-mode") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--scale-mode requires a value");
      }
      options.scale_mode = value;
    } else if (arg.rfind("--scale-mode=", 0) == 0) {
      options.scale_mode = arg.substr(std::strlen("--scale-mode="));
    } else if (arg == "--csv") {
      if (!ConsumeValue(i, argc, argv, &value)) {
        throw std::runtime_error("--csv requires a value");
      }
      options.csv_path = value;
    } else if (arg.rfind("--csv=", 0) == 0) {
      options.csv_path = arg.substr(std::strlen("--csv="));
    } else {
      throw std::runtime_error("unknown argument: " + arg);
    }
  }

  if (!options.synthetic && !options.transport_sink && options.decode_file.empty()) {
    throw std::runtime_error("choose --synthetic, --transport-sink, or --decode-file");
  }
  if (options.fps <= 0 || options.duration_seconds <= 0) {
    throw std::runtime_error("--fps and --duration must be positive");
  }
  if (options.output_width <= 0) {
    options.output_width = options.width;
  }
  if (options.output_height <= 0) {
    options.output_height = options.height;
  }
  if (options.scale_mode != "nearest" && options.scale_mode != "linear") {
    throw std::runtime_error("--scale-mode must be nearest or linear");
  }
  return options;
}

LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  switch (msg) {
    case WM_KEYDOWN:
      if (wparam == VK_ESCAPE) {
        DestroyWindow(hwnd);
        return 0;
      }
      break;
    case WM_DESTROY:
      PostQuitMessage(0);
      return 0;
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

std::wstring g_hud_text;

LRESULT CALLBACK HudWindowProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  switch (msg) {
    case WM_PAINT: {
      PAINTSTRUCT ps = {};
      HDC dc = BeginPaint(hwnd, &ps);
      RECT rect = {};
      GetClientRect(hwnd, &rect);
      HBRUSH brush = CreateSolidBrush(RGB(0, 0, 0));
      FillRect(dc, &rect, brush);
      DeleteObject(brush);
      SetBkMode(dc, TRANSPARENT);
      SetTextColor(dc, RGB(120, 255, 180));
      DrawTextW(dc, g_hud_text.c_str(), -1, &rect,
                DT_LEFT | DT_TOP | DT_NOPREFIX | DT_WORDBREAK);
      EndPaint(hwnd, &ps);
      return 0;
    }
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

class HudOverlay {
 public:
  void Create(HWND target, bool enabled) {
    if (!enabled) {
      return;
    }

    HINSTANCE instance = GetModuleHandleW(nullptr);
    const wchar_t* class_name = L"iBridgeHudOverlay";
    WNDCLASSW wc = {};
    wc.lpfnWndProc = HudWindowProc;
    wc.hInstance = instance;
    wc.lpszClassName = class_name;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    RegisterClassW(&wc);

    RECT target_rect = {};
    GetWindowRect(target, &target_rect);
    hwnd_ = CreateWindowExW(WS_EX_TOPMOST | WS_EX_LAYERED | WS_EX_TOOLWINDOW,
                            class_name, L"", WS_POPUP | WS_VISIBLE,
                            target_rect.left + 24, target_rect.top + 24, 620, 150,
                            nullptr, nullptr, instance, nullptr);
    if (!hwnd_) {
      CheckHR(HRESULT_FROM_WIN32(GetLastError()), "CreateWindowExW HUD");
    }
    SetLayeredWindowAttributes(hwnd_, 0, 210, LWA_ALPHA);
  }

  void Update(const std::string& text) {
    if (!hwnd_) {
      return;
    }
    g_hud_text.assign(text.begin(), text.end());
    InvalidateRect(hwnd_, nullptr, TRUE);
    UpdateWindow(hwnd_);
  }

 private:
  HWND hwnd_ = nullptr;
};

HWND CreateBenchmarkWindow(const Options& options) {
  SetProcessDPIAware();

  HINSTANCE instance = GetModuleHandleW(nullptr);
  const wchar_t* class_name = L"iBridgePlanASyntheticWindow";

  WNDCLASSW wc = {};
  wc.lpfnWndProc = WindowProc;
  wc.hInstance = instance;
  wc.lpszClassName = class_name;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  RegisterClassW(&wc);

  DWORD style = options.fullscreen ? WS_POPUP : WS_OVERLAPPEDWINDOW;
  RECT rect = {0, 0, options.output_width, options.output_height};

  int x = CW_USEDEFAULT;
  int y = CW_USEDEFAULT;
  int window_width = options.output_width;
  int window_height = options.output_height;

  if (options.fullscreen) {
    MONITORINFO monitor_info = {};
    monitor_info.cbSize = sizeof(monitor_info);
    HMONITOR monitor = MonitorFromPoint({0, 0}, MONITOR_DEFAULTTOPRIMARY);
    GetMonitorInfoW(monitor, &monitor_info);
    rect = monitor_info.rcMonitor;
    x = rect.left;
    y = rect.top;
    window_width = rect.right - rect.left;
    window_height = rect.bottom - rect.top;
  } else {
    AdjustWindowRect(&rect, style, FALSE);
    window_width = rect.right - rect.left;
    window_height = rect.bottom - rect.top;
  }

  HWND hwnd = CreateWindowExW(0, class_name, L"iBridge Studio Synthetic Renderer",
                              style, x, y, window_width, window_height, nullptr,
                              nullptr, instance, nullptr);
  if (!hwnd) {
    CheckHR(HRESULT_FROM_WIN32(GetLastError()), "CreateWindowExW");
  }
  ShowWindow(hwnd, SW_SHOW);
  UpdateWindow(hwnd);
  return hwnd;
}

ComPtr<ID3DBlob> CompileShader(const char* source,
                               const char* entry,
                               const char* target) {
  ComPtr<ID3DBlob> shader;
  ComPtr<ID3DBlob> errors;
  HRESULT hr = D3DCompile(source, std::strlen(source), nullptr, nullptr, nullptr,
                          entry, target, D3DCOMPILE_ENABLE_STRICTNESS, 0,
                          &shader, &errors);
  if (FAILED(hr)) {
    std::string message = errors ? static_cast<const char*>(errors->GetBufferPointer())
                                 : HResultMessage(hr);
    throw std::runtime_error("D3DCompile failed: " + message);
  }
  return shader;
}

class D3DRenderer {
 public:
  D3DRenderer(HWND hwnd, const Options& options) : options_(options) {
    CreateDeviceAndSwapChain(hwnd);
    CreateRenderTarget();
    CreateFrameTexture();
    CreateShaders();
    CreateSampler();
  }

  FrameStats Render(uint64_t frame_id,
                    const std::vector<uint32_t>& pixels,
                    bool upload_frame) {
    FrameStats stats;
    stats.frame_id = frame_id;

    if (upload_frame) {
      auto upload_start = Clock::now();
      context_->UpdateSubresource(
          frame_texture_.Get(), 0, nullptr, pixels.data(),
          static_cast<UINT>(options_.width * sizeof(uint32_t)), 0);
      auto upload_end = Clock::now();
      stats.upload_ms = MsSince(upload_start, upload_end);
    }

    auto draw_start = Clock::now();
    const float clear_color[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    context_->ClearRenderTargetView(render_target_.Get(), clear_color);
    context_->OMSetRenderTargets(1, render_target_.GetAddressOf(), nullptr);
    context_->RSSetViewports(1, &viewport_);
    context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    context_->VSSetShader(vertex_shader_.Get(), nullptr, 0);
    context_->PSSetShader(
        options_.gpu_pattern ? gpu_pixel_shader_.Get() : pixel_shader_.Get(),
        nullptr, 0);
    context_->PSSetSamplers(0, 1, sampler_.GetAddressOf());
    if (!options_.gpu_pattern) {
      context_->PSSetShaderResources(0, 1, frame_srv_.GetAddressOf());
    }
    context_->Draw(3, 0);
    CheckHR(swap_chain_->Present(options_.vsync ? 1 : 0, 0), "Present");
    auto draw_end = Clock::now();
    stats.draw_present_ms = MsSince(draw_start, draw_end);
    return stats;
  }

 private:
  void CreateDeviceAndSwapChain(HWND hwnd) {
    DXGI_SWAP_CHAIN_DESC desc = {};
    desc.BufferDesc.Width = static_cast<UINT>(options_.output_width);
    desc.BufferDesc.Height = static_cast<UINT>(options_.output_height);
    desc.BufferDesc.RefreshRate.Numerator = static_cast<UINT>(options_.fps);
    desc.BufferDesc.RefreshRate.Denominator = 1;
    desc.BufferDesc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.SampleDesc.Quality = 0;
    desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.BufferCount = 2;
    desc.OutputWindow = hwnd;
    desc.Windowed = TRUE;
    desc.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    D3D_FEATURE_LEVEL requested[] = {
        D3D_FEATURE_LEVEL_11_1,
        D3D_FEATURE_LEVEL_11_0,
    };
    D3D_FEATURE_LEVEL created = D3D_FEATURE_LEVEL_11_0;

    CheckHR(D3D11CreateDeviceAndSwapChain(
                nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
                D3D11_CREATE_DEVICE_BGRA_SUPPORT, requested, 2,
                D3D11_SDK_VERSION, &desc, &swap_chain_, &device_, &created,
                &context_),
            "D3D11CreateDeviceAndSwapChain");
  }

  void CreateRenderTarget() {
    ComPtr<ID3D11Texture2D> back_buffer;
    CheckHR(swap_chain_->GetBuffer(0, IID_PPV_ARGS(&back_buffer)),
            "IDXGISwapChain::GetBuffer");
    CheckHR(device_->CreateRenderTargetView(back_buffer.Get(), nullptr,
                                            &render_target_),
            "CreateRenderTargetView");
    viewport_.TopLeftX = 0.0f;
    viewport_.TopLeftY = 0.0f;
    viewport_.Width = static_cast<float>(options_.output_width);
    viewport_.Height = static_cast<float>(options_.output_height);
    viewport_.MinDepth = 0.0f;
    viewport_.MaxDepth = 1.0f;
  }

  void CreateFrameTexture() {
    D3D11_TEXTURE2D_DESC desc = {};
    desc.Width = static_cast<UINT>(options_.width);
    desc.Height = static_cast<UINT>(options_.height);
    desc.MipLevels = 1;
    desc.ArraySize = 1;
    desc.Format = DXGI_FORMAT_B8G8R8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.Usage = D3D11_USAGE_DEFAULT;
    desc.BindFlags = D3D11_BIND_SHADER_RESOURCE;

    CheckHR(device_->CreateTexture2D(&desc, nullptr, &frame_texture_),
            "CreateTexture2D");
    CheckHR(device_->CreateShaderResourceView(frame_texture_.Get(), nullptr,
                                              &frame_srv_),
            "CreateShaderResourceView");
  }

  void CreateShaders() {
    const char* hlsl = R"(
Texture2D frame_texture : register(t0);
SamplerState frame_sampler : register(s0);

struct VsOut {
  float4 pos : SV_POSITION;
  float2 uv : TEXCOORD0;
};

VsOut vs_main(uint id : SV_VertexID) {
  float2 pos[3] = {
    float2(-1.0, -1.0),
    float2(-1.0,  3.0),
    float2( 3.0, -1.0)
  };
  float2 uv[3] = {
    float2(0.0, 1.0),
    float2(0.0, -1.0),
    float2(2.0, 1.0)
  };
  VsOut output;
  output.pos = float4(pos[id], 0.0, 1.0);
  output.uv = uv[id];
  return output;
}

float4 ps_main(VsOut input) : SV_TARGET {
  return frame_texture.Sample(frame_sampler, input.uv);
}

float4 ps_gpu_pattern(VsOut input) : SV_TARGET {
  float2 grid = floor(input.uv * float2(80.0, 45.0));
  float checker = fmod(grid.x + grid.y, 2.0);
  float3 a = float3(input.uv.x, input.uv.y, 0.15);
  float3 b = float3(0.05, input.uv.x, input.uv.y);
  return float4(lerp(a, b, checker), 1.0);
}
)";

    ComPtr<ID3DBlob> vs = CompileShader(hlsl, "vs_main", "vs_5_0");
    ComPtr<ID3DBlob> ps = CompileShader(hlsl, "ps_main", "ps_5_0");
    ComPtr<ID3DBlob> gpu_ps = CompileShader(hlsl, "ps_gpu_pattern", "ps_5_0");
    CheckHR(device_->CreateVertexShader(vs->GetBufferPointer(),
                                        vs->GetBufferSize(), nullptr,
                                        &vertex_shader_),
            "CreateVertexShader");
    CheckHR(device_->CreatePixelShader(ps->GetBufferPointer(),
                                       ps->GetBufferSize(), nullptr,
                                       &pixel_shader_),
            "CreatePixelShader");
    CheckHR(device_->CreatePixelShader(gpu_ps->GetBufferPointer(),
                                       gpu_ps->GetBufferSize(), nullptr,
                                       &gpu_pixel_shader_),
            "CreatePixelShader");
  }

  void CreateSampler() {
    D3D11_SAMPLER_DESC desc = {};
    desc.Filter = options_.scale_mode == "linear" ? D3D11_FILTER_MIN_MAG_MIP_LINEAR
                                                   : D3D11_FILTER_MIN_MAG_MIP_POINT;
    desc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
    desc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
    desc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;
    desc.ComparisonFunc = D3D11_COMPARISON_NEVER;
    desc.MinLOD = 0;
    desc.MaxLOD = D3D11_FLOAT32_MAX;
    CheckHR(device_->CreateSamplerState(&desc, &sampler_), "CreateSamplerState");
  }

  Options options_;
  ComPtr<ID3D11Device> device_;
  ComPtr<ID3D11DeviceContext> context_;
  ComPtr<IDXGISwapChain> swap_chain_;
  ComPtr<ID3D11RenderTargetView> render_target_;
  ComPtr<ID3D11Texture2D> frame_texture_;
  ComPtr<ID3D11ShaderResourceView> frame_srv_;
  ComPtr<ID3D11VertexShader> vertex_shader_;
  ComPtr<ID3D11PixelShader> pixel_shader_;
  ComPtr<ID3D11PixelShader> gpu_pixel_shader_;
  ComPtr<ID3D11SamplerState> sampler_;
  D3D11_VIEWPORT viewport_ = {};
};

void FillSyntheticFrame(std::vector<uint32_t>* pixels,
                        int width,
                        int height,
                        uint64_t frame_id) {
  uint32_t* data = pixels->data();
  const uint32_t frame = static_cast<uint32_t>(frame_id & 0xff);
  for (int y = 0; y < height; ++y) {
    const uint32_t gy = static_cast<uint32_t>((y + frame) & 0xff);
    for (int x = 0; x < width; ++x) {
      const uint32_t bx = static_cast<uint32_t>((x + frame) & 0xff);
      const uint32_t r = static_cast<uint32_t>(((x >> 5) + (y >> 5) + frame) & 0xff);
      data[static_cast<size_t>(y) * width + x] =
          0xff000000u | (r << 16) | (gy << 8) | bx;
    }
  }
}

bool PumpMessages() {
  MSG msg = {};
  while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
    if (msg.message == WM_QUIT) {
      return false;
    }
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
  }
  return true;
}

double Percentile(std::vector<double> values, double percentile) {
  if (values.empty()) {
    return 0.0;
  }
  std::sort(values.begin(), values.end());
  const double index = (percentile / 100.0) * (values.size() - 1);
  const size_t lower = static_cast<size_t>(index);
  const size_t upper = std::min(lower + 1, values.size() - 1);
  const double fraction = index - static_cast<double>(lower);
  return values[lower] * (1.0 - fraction) + values[upper] * fraction;
}

void WriteCsv(const std::string& path, const std::vector<FrameStats>& stats) {
  if (path.empty()) {
    return;
  }
  std::ofstream csv(path);
  if (!csv) {
    throw std::runtime_error("could not open CSV output: " + path);
  }
  csv << "frame_id,fill_ms,upload_ms,draw_present_ms,total_ms,missed_budget\n";
  csv << std::fixed << std::setprecision(4);
  for (const FrameStats& frame : stats) {
    csv << frame.frame_id << ',' << frame.fill_ms << ',' << frame.upload_ms << ','
        << frame.draw_present_ms << ',' << frame.total_ms << ','
        << (frame.missed_budget ? 1 : 0) << '\n';
  }
}

void WriteTransportCsv(const std::string& path,
                       const std::vector<TransportStats>& stats) {
  if (path.empty()) {
    return;
  }
  std::ofstream csv(path);
  if (!csv) {
    throw std::runtime_error("could not open CSV output: " + path);
  }
  csv << "frame_id,payload_len,dropped_before,missing_before,receive_ms,width,"
         "height,fps_target,codec,flags\n";
  csv << std::fixed << std::setprecision(4);
  for (const TransportStats& frame : stats) {
    csv << frame.frame_id << ',' << frame.payload_len << ','
        << frame.dropped_before << ',' << frame.missing_before << ','
        << frame.receive_ms << ',' << frame.width << ',' << frame.height << ','
        << frame.fps_target << ',' << static_cast<int>(frame.codec) << ','
        << frame.flags << '\n';
  }
}

void WriteDecodeCsv(const std::string& path,
                    const std::vector<DecodeFrameStats>& stats) {
  if (path.empty()) {
    return;
  }
  std::ofstream csv(path);
  if (!csv) {
    throw std::runtime_error("could not open CSV output: " + path);
  }
  csv << "frame_id,decode_ms,upload_ms,render_ms,total_ms,missed_budget\n";
  csv << std::fixed << std::setprecision(4);
  for (const DecodeFrameStats& frame : stats) {
    csv << frame.frame_id << ',' << frame.decode_ms << ',' << frame.upload_ms
        << ',' << frame.render_ms << ',' << frame.total_ms << ','
        << (frame.missed_budget ? 1 : 0) << '\n';
  }
}

class WinsockSession {
 public:
  WinsockSession() {
    WSADATA data = {};
    const int result = WSAStartup(MAKEWORD(2, 2), &data);
    if (result != 0) {
      throw std::runtime_error("WSAStartup failed: " + std::to_string(result));
    }
  }

  ~WinsockSession() { WSACleanup(); }
};

class SocketHandle {
 public:
  explicit SocketHandle(SOCKET socket = INVALID_SOCKET) : socket_(socket) {}
  ~SocketHandle() { Close(); }

  SocketHandle(const SocketHandle&) = delete;
  SocketHandle& operator=(const SocketHandle&) = delete;

  SOCKET get() const { return socket_; }

  SOCKET release() {
    SOCKET out = socket_;
    socket_ = INVALID_SOCKET;
    return out;
  }

  void reset(SOCKET socket) {
    Close();
    socket_ = socket;
  }

 private:
  void Close() {
    if (socket_ != INVALID_SOCKET) {
      closesocket(socket_);
      socket_ = INVALID_SOCKET;
    }
  }

  SOCKET socket_ = INVALID_SOCKET;
};

class ComSession {
 public:
  ComSession() {
    CheckHR(CoInitializeEx(nullptr, COINIT_MULTITHREADED), "CoInitializeEx");
  }

  ~ComSession() { CoUninitialize(); }

  ComSession(const ComSession&) = delete;
  ComSession& operator=(const ComSession&) = delete;
};

class MediaFoundationSession {
 public:
  MediaFoundationSession() {
    CheckHR(MFStartup(MF_VERSION, MFSTARTUP_LITE), "MFStartup");
  }

  ~MediaFoundationSession() { MFShutdown(); }

  MediaFoundationSession(const MediaFoundationSession&) = delete;
  MediaFoundationSession& operator=(const MediaFoundationSession&) = delete;
};

std::wstring Utf8ToWide(const std::string& text) {
  if (text.empty()) {
    return std::wstring();
  }
  const int required = MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, nullptr, 0);
  if (required <= 0) {
    CheckHR(HRESULT_FROM_WIN32(GetLastError()), "MultiByteToWideChar size");
  }
  std::wstring wide(static_cast<size_t>(required), L'\0');
  MultiByteToWideChar(CP_UTF8, 0, text.c_str(), -1, wide.data(), required);
  wide.resize(static_cast<size_t>(required - 1));
  return wide;
}

struct DecodedVideoFrame {
  std::vector<uint32_t> pixels;
  int width = 0;
  int height = 0;
  LONGLONG sample_time = 0;
};

class MediaFileDecoder {
 public:
  explicit MediaFileDecoder(const std::string& path) {
    const std::wstring wide_path = Utf8ToWide(path);
    CheckHR(MFCreateSourceReaderFromURL(wide_path.c_str(), nullptr, &reader_),
            "MFCreateSourceReaderFromURL");

    ComPtr<IMFMediaType> output_type;
    CheckHR(MFCreateMediaType(&output_type), "MFCreateMediaType output");
    CheckHR(output_type->SetGUID(MF_MT_MAJOR_TYPE, MFMediaType_Video),
            "Set output major type");
    CheckHR(output_type->SetGUID(MF_MT_SUBTYPE, MFVideoFormat_RGB32),
            "Set output subtype RGB32");
    CheckHR(reader_->SetCurrentMediaType(MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                                         nullptr, output_type.Get()),
            "SetCurrentMediaType RGB32");

    ComPtr<IMFMediaType> current_type;
    CheckHR(reader_->GetCurrentMediaType(MF_SOURCE_READER_FIRST_VIDEO_STREAM,
                                         &current_type),
            "GetCurrentMediaType");
    UINT32 width = 0;
    UINT32 height = 0;
    CheckHR(MFGetAttributeSize(current_type.Get(), MF_MT_FRAME_SIZE, &width,
                               &height),
            "MFGetAttributeSize frame size");
    width_ = static_cast<int>(width);
    height_ = static_cast<int>(height);
  }

  int width() const { return width_; }
  int height() const { return height_; }

  bool ReadFrame(DecodedVideoFrame* frame, double* decode_ms) {
    DWORD stream_index = 0;
    DWORD flags = 0;
    LONGLONG sample_time = 0;
    ComPtr<IMFSample> sample;

    const auto start = Clock::now();
    CheckHR(reader_->ReadSample(MF_SOURCE_READER_FIRST_VIDEO_STREAM, 0,
                                &stream_index, &flags, &sample_time, &sample),
            "ReadSample");
    const auto end = Clock::now();
    *decode_ms = MsSince(start, end);

    if (flags & MF_SOURCE_READERF_ENDOFSTREAM) {
      return false;
    }
    if (!sample) {
      return true;
    }

    ComPtr<IMFMediaBuffer> buffer;
    CheckHR(sample->ConvertToContiguousBuffer(&buffer),
            "ConvertToContiguousBuffer");

    BYTE* data = nullptr;
    DWORD max_length = 0;
    DWORD current_length = 0;
    CheckHR(buffer->Lock(&data, &max_length, &current_length), "buffer Lock");
    const size_t expected =
        static_cast<size_t>(width_) * static_cast<size_t>(height_) * sizeof(uint32_t);
    if (current_length < expected) {
      buffer->Unlock();
      throw std::runtime_error("decoded frame is smaller than expected RGB32 size");
    }

    frame->pixels.resize(static_cast<size_t>(width_) * height_);
    std::memcpy(frame->pixels.data(), data, expected);
    buffer->Unlock();
    frame->width = width_;
    frame->height = height_;
    frame->sample_time = sample_time;
    return true;
  }

 private:
  ComPtr<IMFSourceReader> reader_;
  int width_ = 0;
  int height_ = 0;
};

bool RecvAll(SOCKET socket, void* buffer, int bytes) {
  char* cursor = static_cast<char*>(buffer);
  int received = 0;
  while (received < bytes) {
    const int result = recv(socket, cursor + received, bytes - received, 0);
    if (result <= 0) {
      return false;
    }
    received += result;
  }
  return true;
}

std::string RecvLine(SOCKET socket) {
  std::string line;
  char ch = 0;
  while (recv(socket, &ch, 1, 0) == 1) {
    if (ch == '\n') {
      break;
    }
    line.push_back(ch);
    if (line.size() > 4096) {
      throw std::runtime_error("handshake line too long");
    }
  }
  return line;
}

int RunTransportSink(const Options& options) {
  constexpr uint32_t kMagic = 0x47524249;
  constexpr uint16_t kVersion = 0;
  constexpr uint16_t kHeaderLen = 80;

  WinsockSession winsock;
  SocketHandle listener(socket(AF_INET, SOCK_STREAM, IPPROTO_TCP));
  if (listener.get() == INVALID_SOCKET) {
    throw std::runtime_error("socket failed");
  }

  sockaddr_in address = {};
  address.sin_family = AF_INET;
  address.sin_addr.s_addr = htonl(INADDR_ANY);
  address.sin_port = htons(static_cast<u_short>(options.port));

  int reuse = 1;
  setsockopt(listener.get(), SOL_SOCKET, SO_REUSEADDR,
             reinterpret_cast<const char*>(&reuse), sizeof(reuse));

  if (bind(listener.get(), reinterpret_cast<sockaddr*>(&address),
           sizeof(address)) == SOCKET_ERROR) {
    throw std::runtime_error("bind failed: " + std::to_string(WSAGetLastError()));
  }
  if (listen(listener.get(), 1) == SOCKET_ERROR) {
    throw std::runtime_error("listen failed: " + std::to_string(WSAGetLastError()));
  }

  std::cout << "iBridge Studio receiver transport sink listening on port "
            << options.port << "\n";

  SocketHandle client(accept(listener.get(), nullptr, nullptr));
  if (client.get() == INVALID_SOCKET) {
    throw std::runtime_error("accept failed: " + std::to_string(WSAGetLastError()));
  }

  int timeout_ms = 10000;
  setsockopt(client.get(), SOL_SOCKET, SO_RCVTIMEO,
             reinterpret_cast<const char*>(&timeout_ms), sizeof(timeout_ms));

  const std::string handshake = RecvLine(client.get());
  if (handshake.find("\"magic\":\"IBRIDGE\"") == std::string::npos ||
      handshake.find("\"version\":0") == std::string::npos) {
    throw std::runtime_error("bad protocol handshake");
  }

  std::vector<TransportStats> stats;
  const auto run_start = Clock::now();
  uint64_t previous_frame_id = 0;
  bool have_previous = false;
  uint64_t missing_total = 0;
  uint64_t payload_total = 0;

  while (std::chrono::duration_cast<std::chrono::seconds>(Clock::now() - run_start)
             .count() < options.duration_seconds) {
    ProtocolFrameHeaderV0 header = {};
    const auto frame_start = Clock::now();
    if (!RecvAll(client.get(), &header, sizeof(header))) {
      break;
    }

    if (header.magic != kMagic) {
      throw std::runtime_error("wrong protocol magic");
    }
    if (header.version != kVersion) {
      throw std::runtime_error("unsupported protocol version");
    }
    if (header.header_len != kHeaderLen) {
      throw std::runtime_error("unsupported protocol header length");
    }

    std::vector<char> payload(header.payload_len);
    if (!payload.empty() &&
        !RecvAll(client.get(), payload.data(), static_cast<int>(payload.size()))) {
      break;
    }

    TransportStats frame = {};
    frame.frame_id = header.frame_id;
    frame.payload_len = header.payload_len;
    frame.dropped_before = header.dropped_before;
    frame.width = header.width;
    frame.height = header.height;
    frame.fps_target = header.fps_target;
    frame.codec = header.codec;
    frame.flags = header.flags;

    if (have_previous && header.frame_id > previous_frame_id + 1) {
      frame.missing_before = header.frame_id - previous_frame_id - 1;
      missing_total += frame.missing_before;
    }
    previous_frame_id = header.frame_id;
    have_previous = true;

    frame.receive_ms = MsSince(frame_start, Clock::now());
    payload_total += header.payload_len;
    stats.push_back(frame);
  }

  WriteTransportCsv(options.csv_path, stats);

  const double elapsed_sec =
      std::chrono::duration<double>(Clock::now() - run_start).count();
  const double mbps =
      elapsed_sec > 0.0 ? (static_cast<double>(payload_total) * 8.0 / 1'000'000.0) /
                               elapsed_sec
                         : 0.0;

  std::cout << std::fixed << std::setprecision(3)
            << "iBridge Studio transport sink\n"
            << "frames_received=" << stats.size() << '\n'
            << "payload_bytes=" << payload_total << '\n'
            << "receive_mbps=" << mbps << '\n'
            << "missing_frames=" << missing_total << '\n'
            << "csv=" << (options.csv_path.empty() ? "none" : options.csv_path)
            << '\n';

  return 0;
}

int RunSynthetic(const Options& options) {
  HWND hwnd = CreateBenchmarkWindow(options);
  HudOverlay hud;
  hud.Create(hwnd, options.hud);
  D3DRenderer renderer(hwnd, options);

  std::vector<uint32_t> pixels;
  if (!options.gpu_pattern) {
    pixels.resize(static_cast<size_t>(options.width) * options.height);
  }
  std::vector<FrameStats> stats;
  stats.reserve(static_cast<size_t>(options.fps) * options.duration_seconds);

  const double budget_ms = 1000.0 / static_cast<double>(options.fps);
  const auto run_duration = std::chrono::seconds(options.duration_seconds);
  const auto frame_duration =
      std::chrono::duration<double>(1.0 / static_cast<double>(options.fps));

  if (!options.gpu_pattern) {
    FillSyntheticFrame(&pixels, options.width, options.height, 0);
  }

  const auto run_start = Clock::now();
  auto next_frame_time = run_start;
  uint64_t frame_id = 0;

  while (Clock::now() - run_start < run_duration) {
    if (!PumpMessages()) {
      break;
    }

    const auto frame_start = Clock::now();
    FrameStats frame;
    frame.frame_id = frame_id;

    const bool fill_frame =
        !options.gpu_pattern && (!options.static_frame || frame_id == 0);
    const bool upload_frame =
        !options.gpu_pattern && (!options.static_frame || frame_id == 0);

    if (fill_frame) {
      const auto fill_start = Clock::now();
      FillSyntheticFrame(&pixels, options.width, options.height, frame_id);
      const auto fill_end = Clock::now();
      frame.fill_ms = MsSince(fill_start, fill_end);
    }

    FrameStats render_stats = renderer.Render(frame_id, pixels, upload_frame);
    frame.upload_ms = render_stats.upload_ms;
    frame.draw_present_ms = render_stats.draw_present_ms;

    const auto frame_end = Clock::now();
    frame.total_ms = MsSince(frame_start, frame_end);
    frame.missed_budget = frame.total_ms > budget_ms;
    stats.push_back(frame);

    if (frame_id % 30 == 0) {
      const double elapsed =
          std::chrono::duration<double>(Clock::now() - run_start).count();
      const double running_fps = elapsed > 0.0 ? stats.size() / elapsed : 0.0;
      std::ostringstream hud_text;
      hud_text << "iBridge Studio Receiver\n"
               << options.width << "x" << options.height << " @ " << options.fps
               << " -> " << options.output_width << "x" << options.output_height
               << " @ " << options.fps << " target\n"
               << "fps " << std::fixed << std::setprecision(2) << running_fps
               << "  total " << frame.total_ms << " ms\n"
               << "fill " << frame.fill_ms << " ms  upload " << frame.upload_ms
               << " ms  present " << frame.draw_present_ms << " ms\n"
               << "mode "
               << (options.gpu_pattern ? "gpu-pattern"
                                       : (options.static_frame ? "static" : "dynamic"))
               << " scale " << options.scale_mode;
      hud.Update(hud_text.str());
    }

    ++frame_id;
    next_frame_time += std::chrono::duration_cast<Clock::duration>(frame_duration);
    if (!options.vsync && !options.uncapped) {
      std::this_thread::sleep_until(next_frame_time);
    }
  }

  const auto run_end = Clock::now();
  const double elapsed_sec = std::chrono::duration<double>(run_end - run_start).count();
  const double actual_fps = stats.empty() ? 0.0 : stats.size() / elapsed_sec;

  std::vector<double> totals;
  totals.reserve(stats.size());
  size_t missed = 0;
  double max_total = 0.0;
  for (const FrameStats& frame : stats) {
    totals.push_back(frame.total_ms);
    if (frame.missed_budget) {
      ++missed;
    }
    max_total = std::max(max_total, frame.total_ms);
  }

  WriteCsv(options.csv_path, stats);

  std::cout << std::fixed << std::setprecision(3)
            << "iBridge Studio Plan A synthetic renderer\n"
            << "source_resolution=" << options.width << 'x' << options.height << '\n'
            << "output_resolution=" << options.output_width << 'x'
            << options.output_height << '\n'
            << "target_fps=" << options.fps << '\n'
            << "actual_fps=" << actual_fps << '\n'
            << "frames=" << stats.size() << '\n'
            << "budget_ms=" << budget_ms << '\n'
            << "p95_total_ms=" << Percentile(totals, 95.0) << '\n'
            << "max_total_ms=" << max_total << '\n'
            << "missed_frames=" << missed << '\n'
            << "vsync=" << (options.vsync ? "on" : "off") << '\n'
            << "static_frame=" << (options.static_frame ? "on" : "off") << '\n'
            << "gpu_pattern=" << (options.gpu_pattern ? "on" : "off") << '\n'
            << "uncapped=" << (options.uncapped ? "on" : "off") << '\n'
            << "scale_mode=" << options.scale_mode << '\n'
            << "hud=" << (options.hud ? "on" : "off") << '\n';

  return 0;
}

int RunDecodeFile(const Options& options) {
  ComSession com;
  MediaFoundationSession mf;
  MediaFileDecoder decoder(options.decode_file);

  Options render_options = options;
  render_options.synthetic = false;
  render_options.transport_sink = false;
  render_options.width = decoder.width();
  render_options.height = decoder.height();
  render_options.gpu_pattern = false;
  render_options.static_frame = false;
  if (!render_options.output_resolution_set) {
    render_options.output_width = decoder.width();
    render_options.output_height = decoder.height();
  }

  HWND hwnd = CreateBenchmarkWindow(render_options);
  HudOverlay hud;
  hud.Create(hwnd, render_options.hud);
  D3DRenderer renderer(hwnd, render_options);

  std::vector<DecodeFrameStats> stats;
  stats.reserve(static_cast<size_t>(render_options.fps) *
                render_options.duration_seconds);

  const double budget_ms = 1000.0 / static_cast<double>(render_options.fps);
  const auto run_duration =
      std::chrono::seconds(render_options.duration_seconds);
  const auto run_start = Clock::now();
  uint64_t frame_id = 0;

  while (Clock::now() - run_start < run_duration) {
    if (!PumpMessages()) {
      break;
    }

    DecodedVideoFrame decoded;
    double decode_ms = 0.0;
    const auto frame_start = Clock::now();
    const bool have_frame = decoder.ReadFrame(&decoded, &decode_ms);
    if (!have_frame) {
      break;
    }
    if (decoded.pixels.empty()) {
      continue;
    }

    FrameStats render_stats = renderer.Render(frame_id, decoded.pixels, true);
    const auto frame_end = Clock::now();

    DecodeFrameStats frame = {};
    frame.frame_id = frame_id;
    frame.decode_ms = decode_ms;
    frame.upload_ms = render_stats.upload_ms;
    frame.render_ms = render_stats.draw_present_ms;
    frame.total_ms = MsSince(frame_start, frame_end);
    frame.missed_budget = frame.total_ms > budget_ms;
    stats.push_back(frame);

    if (frame_id % 30 == 0) {
      const double elapsed =
          std::chrono::duration<double>(Clock::now() - run_start).count();
      const double running_fps = elapsed > 0.0 ? stats.size() / elapsed : 0.0;
      std::ostringstream hud_text;
      hud_text << "iBridge Studio Receiver Decode\n"
               << render_options.width << "x" << render_options.height << " -> "
               << render_options.output_width << "x" << render_options.output_height
               << "\n"
               << "fps " << std::fixed << std::setprecision(2) << running_fps
               << "  decode " << frame.decode_ms << " ms\n"
               << "upload " << frame.upload_ms << " ms  present "
               << frame.render_ms << " ms\n"
               << "scale " << render_options.scale_mode;
      hud.Update(hud_text.str());
    }

    ++frame_id;
  }

  const auto run_end = Clock::now();
  const double elapsed_sec =
      std::chrono::duration<double>(run_end - run_start).count();
  const double actual_fps = stats.empty() ? 0.0 : stats.size() / elapsed_sec;

  std::vector<double> decode_times;
  std::vector<double> total_times;
  decode_times.reserve(stats.size());
  total_times.reserve(stats.size());
  size_t missed = 0;
  double max_total = 0.0;
  double max_decode = 0.0;
  for (const DecodeFrameStats& frame : stats) {
    decode_times.push_back(frame.decode_ms);
    total_times.push_back(frame.total_ms);
    if (frame.missed_budget) {
      ++missed;
    }
    max_total = std::max(max_total, frame.total_ms);
    max_decode = std::max(max_decode, frame.decode_ms);
  }

  WriteDecodeCsv(options.csv_path, stats);

  std::cout << std::fixed << std::setprecision(3)
            << "iBridge Studio compressed file decode renderer\n"
            << "file=" << options.decode_file << '\n'
            << "decoded_resolution=" << render_options.width << 'x'
            << render_options.height << '\n'
            << "output_resolution=" << render_options.output_width << 'x'
            << render_options.output_height << '\n'
            << "target_fps=" << render_options.fps << '\n'
            << "actual_fps=" << actual_fps << '\n'
            << "frames=" << stats.size() << '\n'
            << "budget_ms=" << budget_ms << '\n'
            << "avg_decode_ms="
            << (decode_times.empty()
                    ? 0.0
                    : std::accumulate(decode_times.begin(), decode_times.end(), 0.0) /
                          decode_times.size())
            << '\n'
            << "p95_decode_ms=" << Percentile(decode_times, 95.0) << '\n'
            << "max_decode_ms=" << max_decode << '\n'
            << "p95_total_ms=" << Percentile(total_times, 95.0) << '\n'
            << "max_total_ms=" << max_total << '\n'
            << "missed_frames=" << missed << '\n'
            << "scale_mode=" << render_options.scale_mode << '\n'
            << "csv=" << (options.csv_path.empty() ? "none" : options.csv_path)
            << '\n';

  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  try {
    const Options options = ParseOptions(argc, argv);
    if (options.transport_sink) {
      return RunTransportSink(options);
    }
    if (!options.decode_file.empty()) {
      return RunDecodeFile(options);
    }
    return RunSynthetic(options);
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << "\n\n";
    PrintUsage();
    return 1;
  }
}
