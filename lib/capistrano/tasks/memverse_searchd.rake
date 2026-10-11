# Sphinx searchd lifecycle for hosts where searchd runs under systemd (martial-eagle).
#
# Thinking Sphinx's `ts:start` daemonises searchd without closing the inherited stdout/stderr, so when
# Capistrano runs it over SSH the remote command never reaches EOF and the deploy hangs after
# "Started searchd successfully". Restarting the systemd unit sidesteps that and also means searchd
# comes back after a reboot. The sudoers file in deployment_scripts/migration/martial-eagle allows
# exactly these systemctl verbs.
namespace :memverse do
  namespace :searchd do
    desc "Regenerate the Sphinx config, stop any searchd started outside systemd, restart the memverse-searchd unit"
    task :restart do
      on roles(:app) do
        within current_path do
          with rails_env: fetch(:rails_env) do
            execute :rake, 'ts:configure'
            # Kills a searchd that Thinking Sphinx started detached (e.g. from an older deploy); harmless otherwise.
            execute :rake, 'ts:stop', raise_on_non_zero_exit: false
          end
        end
        execute :sudo, 'systemctl restart memverse-searchd'
        execute :sudo, 'systemctl status memverse-searchd --no-pager', raise_on_non_zero_exit: false
      end
    end
  end
end
