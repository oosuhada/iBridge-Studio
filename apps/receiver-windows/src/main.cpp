#include <windows.h>
#include <d3d11.h>
#include <d3dcompiler.h>
#include <wrl/client.h>

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
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
  int fps = 60;
  int duration_seconds = 60;
  bool synthetic = false;
  bool fullscreen = false;
  bool vsync = true;
  bool static_frame = false;
  std::string csv_path;
};

struct FrameStats {
  uint64_t frame_id = 0;
  double fill_ms = 0.0;
  double upload_ms = 0.0;
  double draw_present_ms = 0.0;
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
         "[--static-frame]\n";
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

  if (!options.synthetic) {
    throw std::runtime_error("only --synthetic mode exists in the Plan A spike");
  }
  if (options.fps <= 0 || options.duration_seconds <= 0) {
    throw std::runtime_error("--fps and --duration must be positive");
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
  RECT rect = {0, 0, options.width, options.height};

  int x = CW_USEDEFAULT;
  int y = CW_USEDEFAULT;
  int window_width = options.width;
  int window_height = options.height;

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

  HWND hwnd = CreateWindowExW(0, class_name, L"iBridge Plan A Synthetic 5K60",
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

  FrameStats Render(uint64_t frame_id, const std::vector<uint32_t>& pixels) {
    FrameStats stats;
    stats.frame_id = frame_id;

    auto upload_start = Clock::now();
    context_->UpdateSubresource(frame_texture_.Get(), 0, nullptr, pixels.data(),
                                static_cast<UINT>(options_.width * sizeof(uint32_t)),
                                0);
    auto upload_end = Clock::now();
    stats.upload_ms = MsSince(upload_start, upload_end);

    auto draw_start = Clock::now();
    const float clear_color[4] = {0.0f, 0.0f, 0.0f, 1.0f};
    context_->ClearRenderTargetView(render_target_.Get(), clear_color);
    context_->OMSetRenderTargets(1, render_target_.GetAddressOf(), nullptr);
    context_->RSSetViewports(1, &viewport_);
    context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    context_->VSSetShader(vertex_shader_.Get(), nullptr, 0);
    context_->PSSetShader(pixel_shader_.Get(), nullptr, 0);
    context_->PSSetSamplers(0, 1, sampler_.GetAddressOf());
    context_->PSSetShaderResources(0, 1, frame_srv_.GetAddressOf());
    context_->Draw(3, 0);
    CheckHR(swap_chain_->Present(options_.vsync ? 1 : 0, 0), "Present");
    auto draw_end = Clock::now();
    stats.draw_present_ms = MsSince(draw_start, draw_end);
    return stats;
  }

 private:
  void CreateDeviceAndSwapChain(HWND hwnd) {
    DXGI_SWAP_CHAIN_DESC desc = {};
    desc.BufferDesc.Width = static_cast<UINT>(options_.width);
    desc.BufferDesc.Height = static_cast<UINT>(options_.height);
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
    viewport_.Width = static_cast<float>(options_.width);
    viewport_.Height = static_cast<float>(options_.height);
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
)";

    ComPtr<ID3DBlob> vs = CompileShader(hlsl, "vs_main", "vs_5_0");
    ComPtr<ID3DBlob> ps = CompileShader(hlsl, "ps_main", "ps_5_0");
    CheckHR(device_->CreateVertexShader(vs->GetBufferPointer(),
                                        vs->GetBufferSize(), nullptr,
                                        &vertex_shader_),
            "CreateVertexShader");
    CheckHR(device_->CreatePixelShader(ps->GetBufferPointer(),
                                       ps->GetBufferSize(), nullptr,
                                       &pixel_shader_),
            "CreatePixelShader");
  }

  void CreateSampler() {
    D3D11_SAMPLER_DESC desc = {};
    desc.Filter = D3D11_FILTER_MIN_MAG_MIP_POINT;
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

int RunSynthetic(const Options& options) {
  HWND hwnd = CreateBenchmarkWindow(options);
  D3DRenderer renderer(hwnd, options);

  std::vector<uint32_t> pixels(static_cast<size_t>(options.width) * options.height);
  std::vector<FrameStats> stats;
  stats.reserve(static_cast<size_t>(options.fps) * options.duration_seconds);

  const double budget_ms = 1000.0 / static_cast<double>(options.fps);
  const auto run_duration = std::chrono::seconds(options.duration_seconds);
  const auto frame_duration =
      std::chrono::duration<double>(1.0 / static_cast<double>(options.fps));

  FillSyntheticFrame(&pixels, options.width, options.height, 0);

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

    if (!options.static_frame || frame_id == 0) {
      const auto fill_start = Clock::now();
      FillSyntheticFrame(&pixels, options.width, options.height, frame_id);
      const auto fill_end = Clock::now();
      frame.fill_ms = MsSince(fill_start, fill_end);
    }

    FrameStats render_stats = renderer.Render(frame_id, pixels);
    frame.upload_ms = render_stats.upload_ms;
    frame.draw_present_ms = render_stats.draw_present_ms;

    const auto frame_end = Clock::now();
    frame.total_ms = MsSince(frame_start, frame_end);
    frame.missed_budget = frame.total_ms > budget_ms;
    stats.push_back(frame);

    ++frame_id;
    next_frame_time += std::chrono::duration_cast<Clock::duration>(frame_duration);
    if (!options.vsync) {
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
            << "iBridge Plan A synthetic renderer\n"
            << "resolution=" << options.width << 'x' << options.height << '\n'
            << "target_fps=" << options.fps << '\n'
            << "actual_fps=" << actual_fps << '\n'
            << "frames=" << stats.size() << '\n'
            << "budget_ms=" << budget_ms << '\n'
            << "p95_total_ms=" << Percentile(totals, 95.0) << '\n'
            << "max_total_ms=" << max_total << '\n'
            << "missed_frames=" << missed << '\n'
            << "vsync=" << (options.vsync ? "on" : "off") << '\n'
            << "static_frame=" << (options.static_frame ? "on" : "off") << '\n';

  return 0;
}

}  // namespace

int main(int argc, char** argv) {
  try {
    const Options options = ParseOptions(argc, argv);
    return RunSynthetic(options);
  } catch (const std::exception& error) {
    std::cerr << "error: " << error.what() << "\n\n";
    PrintUsage();
    return 1;
  }
}
