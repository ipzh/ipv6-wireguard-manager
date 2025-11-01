<?php
/**
 * 简单路由类
 */
class Router {
    private $routes = [];
    private $middleware = [];
    
    /**
     * 添加路由
     */
    public function addRoute($method, $path, $handler) {
        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $path,
            'handler' => $handler
        ];
    }
    
    /**
     * 添加中间件
     */
    public function addMiddleware($path, $middleware) {
        $this->middleware[$path] = $middleware;
    }
    
    /**
     * 处理请求
     */
    public function handleRequest() {
        $method = $_SERVER['REQUEST_METHOD'];
        $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        
        // 移除查询字符串
        $path = strtok($path, '?');
        
        // 规范化路径：移除 /index.php
        if ($path === '/index.php' || strpos($path, '/index.php') === 0) {
            $path = str_replace('/index.php', '', $path);
            if ($path === '') {
                $path = '/';
            }
        }
        
        // 查找匹配的路由
        foreach ($this->routes as $route) {
            if ($route['method'] === $method && $this->matchPath($route['path'], $path)) {
                // 执行中间件
                if (isset($this->middleware[$route['path']])) {
                    $this->executeMiddleware($this->middleware[$route['path']]);
                }
                
                // 执行处理器
                $this->executeHandler($route['handler']);
                return;
            }
        }
        
        // 404错误
        $this->handle404();
    }
    
    /**
     * 匹配路径
     */
    private function matchPath($routePath, $requestPath) {
        // 简单的路径匹配，支持参数
        $routePattern = preg_replace('/\{[^}]+\}/', '([^/]+)', $routePath);
        $routePattern = '#^' . $routePattern . '$#';
        
        return preg_match($routePattern, $requestPath);
    }
    
    /**
     * 执行处理器
     */
    private function executeHandler($handler) {
        if (is_string($handler) && strpos($handler, '@') !== false) {
            list($controller, $method) = explode('@', $handler);
            
            // 使用绝对路径加载控制器（修复相对路径问题）
            $controllerFile = __DIR__ . "/../controllers/{$controller}.php";
            if (file_exists($controllerFile)) {
                require_once $controllerFile;
                
                if (class_exists($controller)) {
                    $controllerInstance = new $controller();
                    if (method_exists($controllerInstance, $method)) {
                        // 提取路由参数
                        $params = $this->extractRouteParams($handler);
                        if (!empty($params)) {
                            $controllerInstance->$method(...$params);
                        } else {
                            $controllerInstance->$method();
                        }
                        return;
                    }
                }
            }
        } elseif (is_callable($handler)) {
            // 支持闭包函数
            $handler();
            return;
        } elseif (is_string($handler) && file_exists(__DIR__ . "/../{$handler}")) {
            // 支持直接包含文件（如api_proxy.php）
            include __DIR__ . "/../{$handler}";
            return;
        }
        
        // 如果处理器无效，返回404
        $this->handle404();
    }
    
    /**
     * 提取路由参数
     */
    private function extractRouteParams($handler) {
        $path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
        $path = strtok($path, '?');
        
        // 规范化路径
        if ($path === '/index.php' || strpos($path, '/index.php') === 0) {
            $path = str_replace('/index.php', '', $path);
            if ($path === '') {
                $path = '/';
            }
        }
        
        // 查找匹配的路由
        foreach ($this->routes as $route) {
            if ($route['handler'] === $handler && $this->matchPath($route['path'], $path)) {
                // 提取参数
                $routePattern = preg_replace('/\{[^}]+\}/', '([^/]+)', $route['path']);
                $routePattern = '#^' . $routePattern . '$#';
                
                if (preg_match($routePattern, $path, $matches)) {
                    array_shift($matches); // 移除完整匹配
                    return $matches;
                }
            }
        }
        
        return [];
    }
    
    /**
     * 执行中间件
     */
    private function executeMiddleware($middleware) {
        if (is_callable($middleware)) {
            $middleware();
        }
    }
    
    /**
     * 处理404错误
     */
    private function handle404() {
        http_response_code(404);
        // 使用绝对路径加载404视图（修复相对路径问题）
        $errorViewPath = __DIR__ . '/../views/errors/404.php';
        if (file_exists($errorViewPath)) {
            include $errorViewPath;
        } else {
            echo '<h1>404 Not Found</h1>';
            echo '<p>The requested page could not be found.</p>';
        }
    }
    
    /**
     * 重定向
     */
    public static function redirect($url) {
        header("Location: $url");
        exit;
    }
    
    /**
     * 获取当前路径
     */
    public static function currentPath() {
        return parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
    }
    
    /**
     * 生成URL
     */
    public static function url($path) {
        $baseUrl = (isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? 'https' : 'http') . 
                   '://' . $_SERVER['HTTP_HOST'];
        return $baseUrl . $path;
    }
}
?>
