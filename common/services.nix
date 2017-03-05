{ services, pkgs, programs, environment, networking, virtualisation, ... }:

{

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGJ3Sf7iBKEpwHjDQj9d6FPYdY97MK5q82G7eioGRsC9eHVlS4Ndj/67SFB1tIXkYLCtXIai1YAH6BVI6prwoycQvb3oBCB8O8W92DbGjbqD8N5pylUPeXxL65ZI2p1ns4kshEVs4li95S3YVs1bS2veP0LP3NMFF2J1w/mPftH60MnbIY3y67sH0jN3ehF2qJBmXa1wddRVzKU9Jx4oMVl5RSpqzFjgKUI7YIz2kLM1fm39cX4HbSqA0U5+hB8nnge4GjriqGYXUg4o55F84EJcecUQaScnwTvwVD5MedyJa8bX3RcUbhT1aq2JCnJV+fjZzETZV/i01YD5AjnuJN azul@thinkpad"
  ];

  services.udev.extraRules = ''
   SUBSYSTEM=="firmware", ACTION="add", ATTR{loading}="-1"
    # set noop scheduler for non-rotating disks
    ACTION=="add|change", KERNEL=="vd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="noop"
    ACTION=="add|change", KERNEL=="sd[b-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="noop"
  '';


  services.fail2ban.enable = true;
  services.logrotate.enable = true;
  services.logrotate.config = ''
    compress
    delaycompress
    hourly
    create
    /var/log/messages /var/log/warn /var/log/faillog /var/log/slim.log {
      missingok
      # we ship our logs to ELK, so we don't really need to keep them locally
      # only reason rsyslog is enabled as it simpliflies the transport to ELK
      rotate 1
      sharedscripts
      postrotate
      /bin/kill -HUP `cat /var/run/rsyslogd.pid 2> /dev/null` 2> /dev/null || true
      endscript
    }
  '';

  services.cron.enable = true;
  services.dbus.enable    = true; # DBus
  services.openssh.enable = true; # OpenSSH
  services.timesyncd.enable = true; # Replace ntpd with timesyncd

  services.rsyslogd.enable = true;
  services.journald.extraConfig = ''
   ForwardToSyslog=yes
  '';

  services.logstash.enable = true;
  services.logstash.plugins = [ pkgs.logstash-contrib ];
  services.logstash.enableWeb = true;
  services.logstash.inputConfig = ''
   pipe {
   command => "${pkgs.systemd}/bin/journalctl -f -o json"
   type => "syslog"
   codec => json {}
  }
  '';

  services.logstash.filterConfig = ''
            if [type] == "syslog" {
                # Keep only relevant systemd fields
                # http://www.freedesktop.org/software/systemd/man/systemd.journal-fields.html
                prune {
                    whitelist_names => [
                        "type", "@timestamp", "@version",
                        "MESSAGE", "PRIORITY", "SYSLOG_FACILITY", "_SYSTEMD_UNIT"
                    ]
                }
    mutate {
                rename => { "_SYSTEMD_UNIT" => "unit" }
          }
            }
  ''; 

  # this is toaster.local
  services.logstash.outputConfig = ''
    elasticsearch {
      hosts => "toaster.tinc-core-vpn:9200"
    }
  '';
}