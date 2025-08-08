# Ruby 3.2.6 Setup Instructions

Ruby 3.2.6 has been successfully installed on your system. To complete the setup and run bundle install, please run these commands in your terminal:

## Step 1: Open a new terminal window
This ensures a fresh shell environment.

## Step 2: Navigate to the project directory
```bash
cd /Users/avitus/Projects/Memverse
```

## Step 3: Ensure RVM is loaded
```bash
source ~/.rvm/scripts/rvm
```

## Step 4: Switch to Ruby 3.2.6
```bash
rvm use 3.2.6
```

## Step 5: Verify Ruby version
```bash
ruby -v
# Should output: ruby 3.2.6 (2024-10-30 revision 63aeb018eb) [arm64-darwin24]
```

## Step 6: Install bundler if needed
```bash
gem install bundler
```

## Step 7: Run bundle install
```bash
bundle install
```

## Troubleshooting

### If you get "Your Ruby version is 2.7.8, but your Gemfile specified 3.2.6"
This means RVM isn't properly switching Ruby versions. Try:

1. Close all terminal windows
2. Open a fresh terminal
3. Run: `rvm get stable --auto-dotfiles`
4. Then repeat steps 2-7 above

### If you get OpenSSL errors during bundle install
Some gems might have issues with OpenSSL 3.x. The Ruby installation was already configured to use OpenSSL 1.1, but if you encounter issues:

```bash
bundle config build.eventmachine --with-openssl-dir=$(brew --prefix openssl@1.1)
bundle config build.puma --with-openssl-dir=$(brew --prefix openssl@1.1)
bundle install
```

## What's been done already:

✅ Ruby 3.2.6 installed with OpenSSL 1.1
✅ All project files updated to use Ruby 3.2.6
✅ Gemfile updated with Ruby 3.2.6 compatible versions
✅ Paperclip migrated to Active Storage
✅ All Fixnum references updated to Integer
✅ CI/CD configuration updated

## Next Steps After Bundle Install:

1. Run the test suite:
   ```bash
   bundle exec rspec
   bundle exec cucumber
   npm run test:run
   ```

2. If all tests pass, the Ruby 3.2.6 upgrade is complete!

3. Deploy to staging first to verify everything works in a production-like environment

## Note:
The RVM PATH warning can be safely ignored if Ruby commands are working correctly. To permanently fix it, you may need to update your shell configuration (.bashrc, .zshrc, etc.).