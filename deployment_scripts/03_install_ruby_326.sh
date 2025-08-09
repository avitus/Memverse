#!/bin/bash
# Install Ruby 3.2.6 for Memverse Rails 7 upgrade
# Supports both RVM and rbenv

set -e

# Configuration
RUBY_VERSION="3.2.6"
APP_DIR="/var/www/memverse"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Ruby 3.2.6 Installation Script"
echo "=========================================="
echo ""

# Detect Ruby version manager
if command -v rvm &> /dev/null; then
    RUBY_MANAGER="rvm"
    echo "Detected Ruby Version Manager: RVM"
elif command -v rbenv &> /dev/null; then
    RUBY_MANAGER="rbenv"
    echo "Detected Ruby Version Manager: rbenv"
else
    echo -e "${RED}No Ruby version manager detected!${NC}"
    echo "Please install RVM or rbenv first."
    echo ""
    echo "To install RVM:"
    echo "curl -sSL https://get.rvm.io | bash"
    echo ""
    echo "To install rbenv:"
    echo "git clone https://github.com/rbenv/rbenv.git ~/.rbenv"
    exit 1
fi
echo ""

# Function to check if command succeeded
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1 failed!${NC}"
        exit 1
    fi
}

# Install dependencies
echo "1. Installing Ruby build dependencies..."
echo "This may require sudo password..."

# For Ubuntu/Debian
if [ -f /etc/debian_version ]; then
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        libssl-dev \
        libreadline-dev \
        zlib1g-dev \
        libxml2-dev \
        libxslt-dev \
        libffi-dev \
        libyaml-dev \
        libgdbm-dev \
        libncurses5-dev \
        automake \
        libtool \
        bison \
        pkg-config \
        libmysqlclient-dev \
        libpq-dev \
        imagemagick \
        libmagickwand-dev
    check_status "Dependency installation"

# For CentOS/RHEL/Fedora
elif [ -f /etc/redhat-release ]; then
    sudo yum groupinstall -y "Development Tools"
    sudo yum install -y \
        openssl-devel \
        readline-devel \
        zlib-devel \
        libxml2-devel \
        libxslt-devel \
        libffi-devel \
        libyaml-devel \
        gdbm-devel \
        ncurses-devel \
        automake \
        libtool \
        bison \
        mysql-devel \
        postgresql-devel \
        ImageMagick \
        ImageMagick-devel
    check_status "Dependency installation"
else
    echo -e "${YELLOW}Unknown OS. Please install build dependencies manually.${NC}"
fi
echo ""

# Install Ruby 3.2.6
echo "2. Installing Ruby $RUBY_VERSION..."

if [ "$RUBY_MANAGER" = "rvm" ]; then
    echo "Using RVM to install Ruby $RUBY_VERSION..."
    
    # Update RVM
    echo "Updating RVM..."
    rvm get stable
    check_status "RVM update"
    
    # Install Ruby
    echo "Installing Ruby $RUBY_VERSION (this may take several minutes)..."
    rvm install $RUBY_VERSION
    check_status "Ruby installation"
    
    # Set as default for the project
    cd "$APP_DIR" 2>/dev/null || true
    rvm use $RUBY_VERSION
    rvm --ruby-version use $RUBY_VERSION
    check_status "Ruby version set"
    
elif [ "$RUBY_MANAGER" = "rbenv" ]; then
    echo "Using rbenv to install Ruby $RUBY_VERSION..."
    
    # Update rbenv
    echo "Updating rbenv..."
    cd ~/.rbenv && git pull
    check_status "rbenv update"
    
    # Update ruby-build
    echo "Updating ruby-build..."
    if [ -d ~/.rbenv/plugins/ruby-build ]; then
        cd ~/.rbenv/plugins/ruby-build && git pull
    else
        git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
    fi
    check_status "ruby-build update"
    
    # Install Ruby
    echo "Installing Ruby $RUBY_VERSION (this may take several minutes)..."
    rbenv install $RUBY_VERSION
    check_status "Ruby installation"
    
    # Set for the project
    cd "$APP_DIR" 2>/dev/null || true
    rbenv local $RUBY_VERSION
    check_status "Ruby version set"
fi
echo ""

# Verify installation
echo "3. Verifying Ruby installation..."
ruby -v
if ruby -v | grep -q "$RUBY_VERSION"; then
    echo -e "${GREEN}Ruby $RUBY_VERSION installed successfully!${NC}"
else
    echo -e "${RED}Ruby version mismatch!${NC}"
    exit 1
fi
echo ""

# Install bundler
echo "4. Installing Bundler..."
gem install bundler -v '~> 2.0'
check_status "Bundler installation"
echo ""

# Optimize Ruby 3.2 for production
echo "5. Optimizing Ruby 3.2 settings..."

# Create Ruby optimization script
cat > /tmp/optimize_ruby32.sh << 'EOF'
# Ruby 3.2 optimizations for production

# Enable YJIT (Yet Another JIT) for better performance
export RUBY_YJIT_ENABLE=1

# Garbage collection tuning for web applications
export RUBY_GC_HEAP_INIT_SLOTS=1000000
export RUBY_GC_HEAP_FREE_SLOTS=500000
export RUBY_GC_HEAP_GROWTH_FACTOR=1.1
export RUBY_GC_HEAP_GROWTH_MAX_SLOTS=10000000
export RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=2.0
export RUBY_GC_MALLOC_LIMIT=90000000
export RUBY_GC_MALLOC_LIMIT_MAX=360000000
export RUBY_GC_MALLOC_LIMIT_GROWTH_FACTOR=1.4
export RUBY_GC_OLDMALLOC_LIMIT=90000000
export RUBY_GC_OLDMALLOC_LIMIT_MAX=360000000
export RUBY_GC_OLDMALLOC_LIMIT_GROWTH_FACTOR=1.2
EOF

echo "Created Ruby optimization settings in /tmp/optimize_ruby32.sh"
echo -e "${YELLOW}Add these to your application's environment or systemd service files${NC}"
echo ""

# Install Rails 7 specific gems globally
echo "6. Installing Rails 7 development tools..."
gem install rails -v '~> 7.0.0'
gem install foreman
gem install solargraph  # For better IDE support
check_status "Rails tools installation"
echo ""

# Prepare for gem native extensions
echo "7. Preparing for native gem compilation..."

# Rebuild all native extensions with new Ruby
echo "This ensures all C extensions are compiled for Ruby 3.2.6..."
gem pristine --all
check_status "Native extension rebuild"
echo ""

# Create migration helper script
echo "8. Creating gem migration helper..."
cat > "$APP_DIR/migrate_gems_to_ruby32.sh" << 'EOF'
#!/bin/bash
# Helper script to migrate gems to Ruby 3.2.6

set -e

echo "Migrating gems to Ruby 3.2.6..."

# Remove old Gemfile.lock
if [ -f Gemfile.lock ]; then
    mv Gemfile.lock Gemfile.lock.ruby27_backup
    echo "Backed up old Gemfile.lock"
fi

# Clean vendor/bundle if it exists
if [ -d vendor/bundle ]; then
    echo "Cleaning vendor/bundle..."
    rm -rf vendor/bundle
fi

# Install all gems fresh
echo "Installing all gems for Ruby 3.2.6..."
bundle install --jobs=4

# List gems with native extensions
echo ""
echo "Gems with native extensions:"
bundle exec ruby -e "
  Gem::Specification.each do |spec|
    if spec.extensions.any?
      puts \"#{spec.name} (#{spec.version})\"
    end
  end
"

echo ""
echo "Gem migration completed!"
EOF

chmod +x "$APP_DIR/migrate_gems_to_ruby32.sh"
check_status "Migration helper creation"
echo ""

# Summary and next steps
echo "=========================================="
echo -e "${GREEN}Ruby 3.2.6 Installation Complete!${NC}"
echo "=========================================="
echo ""
echo "Ruby version: $(ruby -v)"
echo "Gem version: $(gem -v)"
echo "Bundler version: $(bundle -v)"
echo ""
echo "Next steps:"
echo "1. cd $APP_DIR"
echo "2. Run: ./migrate_gems_to_ruby32.sh"
echo "3. Test your application with Ruby 3.2.6"
echo "4. Run: bundle exec rspec (to verify tests pass)"
echo ""
echo "Ruby 3.2 Performance Tips:"
echo "- YJIT is available for 30-40% performance improvement"
echo "- Use the optimization settings in /tmp/optimize_ruby32.sh"
echo "- Monitor memory usage as it may differ from Ruby 2.7"
echo ""
echo -e "${YELLOW}Note: Some gems may need updates for Ruby 3.2 compatibility${NC}"
echo -e "${YELLOW}Check Gemfile for any version constraints that need updating${NC}"