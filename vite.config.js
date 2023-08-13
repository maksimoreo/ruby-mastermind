import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    headers: {
      // COOP & COEP are required for `SharedArrayBuffer` and `Atomics` but are not required to run WASM
      // Note: these headers only affect local dev server
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cross-Origin-Opener-Policy': 'same-origin',
    },
  },
})
