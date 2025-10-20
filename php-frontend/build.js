/**
 * 构建脚本 - 支持ESM模块
 * 使用Vite进行现代前端构建
 */

import { defineConfig } from 'vite';

export default defineConfig({
  root: 'public',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      input: {
        main: 'public/index.html',
        login: 'public/login.html'
      }
    }
  },
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true
      }
    }
  },
  resolve: {
    alias: {
      '@': '/public',
      '@services': '/services',
      '@config': '/config'
    }
  }
});
