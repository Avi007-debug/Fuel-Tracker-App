/// LLM service — Qwen2.5 0.5B Instruct on-device inference.
///
/// v2.0 feature. Model is downloaded once (~450 MB GGUF Q4_K_M)
/// and loaded lazily when the chat screen is opened.
class LlmService {
  // TODO: Implement in v2.0 (Phase 7-8)
  //
  // - Model download manager (resumable, progress bar)
  // - GGUF model loading via flutter_llm_inference / ONNX Runtime
  // - Context builder: serialize 30-day rider data
  // - System prompt engineering
  // - Streaming token output
  // - Session memory (multi-turn context)
  // - Model cache + delete flow
}
