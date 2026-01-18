#!/bin/bash
echo "开始配置高质量桌面环境..."

# 更新系统
sudo apt update
sudo apt upgrade -y

# 安装 XFCE 桌面环境（最小化安装，避免臃肿）
sudo apt install -y --no-install-recommends \
    xubuntu-core \
    xfce4-terminal \
    xfce4-screenshooter \
    xfce4-taskmanager \
    xfce4-appfinder \
    mousepad \
    ristretto \
    thunar-archive-plugin \
    xarchiver

# 安装必要的工具和字体
sudo apt install -y \
    xrdp \
    xorgxrdp \
    firefox \
    git \
    curl \
    wget \
    vim \
    fonts-noto-cjk \
    fonts-wqy-microhei \
    gnome-icon-theme

# 配置 XRDP
echo "配置 XRDP..."
sudo systemctl stop xrdp
sudo systemctl stop xrdp-sesman

# 备份原始配置
sudo cp /etc/xrdp/xrdp.ini /etc/xrdp/xrdp.ini.bak
sudo cp /etc/xrdp/sesman.ini /etc/xrdp/sesman.ini.bak

# 优化 XRDP 配置
sudo tee /etc/xrdp/xrdp.ini > /dev/null << 'EOF'
[globals]
bitmap_cache=yes
bitmap_compression=yes
port=3389
crypt_level=low
channel_code=1
max_bpp=32
use_compression=yes

[xrdp1]
name=XFCE-Desktop
lib=libxup.so
username=ask
password=ask
ip=127.0.0.1
port=-1
EOF

# 优化 sesman 配置
sudo tee /etc/xrdp/sesman.ini > /dev/null << 'EOF'
[Globals]
ListenAddress=127.0.0.1
ListenPort=3350
EnableUserWindowManager=true
UserWindowManager=startxfce4
DefaultWindowManager=startxfce4

[Security]
AllowRootLogin=true
MaxLoginRetry=4
TerminalServerUsers=tsusers
TerminalServerAdmins=tsadmins
AlwaysGroupCheck=false

[Sessions]
X11DisplayOffset=10
MaxSessions=10
KillDisconnected=false
IdleTimeLimit=0
DisconnectedTimeLimit=0

[Logging]
LogFile=xrdp-sesman.log
LogLevel=INFO
EnableSyslog=true
SyslogLevel=INFO
EOF

# 设置 XFCE 为默认会话
echo "startxfce4" > ~/.xsession

# 创建启动脚本
sudo tee /usr/local/bin/start-desktop > /dev/null << 'EOF'
#!/bin/bash
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en
export LC_ALL=en_US.UTF-8
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
export XDG_CONFIG_DIRS=/etc/xdg/xdg-xubuntu:/etc/xdg:/usr/share/xubuntu:/etc/xdg
export XDG_DATA_DIRS=/usr/share/xubuntu:/usr/local/share:/usr/share:/var/lib/snapd/desktop
startxfce4
EOF

sudo chmod +x /usr/local/bin/start-desktop

# 配置权限
sudo chown -R $(whoami):$(whoami) ~/.xsession
chmod +x ~/.xsession

# 优化系统设置
echo "优化系统性能..."

# 创建交换文件（如果内存不足）
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 禁用不必要的服务释放内存
sudo systemctl disable --now bluetooth
sudo systemctl disable --now cups
sudo systemctl disable --now cups-browsed

# 配置 XFCE 优化
mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml
cat > ~/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string" value="/usr/share/backgrounds/xfce/xfce-blue.jpg"/>
        <property name="image-style" type="int" value="5"/>
      </property>
    </property>
  </property>
</channel>
EOF

# 启动 XRDP 服务
echo "启动服务..."
sudo systemctl enable xrdp
sudo systemctl start xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl start xrdp-sesman

# 显示连接信息
echo ""
echo "=============================================="
echo "🎉 桌面环境配置完成！"
echo ""
echo "连接信息："
echo "1. 在 VS Code 中："
echo "   - 点击左侧 '端口' 图标"
echo "   - 找到端口 3389"
echo "   - 点击 '地球图标' → '在浏览器中预览'"
echo ""
echo "2. 使用微软远程桌面："
echo "   计算机: ${CODESPACE_NAME}-3389.preview.app.github.dev"
echo "   用户名: $(whoami)"
echo "   密码: (不需要)"
echo ""
echo "3. 直接访问："
echo "   https://${CODESPACE_NAME}-3389.preview.app.github.dev"
echo "=============================================="
