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
        # Fail the deploy unless the unit is active and searchd is accepting connections (it precaches
        # the indices first, so allow up to 30 s). Neither check needs sudo.
        execute :systemctl, 'is-active', '--quiet', 'memverse-searchd'
        execute :bash, '-c', %q('for i in $(seq 1 30); do ss -tln | grep -q ":9312 " && exit 0; sleep 1; done; echo "searchd not listening on 9312 after 30s" >&2; exit 1')
        execute :sudo, 'systemctl status memverse-searchd --no-pager'
      end
    end
  end
end
