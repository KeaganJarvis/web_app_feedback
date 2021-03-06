apt_update
package "git-core"
package "nginx"
# package "make"
# package "gcc"
# package "perl"
# package "cpanminus"
package "sqlite3"
package "python3"
package "python3-pip"
package "python3-virtualenv"

git "/web_app_feedback/" do
    repository "https://github.com/KeaganJarvis/web_app_feedback.git"
    reference "main"
    action :sync
end

# get nginx setup correctly before doing certbot stuff so that it auto fixes /etc/nginx/sites-enabled/application
# this must come after installing nginx
file "/etc/nginx/sites-available/application" do
    owner 'root'
    group 'root'
    mode 0644
    content ::File.open("/web_app_feedback/nginx/application").read
    action :create
end

link "/etc/nginx/sites-enabled/application" do
    to "/etc/nginx/sites-available/application"
end

link "/etc/nginx/sites-enabled/default" do
    action :delete
end

file "/etc/nginx/sites-available/default" do
    action :delete
end


systemd_unit 'nginx.service' do
    action :restart
end

# certbot is recommended to use the snap install for 20.04
# attempts at using chef's `snap_package` was giving failing therefore calling command directly
execute "Install certbot" do
    command "snap install certbot --classic"
end

# run this command to get https: certbot --nginx -d web-app-feedback.space -d www.web-app-feedback.space --non-interactive --agree-tos -m webmaster@example.com
# Note this command was interactive on first run through (added on --non-interactive --agree-tos -m webmaster@example.com).
# Second note this requires the @.web-app-feedback.space domain A record to point to the public IP of the instance

# create /etc/letsencrypt/renewal-hooks/post/ that restarts nginx

# note avoided using the Python cookbooks, like Poise-python because they seem unmaintained
execute "Create web_app_py_virtual_env" do
    command "virtualenv -p python3 /web_app_venv/"
end

execute "Install python libraries" do
    command "/web_app_venv/bin/pip install -r /web_app_feedback/web_app/requirements.txt"
end


# necessary for uwsgi logging:
directory '/var/log/uwsgi' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
end

# install the uswgi service files in systemd,
systemd_unit 'uwsgi-application.service' do
    content({ Unit: {
              Description: 'Feedback Web application UWSGI Workers',
              After: 'network.target nginx.service',
            },
            Service: {
              Type: 'notify',
              ExecStart: '/web_app_venv/bin/uwsgi --die-on-term --ini /web_app_feedback/web_app/uwsgi.ini',
              Restart: 'always',
              WorkingDirectory: '/web_app_feedback/web_app/'
            },
            Install: {
              WantedBy: 'multi-user.target',
            } })
    action [:create, :enable, :restart]
    # :restart rather than :start chosen in step above for the case where new server code has been pulled
    # and that new code needs to be loaded into the service
end

file "/web_app_feedback/web_app/post_feedback_to_asana.py" do
    mode 0744
end

cron 'Daily_asana_report_post' do
    hour '8'
    minute '0'
    command '/web_app_feedback/web_app/post_feedback_to_asana.py'
end

package "monit"

file "/etc/monit/conf.d/uwsgi-application" do
    owner 'root'
    group 'root'
    mode 0644
    content ::File.open("/web_app_feedback/monit/uwsgi-application").read
    action :create
end

file "/etc/monit/conf.d/nginx" do
    owner 'root'
    group 'root'
    mode 0644
    content ::File.open("/web_app_feedback/monit/nginx").read
    action :create
end

systemd_unit 'monit.service' do
    action :restart
end
