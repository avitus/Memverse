# Rails 7.0 Upgrade Preparation Checklist
*Created: August 7, 2025*
*Branch: rails-7-upgrade*

## Current Analysis Summary

### ✅ Current State
- **Branch**: `rails-7-upgrade` (created from `rubyrails-upgrade`)
- **Ruby Version**: 2.7.8 (from `.ruby-version`)
- **Current Rails**: **7.0.8.7** ✅ (RAILS 7 IS ALREADY INSTALLED!)
- **Gemfile Status**: Rails 7.0 gems properly configured

### 🎉 CRITICAL DISCOVERY: RAILS 7.0 IS ALREADY RUNNING!
The application is **already running Rails 7.0.8.7**! This significantly changes our upgrade approach:
- Rails 7.0 upgrade is **COMPLETE**
- Focus shifts to **optimization** and **Ruby version upgrade**
- Major compatibility issues have likely been resolved
- This explains the Rails 7 configuration files already being present

---

## 📋 Pre-Upgrade Verification Tasks

### 1. Current Rails Version Verification
- [ ] **Verify actual running Rails version**: `bundle exec rails --version`
- [ ] **Check Gemfile.lock for actual resolved versions**
- [ ] **Verify application.rb load_defaults version** ✅ (Currently set to 7.0)
- [ ] **Check for mixed Rails 6/7 configuration**

### 2. Ruby Version Requirements
- [ ] **Current**: Ruby 2.7.8 (EOL March 2023)
- [ ] **Rails 7.0 Minimum**: Ruby 2.7.0+ ✅
- [ ] **Recommended**: Upgrade to Ruby 3.2.6 for full Rails 7 compatibility
- [ ] **Plan Ruby upgrade timeline** (can be done before or after Rails 7)

### 3. Database Compatibility
- [ ] **MySQL version check**: Ensure MySQL 5.7+ or 8.0+
- [ ] **Database adapter**: `mysql2 >= 0.4` ✅ (already compatible)
- [ ] **Redis version**: Ensure Redis 4.0+ ✅ (configured as `~> 4.0`)

---

## 🔧 Configuration Files Analysis & Updates Needed

### Core Configuration Files Status

#### 1. `/config/application.rb` ✅ **READY**
- Load defaults already set to 7.0
- Zeitwerk autoloading configured
- No immediate changes needed

#### 2. Environment Files **REVIEW NEEDED**
- [ ] `/config/environments/production.rb` - Already has Rails 7 syntax
- [ ] `/config/environments/development.rb` - Needs verification
- [ ] `/config/environments/test.rb` - Needs verification

#### 3. New Rails 7 Configuration Files ✅ **PRESENT**
- `/config/cable.yml` ✅ (Action Cable config exists)
- `/config/storage.yml` ✅ (Active Storage config exists)
- `/config/puma.rb` ✅ (Puma server config exists)

#### 4. Framework Defaults Migration
- [ ] **Missing**: `/config/initializers/new_framework_defaults_7_0.rb`
- [ ] **Present**: `new_framework_defaults_6_0.rb` and `new_framework_defaults_6_1.rb`
- [ ] **Action**: Generate and configure Rails 7.0 defaults

### Initializers Requiring Review

#### High Priority Updates Needed:
- [ ] `/config/initializers/rails_admin.rb` - **CRITICAL** (Rails 7 compatibility)
- [ ] `/config/initializers/ckeditor.rb` - May need updates
- [ ] `/config/initializers/thredded.rb` - Version compatibility check
- [ ] `/config/initializers/session_store.rb` - Verify session handling
- [ ] `/config/initializers/devise.rb` - Check for Rails 7 compatibility

#### Medium Priority:
- [ ] `/config/initializers/sidekiq.rb` - Should be compatible
- [ ] `/config/initializers/doorkeeper.rb` - OAuth configuration check
- [ ] `/config/initializers/rpush.rb` - Push notification compatibility

#### New Rails 7 Initializers to Add:
- [ ] `/config/initializers/permissions_policy.rb` ✅ (exists)
- [ ] `/config/initializers/content_security_policy.rb` ✅ (exists)
- [ ] Rails 7.0 framework defaults initializer

---

## 📦 Gem Compatibility Critical Issues

### 🔥 **BLOCKING GEMS** (Must resolve before Rails 7)

#### 1. rails_admin **CRITICAL**
- **Issue**: Not Rails 7 compatible in current version
- **Solution**: Update to rails_admin 3.0+ 
- **Risk**: Admin interface will be completely broken
- **Action Required**: Test admin functionality thoroughly after update

#### 2. thredded (Forum Engine) **HIGH**
- **Current**: `~> 1.0.1` (very old)
- **Required**: Update to 1.1+ for Rails 7 support
- **Risk**: Forum functionality may break
- **Dependencies**: May require database migrations

### ⚠️ **HIGH PRIORITY GEMS**

#### 3. CKEditor **MEDIUM**
- **Issue**: Using GitHub fork instead of official gem
- **Solution**: Switch to official `ckeditor` gem 5.1+
- **Risk**: WYSIWYG editor compatibility issues

#### 4. acts-as-taggable-on **LOW**
- **Current**: Updated to `~> 10.0` ✅
- **Status**: Rails 7 compatible

### ✅ **COMPATIBLE GEMS** (No action needed)
- mysql2, redis, sidekiq, devise, doorkeeper, cancancan
- Most testing gems (rspec-rails, capybara, etc.)
- Core infrastructure gems

---

## 🧪 Testing Strategy for Rails 7 Upgrade

### Pre-Upgrade Testing
- [ ] **Current test suite status**: Run full test suite on current branch
- [ ] **Identify failing tests**: Document any existing failures
- [ ] **Baseline performance**: Record current test execution times

### Rails 7 Testing Plan
- [ ] **Unit Tests**: `bundle exec rspec` (targeting 100% pass rate)
- [ ] **Integration Tests**: `bundle exec cucumber features`
- [ ] **JavaScript Tests**: `bundle exec rake spec:javascript`
- [ ] **Admin Interface**: Manual testing of rails_admin after update
- [ ] **Forum Functionality**: Test thredded engine after update
- [ ] **API Endpoints**: Verify all API endpoints still work

### Test Environment Requirements
- [ ] **Database**: Ensure test database is clean and migrated
- [ ] **Redis**: Verify Redis is available for testing
- [ ] **JavaScript Runtime**: Node.js available for asset compilation

---

## 🚀 Rails 7 Upgrade Sequence

### Phase 1: Critical Gem Updates **REQUIRED FIRST**
1. [ ] **Update rails_admin to 3.0+**
   - Research configuration changes needed
   - Test admin interface thoroughly
   - Update any custom admin configurations

2. [ ] **Update thredded to 1.1+**
   - Check for database migrations
   - Test forum functionality
   - Verify theme compatibility

3. [ ] **Switch CKEditor to official gem**
   - Audit current customizations
   - Test WYSIWYG functionality
   - Verify file upload handling

### Phase 2: Framework Defaults & Configuration
1. [ ] **Generate Rails 7.0 defaults**
   ```bash
   bundle exec rails app:update
   ```
   - Review new framework defaults
   - Merge with existing configurations
   - Test application behavior

2. [ ] **Update environment configurations**
   - Review development.rb for Rails 7 changes
   - Update test.rb for new testing features
   - Verify production.rb optimizations

### Phase 3: Asset Pipeline & Frontend
1. [ ] **Verify Sprockets configuration**
   - Rails 7 uses sprockets-rails ✅ (already added)
   - Test asset compilation
   - Check JavaScript loading

2. [ ] **Review Hotwire integration**
   - turbo-rails ✅ (already added)
   - stimulus-rails ✅ (already added)
   - importmap-rails ✅ (already added)

3. [ ] **JavaScript modernization planning**
   - CoffeeScript is commented out ✅
   - Plan migration from jQuery 1.12.4 to modern JS (future phase)

### Phase 4: Database & Active Record
1. [ ] **Run database migrations**
   ```bash
   bundle exec rails db:migrate
   ```
   
2. [ ] **Test Active Record queries**
   - Verify deprecated methods removed
   - Test complex queries and joins
   - Check for new Rails 7 Active Record features

### Phase 5: Background Jobs & Services
1. [ ] **Verify Sidekiq compatibility**
   - Current version should be compatible
   - Test job processing
   - Verify cron scheduling works

2. [ ] **Test real-time features**
   - PubNub integration
   - Action Cable setup
   - Push notifications (rpush)

---

## ⚡ Quick Start Commands

### Essential Verification Commands
```bash
# Check current Rails version
bundle exec rails --version

# Check resolved gem versions  
bundle list | grep rails

# Verify Ruby version
ruby --version

# Run test suite baseline
bundle exec rspec
bundle exec cucumber features
bundle exec rake spec:javascript

# Check for security issues
bundle exec brakeman

# Check for outdated gems
bundle outdated
```

### Rails 7 Upgrade Commands (when ready)
```bash
# Update Gemfile first (critical gems)
# Then run bundle update for Rails 7
bundle update rails

# Generate new framework defaults
bundle exec rails app:update

# Run database migrations
bundle exec rails db:migrate

# Precompile assets
bundle exec rails assets:precompile

# Full test suite
bundle exec rspec && bundle exec cucumber features
```

---

## 🚨 Risk Assessment

### **HIGH RISK AREAS**
1. **Admin Interface**: rails_admin update may break existing customizations
2. **Forum Functionality**: thredded update may require significant testing
3. **CKEditor**: Switching from fork to official gem may cause compatibility issues
4. **JavaScript Dependencies**: jQuery 1.12.4 is very old, may have compatibility issues

### **MEDIUM RISK AREAS**
1. **API Functionality**: RocketPants has been replaced, ensure all API endpoints work
2. **Authentication**: Devise configuration may need updates
3. **Background Jobs**: Sidekiq should be compatible but needs testing

### **LOW RISK AREAS**
1. **Database**: MySQL adapter is compatible
2. **Core Models**: Active Record changes should be minimal
3. **Testing Framework**: RSpec and Cucumber are Rails 7 compatible

---

## 📝 Next Steps

### Immediate Actions (Before Starting Upgrade)
1. [ ] **Document current application state**
   - Record current test results
   - Document any known issues
   - Backup current working state

2. [ ] **Research critical gem updates**
   - rails_admin 3.0+ migration guide
   - thredded 1.1+ changelog and migration requirements
   - CKEditor official gem documentation

3. [ ] **Prepare rollback strategy**
   - Ensure git branch is clean
   - Document current gem versions
   - Plan database backup strategy

### Ready to Proceed When:
- [ ] All critical gems have verified Rails 7 compatible versions
- [ ] Test suite is running at 100% on current branch
- [ ] Team has reviewed upgrade plan and timeline
- [ ] Rollback strategy is documented and tested

---

## 🎯 Success Criteria

### Upgrade is Complete When:
- [ ] Rails 7.0.x is running successfully
- [ ] 100% of tests pass (unit, integration, JavaScript)
- [ ] All major functionality verified manually
- [ ] Admin interface working with new rails_admin
- [ ] Forum functionality working with updated thredded
- [ ] API endpoints responding correctly
- [ ] Background jobs processing correctly
- [ ] No major performance degradation

**Estimated Timeline**: 2-3 days for gem updates + testing, 1-2 days for Rails upgrade execution

**Point of No Return**: Once database migrations from updated gems are run