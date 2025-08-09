# Production Server Upgrade

## Ruby 3.2.6 Installation Instructions

### Prerequisites
- Ensure OpenSSL 1.1 is installed (Ruby 3.2.6 is incompatible with OpenSSL 3.x)
- RVM should be installed and configured

### Installation Steps

1. **Check OpenSSL version:**
   ```bash
   openssl version
   # If OpenSSL 3.x, you need OpenSSL 1.1 installed alongside
   ```

2. **Find OpenSSL 1.1 path:**
   ```bash
   # For Homebrew (macOS):
   brew --prefix openssl@1.1
   
   # For Linux (common paths):
   # /usr/local/openssl-1.1
   # /opt/openssl-1.1
   ```

3. **Clean RVM cache (if previous attempts failed):**
   ```bash
   rvm cleanup sources
   ```

4. **Install Ruby 3.2.6 with OpenSSL 1.1:**
   ```bash
   rvm install ruby-3.2.6 --with-openssl-dir=/path/to/openssl@1.1
   ```
   Replace `/path/to/openssl@1.1` with your actual OpenSSL 1.1 path.

5. **Verify installation:**
   ```bash
   rvm use ruby-3.2.6
   ruby --version
   # Should output: ruby 3.2.6 (2024-10-30 revision 63aeb018eb)
   ```

### Linux-Specific Notes

On Linux servers, you may need to install OpenSSL 1.1 development packages first:

- **Ubuntu/Debian:**
  ```bash
  apt-get install libssl1.1 libssl-dev
  ```

- **RHEL/CentOS:**
  ```bash
  yum install openssl11 openssl11-devel
  ```

### Troubleshooting

**Issue:** Compilation fails with OpenSSL-related errors
**Solution:** Ensure you're pointing to OpenSSL 1.1, not OpenSSL 3.x

**Issue:** "ruby-3.2.6 - #compiling" fails with make errors
**Solution:** Check `/Users/[username]/.rvm/log/[timestamp]_ruby-3.2.6/make.log` for specific errors, likely OpenSSL version mismatch