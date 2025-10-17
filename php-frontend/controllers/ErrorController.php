<?php
/**
 * 错误处理控制器
 */
class ErrorController {
    private $auth;
    
    public function __construct() {
        $this->auth = new Auth();
    }
    
    /**
     * 显示错误页面
     */
    public function showError() {
        $errorTitle = $_SESSION['error_title'] ?? '发生错误';
        $errorMessage = $_SESSION['error_message'] ?? '未知错误';
        
        // 清除会话中的错误信息
        unset($_SESSION['error_title'], $_SESSION['error_message']);
        
        $pageTitle = '错误';
        $showSidebar = $this->auth->isLoggedIn();
        
        include 'views/layout/header.php';
        include 'views/errors/error.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 显示404错误
     */
    public function show404() {
        $pageTitle = '页面未找到';
        $showSidebar = $this->auth->isLoggedIn();
        
        include 'views/layout/header.php';
        include 'views/errors/404.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 显示403错误
     */
    public function show403() {
        $pageTitle = '权限不足';
        $showSidebar = $this->auth->isLoggedIn();
        
        include 'views/layout/header.php';
        include 'views/errors/403.php';
        include 'views/layout/footer.php';
    }
    
    /**
     * 显示500错误
     */
    public function show500() {
        $pageTitle = '服务器错误';
        $showSidebar = $this->auth->isLoggedIn();
        
        include 'views/layout/header.php';
        include 'views/errors/500.php';
        include 'views/layout/footer.php';
    }
}
?>
